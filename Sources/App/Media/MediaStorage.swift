import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import SotoS3
import Vapor

/// S3 signing is delegated to Soto. URLSession uploads/downloads files from disk.
final class MediaStorage: @unchecked Sendable {
    let bucket: String
    let endpoint: URL
    let publicBase: URL
    private let accessKey: String
    private let secretKey: String
    private let client: AWSClient
    private let s3: S3
    private let session: URLSession

    init() throws {
        bucket = try Self.requiredSetting("S3_BUCKET")
        let region = try Self.requiredSetting("S3_REGION")
        let endpointSetting = try Self.requiredSetting("S3_ENDPOINT")
        let publicBaseSetting = try Self.requiredSetting("S3_PUBLIC_BASE_URL")
        guard let endpointURL = URL(string: endpointSetting),
              let publicURL = URL(string: publicBaseSetting),
              [endpointURL, publicURL].allSatisfy({ url in
                  guard let c = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
                  return c.scheme == "https" && c.host != nil && c.user == nil && c.password == nil && c.query == nil && c.fragment == nil
              }), !bucket.isEmpty, bucket.range(of: "^[a-z0-9][a-z0-9.-]*$", options: .regularExpression) != nil else {
            throw Abort(.internalServerError, reason: "Invalid S3_ENDPOINT, S3_PUBLIC_BASE_URL or S3_BUCKET configuration")
        }
        endpoint = endpointURL
        publicBase = publicURL
        accessKey = Environment.get("S3_ACCESS_KEY_ID") ?? ""
        secretKey = Environment.get("S3_SECRET_ACCESS_KEY") ?? ""
        client = AWSClient(credentialProvider: .static(accessKeyId: accessKey, secretAccessKey: secretKey))
        s3 = S3(client: client, region: .init(rawValue: region), endpoint: endpoint.absoluteString)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 3600
        session = URLSession(configuration: configuration)
    }

    private static func requiredSetting(_ name: String) throws -> String {
        guard let value = Environment.get(name)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            throw Abort(.internalServerError, reason: "\(name) must be configured in the environment")
        }
        return value
    }

    func shutdown() async throws {
        session.invalidateAndCancel()
        try await client.shutdown()
    }

    func validateConfiguration() throws {
        guard !accessKey.isEmpty, !secretKey.isEmpty else {
            throw Abort(.serviceUnavailable, reason: "S3_ACCESS_KEY_ID and S3_SECRET_ACCESS_KEY are not configured")
        }
    }

    func url(for key: String) -> String {
        publicBase.appendingPathComponent(key).absoluteString
    }

    /// Parse only URLs inside this bucket. No HTTP requests to client-supplied hosts.
    func key(from value: String) throws -> String {
        guard let supplied = URLComponents(string: value), supplied.user == nil, supplied.password == nil,
              supplied.query == nil, supplied.fragment == nil else {
            throw Abort(.badRequest, reason: "Expected a direct URL without credentials, query or fragment")
        }
        var bases = [publicBase, endpoint.appendingPathComponent(bucket)]
        if var virtual = URLComponents(url: endpoint, resolvingAgainstBaseURL: false), let host = virtual.host {
            virtual.host = "\(bucket).\(host)"
            if let url = virtual.url { bases.append(url) }
        }
        for base in bases {
            guard let components = URLComponents(url: base, resolvingAgainstBaseURL: false),
                  supplied.scheme == components.scheme, supplied.host == components.host,
                  supplied.port == components.port else { continue }
            let prefix = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let root = prefix.isEmpty ? "/" : "/\(prefix)/"
            guard supplied.path.hasPrefix(root) else { continue }
            let key = String(supplied.path.dropFirst(root.count))
            guard !key.isEmpty, !key.contains("\\"), !key.contains("//"),
                  !key.split(separator: "/").contains(where: { $0 == "." || $0 == ".." }),
                  key.range(of: "^[A-Za-z0-9_./-]+$", options: .regularExpression) != nil else {
                throw Abort(.badRequest, reason: "Invalid S3 object path")
            }
            return key
        }
        throw Abort(.badRequest, reason: "URL does not belong to the configured S3 bucket")
    }

    private func signedURL(key: String, method: HTTPMethod) async throws -> URL {
        try validateConfiguration()
        return try await s3.signURL(url: endpoint.appendingPathComponent(bucket).appendingPathComponent(key),
                                    httpMethod: method, expires: .hours(1))
    }

    func put(file: URL, key: String, contentType: String) async throws {
        var request = URLRequest(url: try await signedURL(key: key, method: .PUT))
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        // Revalidation avoids stale content after a replacement at the same URL.
        request.setValue("public, max-age=0, must-revalidate", forHTTPHeaderField: "Cache-Control")
        do {
            let (_, response) = try await session.upload(for: request, fromFile: file)
            try check(response, operation: "upload")
        } catch let error as Abort { throw error }
        catch { throw Abort(.badGateway, reason: "S3 upload failed: \(networkReason(error))") }
    }

    func remove(key: String) async throws {
        var request = URLRequest(url: try await signedURL(key: key, method: .DELETE))
        request.httpMethod = "DELETE"
        do {
            let (_, response) = try await session.data(for: request)
            try check(response, operation: "delete", allowMissing: true)
        } catch let error as Abort { throw error }
        catch { throw Abort(.badGateway, reason: "S3 deletion failed: \(networkReason(error))") }
    }

    /// Save a rollback copy on disk, including existing objects at the destination name.
    func backup(key: String, directory: URL) async throws -> URL? {
        do {
            let (download, response) = try await session.download(from: try await signedURL(key: key, method: .GET))
            defer { try? FileManager.default.removeItem(at: download) }
            if (response as? HTTPURLResponse)?.statusCode == 404 { return nil }
            try check(response, operation: "backup")
            let destination = directory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.moveItem(at: download, to: destination)
            return destination
        } catch let error as Abort { throw error }
        catch { throw Abort(.badGateway, reason: "S3 backup failed: \(networkReason(error))") }
    }

    private func check(_ response: URLResponse, operation: String, allowMissing: Bool = false) throws {
        guard let response = response as? HTTPURLResponse else {
            throw Abort(.badGateway, reason: "Invalid S3 response during \(operation)")
        }
        guard (200..<300).contains(response.statusCode) || (allowMissing && response.statusCode == 404) else {
            throw Abort(.badGateway, reason: "S3 \(operation) returned HTTP \(response.statusCode)")
        }
    }

    private func networkReason(_ error: Error) -> String {
        // Do not include signed URLs / credential details in API errors or logs.
        if let error = error as? URLError { return "network error \(error.code.rawValue)" }
        return "transport error"
    }
}

struct MediaStorageLifecycle: LifecycleHandler {
    func shutdownAsync(_ application: Application) async {
        do { try await application.mediaStorage.shutdown() }
        catch { application.logger.error("Could not shut down S3 client") }
    }
}

extension Application {
    private struct MediaStorageKey: StorageKey { typealias Value = MediaStorage }
    var mediaStorage: MediaStorage {
        get { storage[MediaStorageKey.self]! }
        set { storage[MediaStorageKey.self] = newValue }
    }
}
