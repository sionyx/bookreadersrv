import Fluent
// The legacy NIO handle is confined to receive(); writes are awaited before close.
@preconcurrency import NIOCore
import NIOPosix
import Vapor

struct MediaController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        register(routes.grouped("authors", ":authorID", "image"), kind: .author)
        register(routes.grouped("users", ":userID", "image"), kind: .user)
        register(routes.grouped("sections", ":sectionID", "image"), kind: .section)
        register(routes.grouped("books", ":bookID", "image"), kind: .book)
        register(routes.grouped("books", ":bookID", "chapters", ":chapterID", "image"), kind: .chapterImage)
        register(routes.grouped("books", ":bookID", "chapters", ":chapterID", "audio"), kind: .chapterAudio)
    }

    private func register(_ routes: any RoutesBuilder, kind: MediaKind) {
        routes.on(.POST, body: .stream) { req async throws -> MediaResponse in
            try await self.upload(req: req, kind: kind)
        }
        routes.delete { req async throws -> MediaResponse in
            try await self.delete(req: req, kind: kind)
        }
    }

    private func upload(req: Request, kind: MediaKind) async throws -> MediaResponse {
        let storage = req.application.mediaStorage
        try storage.validateConfiguration()
        guard req.parameters.get(kind.parameter).flatMap(UUID.init(uuidString:)) != nil else {
            throw Abort(.badRequest, reason: "Invalid \(kind.parameter)")
        }
        if kind == .chapterAudio || kind == .chapterImage {
            guard req.parameters.get("bookID").flatMap(UUID.init(uuidString:)) != nil,
                  let number = try req.query.decode(MediaQuery.self).chapterNumber, number > 0 else {
                throw Abort(.badRequest, reason: "Valid bookID and positive chapterNumber are required")
            }
        }
        let type = req.headers.first(name: .contentType)?.split(separator: ";").first?
            .trimmingCharacters(in: .whitespaces).lowercased() ?? ""
        let audioExtension: String?
        if kind.isAudio {
            switch type {
            case "audio/mpeg": audioExtension = "mp3"
            case "audio/mp4", "audio/m4a", "audio/x-m4a": audioExtension = "m4a"
            default: throw Abort(.unsupportedMediaType, reason: "Expected an MP3 or M4A file in the request body")
            }
        } else {
            guard ["image/jpeg", "image/png", "image/webp"].contains(type) else {
                throw Abort(.unsupportedMediaType, reason: "Expected a JPEG, PNG or WebP file in the request body")
            }
            audioExtension = nil
        }
        let directory = try await temporaryDirectory(req: req)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("upload")
        try await receive(req: req, to: source, limit: kind.isAudio ? 1_073_741_824 : 20_971_520)
        let files: [(URL, String, String)]
        if let ext = audioExtension {
            try await req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
                try self.validateAudio(source, extension: ext)
            }.get()
            files = [(source, ".\(ext)", ext == "mp3" ? "audio/mpeg" : "audio/mp4")]
        } else {
            let images = try await req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
                _ = try ImageProcessor.imageFormat(source)
                return try ImageProcessor.process(source: source, directory: directory)
            }.get()
            files = [(images.0, ".png", "image/png"), (images.1, "_mini.jpg", "image/jpeg")]
        }
        let mutation = MediaMutation(storage: storage, directory: directory)
        do {
            return try await req.db.transaction { database in
                let target = try await kind.load(req: req, database: database)
                let keys = files.map { target.path + $0.1 }
                // Read previous names from the locked row, not from today's entity names.
                let oldKeys = Set(target.urls.compactMap { try? storage.key(from: $0) })
                let affected = oldKeys.union(keys)
                try await mutation.snapshot(keys: affected)
                do {
                    for (index, file) in files.enumerated() {
                        try await mutation.put(file: file.0, key: keys[index], type: file.2)
                    }
                    let primary = storage.url(for: keys[0])
                    let preview = keys.count == 2 ? storage.url(for: keys[1]) : nil
                    try await target.save(primary: primary, preview: preview, on: database)
                    for key in oldKeys.subtracting(keys) { try await mutation.remove(key: key) }
                    return MediaResponse(success: true, url: primary, previewUrl: preview)
                } catch {
                    try await mutation.restore(orThrow: error)
                    throw error
                }
            }
        } catch {
            // Also compensate if the database transaction fails to commit.
            try await mutation.restore(orThrow: error)
            throw described(error, operation: "Media upload")
        }
    }

    private func delete(req: Request, kind: MediaKind) async throws -> MediaResponse {
        let storage = req.application.mediaStorage
        try storage.validateConfiguration()
        let input = try req.content.decode(MediaDeleteRequest.self)
        let requestedKey = try storage.key(from: input.url)
        let directory = try await temporaryDirectory(req: req)
        defer { try? FileManager.default.removeItem(at: directory) }
        let mutation = MediaMutation(storage: storage, directory: directory)
        do {
            return try await req.db.transaction { database in
                let target = try await kind.load(req: req, database: database)
                let keys = Set(try target.urls.map { try storage.key(from: $0) })
                guard keys.contains(requestedKey) else {
                    throw Abort(.badRequest, reason: "URL is not attached to this entity")
                }
                try await mutation.snapshot(keys: keys)
                do {
                    // Either image URL deletes the complete pair. Audio deletes one object.
                    for key in keys { try await mutation.remove(key: key) }
                    try await target.save(primary: nil, preview: nil, on: database)
                    return MediaResponse(success: true, url: nil, previewUrl: nil)
                } catch {
                    try await mutation.restore(orThrow: error)
                    throw error
                }
            }
        } catch {
            try await mutation.restore(orThrow: error)
            throw described(error, operation: "Media deletion")
        }
    }

    private func temporaryDirectory(req: Request) async throws -> URL {
        try await req.application.threadPool.runIfActive(eventLoop: req.eventLoop) {
            let configured = Environment.get("MEDIA_TEMP_DIRECTORY") ?? ".media-tmp"
            let root = URL(fileURLWithPath: configured, relativeTo: URL(fileURLWithPath: req.application.directory.workingDirectory))
            let directory = root.appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                    attributes: [.posixPermissions: 0o700])
            return directory
        }.get()
    }

    private func receive(req: Request, to destination: URL, limit: Int) async throws {
        if let raw = req.headers.first(name: .contentLength) {
            guard let length = Int(raw), length >= 0 else {
                throw Abort(.badRequest, reason: "Invalid Content-Length")
            }
            guard length <= limit else { throw Abort(.payloadTooLarge, reason: "File exceeds \(limit) bytes") }
        }
        let io = req.application.fileio
        let handle = try await io.openFile(path: destination.path, mode: .write,
                                          flags: .allowFileCreation(posixMode: 0o600), eventLoop: req.eventLoop).get()
        defer { try? handle.close() }
        var received = 0
        for try await chunk in req.body {
            guard chunk.readableBytes <= limit - received else {
                throw Abort(.payloadTooLarge, reason: "File exceeds \(limit) bytes")
            }
            received += chunk.readableBytes
            try await io.write(fileHandle: handle, buffer: chunk, eventLoop: req.eventLoop).get()
        }
        guard received > 0 else { throw Abort(.badRequest, reason: "File is empty") }
    }

    private func validateAudio(_ source: URL, extension ext: String) throws {
        let handle = try FileHandle(forReadingFrom: source)
        defer { try? handle.close() }
        let bytes = [UInt8](try handle.read(upToCount: 16) ?? Data())
        let valid: Bool
        if ext == "mp3" {
            valid = bytes.starts(with: Array("ID3".utf8)) ||
                (bytes.count >= 4 && bytes[0] == 0xff && bytes[1] & 0xe0 == 0xe0 &&
                 bytes[1] & 0x06 != 0 && bytes[1] & 0x18 != 0x08)
        } else {
            valid = bytes.count >= 12 && String(bytes: bytes[4..<8], encoding: .ascii) == "ftyp"
        }
        guard valid else { throw Abort(.unprocessableEntity, reason: "File does not have a valid \(ext.uppercased()) header") }
    }

    private func described(_ error: Error, operation: String) -> Abort {
        if let abort = error as? any AbortError { return Abort(abort.status, reason: abort.reason) }
        return Abort(.internalServerError, reason: "\(operation) failed while saving database or temporary files")
    }
}

