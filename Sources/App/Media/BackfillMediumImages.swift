import Fluent
import Vapor

/// Separate from the schema migration: network failures must not prevent API startup.
struct BackfillMediumImages: AsyncCommand {
    struct Signature: CommandSignature {
        @Flag(name: "dry-run", help: "Count missing medium images without writing to S3 or the database.")
        var dryRun: Bool
    }
    var help: String { "Generate missing 512px WebP images from stored originals (safe to resume)." }

    func run(using context: CommandContext, signature: Signature) async throws {
        let app = context.application
        try app.mediaStorage.validateConfiguration()
        var failures = 0
        failures += try await backfill(Author.self, app: app, dryRun: signature.dryRun)
        failures += try await backfill(User.self, app: app, dryRun: signature.dryRun)
        failures += try await backfill(Section.self, app: app, dryRun: signature.dryRun)
        failures += try await backfill(Book.self, app: app, dryRun: signature.dryRun)
        failures += try await backfill(Chapter.self, app: app, dryRun: signature.dryRun)
        guard failures == 0 else {
            throw Abort(.internalServerError, reason: "Medium backfill failed for \(failures) entities; inspect logged IDs and retry")
        }
    }

    private func backfill<M: MediumImageModel>(_ type: M.Type, app: Application, dryRun: Bool) async throws -> Int {
        var offset = 0
        var failures = 0
        var count = 0
        while true {
            // Include soft-deleted content, with bounded memory and stable ordering.
            let batch = try await M.query(on: app.db).withDeleted().sort(\._$id)
                .range(offset..<(offset + 100)).all()
            if batch.isEmpty { break }
            offset += batch.count
            for item in batch {
                let id = try item.requireID()
                do {
                    if try await generate(type, id: id, app: app, dryRun: dryRun) { count += 1 }
                } catch {
                    failures += 1
                    // Never log signed URLs or raw network errors containing credentials.
                    let reason = (error as? any AbortError)?.reason ?? "Database or file operation failed"
                    app.logger.error("Medium backfill failed: \(M.schema)/\(id): \(reason)")
                }
            }
        }
        app.logger.notice("Medium backfill \(M.schema): \(count) \(dryRun ? "pending" : "generated"), \(failures) failed")
        return failures
    }

    private func generate<M: MediumImageModel>(_ type: M.Type, id: UUID, app: Application, dryRun: Bool) async throws -> Bool {
        let root = Environment.get("MEDIA_TEMP_DIRECTORY") ?? app.directory.workingDirectory + ".media-tmp"
        let directory = URL(fileURLWithPath: root).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        defer { try? FileManager.default.removeItem(at: directory) }
        let storage = app.mediaStorage
        let mutation = MediaMutation(storage: storage, directory: directory)
        do {
            return try await app.db.transaction { db in
                // Match the write lock used by media uploads before reading the source URL.
                if !dryRun {
                    try await M.query(on: db).withDeleted().filter(\._$id == id).set(\._$id, to: id).update()
                }
                guard let model = try await M.query(on: db).withDeleted().filter(\._$id == id).first(),
                      model.mediumUrl?.isEmpty != false,
                      let original = model.originalImageURL, !original.isEmpty else { return false }
                let sourceKey = try storage.key(from: original)
                if dryRun { return true }
                guard let source = try await storage.backup(key: sourceKey, directory: directory) else {
                    throw Abort(.notFound, reason: "Original S3 image is missing")
                }
                let medium = try await app.threadPool.runIfActive(eventLoop: db.eventLoop) {
                    try ImageProcessor.processMedium(source: source, directory: directory)
                }.get()
                // Per-entity names avoid collisions when multiple entities share an original.
                let key = "medium/\(M.schema)/\(id.uuidString.lowercased()).webp"
                try await mutation.snapshot(keys: [key])
                try await mutation.put(file: medium, key: key, type: "image/webp")
                try await M.query(on: db).withDeleted().filter(\._$id == id)
                    .set(["medium_url": .bind(storage.url(for: key))]).update()
                return true
            }
        } catch {
            try await mutation.restore(orThrow: error)
            throw error
        }
    }
}

private protocol MediumImageModel: Model where IDValue == UUID {
    var mediumUrl: String? { get set }
    var originalImageURL: String? { get }
}
extension Author: MediumImageModel { var originalImageURL: String? { photoUrl } }
extension User: MediumImageModel { var originalImageURL: String? { photoUrl } }
extension Section: MediumImageModel { var originalImageURL: String? { coverUrl } }
extension Book: MediumImageModel { var originalImageURL: String? { coverUrl } }
extension Chapter: MediumImageModel { var originalImageURL: String? { coverUrl } }
