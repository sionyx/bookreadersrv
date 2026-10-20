import Fluent
import Vapor

/// Loads the entity through Fluent inside the media transaction.
enum MediaKind: String, Sendable {
    case author, user, section, book, chapterImage, chapterAudio

    var parameter: String {
        switch self {
        case .author: return "authorID"
        case .user: return "userID"
        case .section: return "sectionID"
        case .book: return "bookID"
        case .chapterImage, .chapterAudio: return "chapterID"
        }
    }

    var isAudio: Bool { self == .chapterAudio }

    func load(req: Request, database: any Database) async throws -> MediaTarget {
        let id = try await identifier(req: req, database: database)
        switch self {
        case .author:
            guard let model = try await lockedEntity(Author.self, id: id, on: database) else { throw missing() }
            if req.method != .POST { return .author(model, "") }
            let last = try mediaSlug(model.lastName)
            return .author(model, "authors/\(last)/\(last)_\(try mediaSlug(model.firstName))")
        case .user:
            guard let model = try await lockedEntity(User.self, id: id, on: database) else { throw missing() }
            if req.method != .POST { return .user(model, "") }
            return .user(model, "users/\(try mediaSlug(model.login))")
        case .section:
            guard let model = try await lockedEntity(Section.self, id: id, on: database) else { throw missing() }
            if req.method != .POST { return .section(model, "") }
            let name = try mediaSlug(model.linkName)
            return .section(model, "sections/\(name)/\(name)")
        case .book:
            guard let model = try await lockedEntity(Book.self, id: id, on: database) else { throw missing() }
            if req.method != .POST { return .book(model, "") }
            return .book(model, try await bookPath(model, database: database))
        case .chapterImage, .chapterAudio:
            let book = try await Book.resolve(req.parameters.get("bookID"), on: database)
            guard let chapter = try await lockedEntity(Chapter.self, id: id, on: database),
                  chapter.$book.id == book.id else { throw missing() }
            // Deletion follows persisted URLs, even if names/authors have since changed.
            if req.method != .POST { return .chapter(chapter, "", isAudio) }
            guard let number = try req.query.decode(MediaQuery.self).chapterNumber, number >= 1 else {
                throw Abort(.badRequest, reason: "chapterNumber must be a positive integer")
            }
            let suffix = String(format: "_chapter_%02ld", number)
            let path = try await bookPath(book, database: database) + suffix
            return .chapter(chapter, path, isAudio)
        }
    }

    func identifier(req: Request, database: any Database) async throws -> UUID {
        let value = req.parameters.get(parameter)
        switch self {
        case .author: return try await Author.resolve(value, on: database).requireID()
        case .section: return try await Section.resolve(value, on: database).requireID()
        case .book: return try await Book.resolve(value, on: database).requireID()
        case .user, .chapterImage, .chapterAudio:
            guard let value, let id = UUID(uuidString: value) else {
                throw Abort(.badRequest, reason: "Invalid \(parameter)")
            }
            return id
        }
    }

    /// A no-op ID update takes the database write lock until this transaction ends.
    /// This keeps concurrent media requests serialized using only Fluent's query API.
    private func lockedEntity<M: Model>(_ type: M.Type, id: UUID, on database: any Database) async throws -> M?
        where M.IDValue == UUID
    {
        try await M.query(on: database)
            .filter(.id, .equal, id)
            .set([.id: .bind(id)])
            .update()
        return try await M.find(id, on: database)
    }

    private func missing() -> Abort { Abort(.notFound, reason: "Media entity not found") }

    private func bookPath(_ book: Book, database: any Database) async throws -> String {
        let role = try await Role.query(on: database)
            .filter(\.$book.$id == book.requireID()).filter(\.$type == .author)
            .sort(\.$createDate).sort(\.$id).first()
        let authorID = role?.$author.id ?? book.$author.id
        guard let author = try await Author.find(authorID, on: database) else {
            throw Abort(.unprocessableEntity, reason: "Book has no author for media naming")
        }
        let name = try mediaSlug("\(author.firstName) \(author.lastName)")
        let title = try mediaSlug(book.title)
        return "audiobooks/\(name)/\(title)/\(name)_\(title)"
    }
}

struct MediaQuery: Content { var chapterNumber: Int? }

func mediaSlug(_ value: String) throws -> String {
    let latin = value.applyingTransform(.toLatin, reverse: false)?
        .applyingTransform(.stripDiacritics, reverse: false) ?? value
    let slug = latin.lowercased().replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression)
        .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    guard !slug.isEmpty, slug.utf8.count <= 200 else {
        throw Abort(.unprocessableEntity, reason: "Entity name must produce a Latin filename of 1–200 bytes")
    }
    return slug
}

enum MediaTarget: Sendable {
    case author(Author, String)
    case user(User, String)
    case section(Section, String)
    case book(Book, String)
    case chapter(Chapter, String, Bool)

    var path: String {
        switch self {
        case .author(_, let path), .user(_, let path), .section(_, let path), .book(_, let path), .chapter(_, let path, _): return path
        }
    }

    var urls: [String] {
        switch self {
        case .author(let m, _): return [m.photoUrl, m.previewUrl ?? "", m.mediumUrl ?? ""].filter { !$0.isEmpty }
        case .user(let m, _): return [m.photoUrl, m.previewUrl ?? "", m.mediumUrl ?? ""].filter { !$0.isEmpty }
        case .section(let m, _): return [m.coverUrl, m.previewUrl ?? "", m.mediumUrl ?? ""].filter { !$0.isEmpty }
        case .book(let m, _): return [m.coverUrl, m.previewUrl ?? "", m.mediumUrl ?? ""].filter { !$0.isEmpty }
        case .chapter(let m, _, true): return [m.mediaUrl].filter { !$0.isEmpty }
        case .chapter(let m, _, false): return [m.coverUrl ?? "", m.previewUrl ?? "", m.mediumUrl ?? ""].filter { !$0.isEmpty }
        }
    }

    func save(primary: String?, preview: String?, medium: String? = nil, on database: any Database) async throws {
        switch self {
        case .author(let m, _):
            m.photoUrl = primary ?? ""; m.previewUrl = preview; m.mediumUrl = medium; try await m.save(on: database)
        case .user(let m, _):
            m.photoUrl = primary ?? ""; m.previewUrl = preview; m.mediumUrl = medium; try await m.save(on: database)
        case .section(let m, _):
            m.coverUrl = primary ?? ""; m.previewUrl = preview; m.mediumUrl = medium; try await m.save(on: database)
        case .book(let m, _):
            m.coverUrl = primary ?? ""; m.previewUrl = preview; m.mediumUrl = medium; try await m.save(on: database)
        case .chapter(let m, _, true):
            m.mediaUrl = primary ?? ""; try await m.save(on: database)
        case .chapter(let m, _, false):
            m.coverUrl = primary; m.previewUrl = preview; m.mediumUrl = medium; try await m.save(on: database)
        }
    }
}