struct MediaDeleteRequest: Content { let url: String }
struct MediaResponse: Content {
    let success: Bool
    let url: String?
    let previewUrl: String?
}

/// One sequential mutation, never shared between requests. Backups allow compensating
/// failed uploads/deletions and database writes; they are removed with the request directory.
private final class MediaMutation: @unchecked Sendable {
    enum Snapshot { case missing, file(URL) }
    let storage: MediaStorage
    let directory: URL
    private var snapshots: [String: Snapshot] = [:]
    private var changed: [String] = []

    init(storage: MediaStorage, directory: URL) {
        self.storage = storage
        self.directory = directory
    }

    func snapshot(keys: Set<String>) async throws {
        for key in keys.sorted() {
            if let file = try await storage.backup(key: key, directory: directory) {
                snapshots[key] = .file(file)
            } else { snapshots[key] = .missing }
        }
    }

    func put(file: URL, key: String, type: String) async throws {
        changed.append(key) // Include uncertain network outcomes in compensation.
        try await storage.put(file: file, key: key, contentType: type)
    }

    func remove(key: String) async throws {
        changed.append(key)
        try await storage.remove(key: key)
    }

    func restore(orThrow original: Error) async throws {
        var failed = false
        for key in changed.reversed() {
            do {
                switch snapshots[key] {
                case .file(let file):
                    let type: String
                    switch URL(fileURLWithPath: key).pathExtension.lowercased() {
                    case "png": type = "image/png"
                    case "jpg", "jpeg": type = "image/jpeg"
                    case "webp": type = "image/webp"
                    case "mp3": type = "audio/mpeg"
                    case "m4a": type = "audio/mp4"
                    default: type = "application/octet-stream"
                    }
                    try await storage.put(file: file, key: key, contentType: type)
                case .missing: try await storage.remove(key: key)
                case nil: break
                }
            } catch { failed = true }
        }
        changed.removeAll()
        if failed {
            let reason = (original as? any AbortError)?.reason ?? "Database or file operation failed"
            throw Abort(.badGateway, reason: "\(reason). S3 rollback was incomplete; check media objects before retrying")
        }
    }
}
