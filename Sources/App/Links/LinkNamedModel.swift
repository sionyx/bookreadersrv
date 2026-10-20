import Fluent
import Vapor

protocol LinkNamedModel: Model where IDValue == UUID {
    var linkName: String { get set }
}

extension LinkNamedModel {
    static func matching(_ value: String?, on database: any Database) throws -> QueryBuilder<Self> {
        guard let value, !value.isEmpty else { throw Abort(.badRequest, reason: "Missing entity identifier") }
        let query = Self.query(on: database)
        if let id = UUID(uuidString: value) { return query.filter(.id, .equal, id) }
        return query.filter("link_name", .equal, value)
    }

    static func resolve(_ value: String?, on database: any Database) async throws -> Self {
        guard let model = try await matching(value, on: database).first() else { throw Abort(.notFound) }
        return model
    }

    /// Explicit addresses conflict rather than silently changing; generated addresses get a suffix.
    func assignLinkName(_ supplied: String?, source: String, on database: any Database) async throws {
        if let supplied {
            try validateLinkName(supplied)
            linkName = supplied
        } else if linkName.isEmpty {
            let base = generatedLinkName(source, fallback: Self.schema)
            var candidate = base
            var suffix = 2
            while try await Self.query(on: database).withDeleted().filter("link_name", .equal, candidate).first() != nil {
                candidate = "\(base)-\(suffix)"
                suffix += 1
            }
            linkName = candidate
        }
        let existing = try await Self.query(on: database).withDeleted().filter("link_name", .equal, linkName).first()
        if let existing, existing.id != id {
            throw Abort(.conflict, reason: "link_name is already in use")
        }
    }

    func saveWithLinkName(on database: any Database) async throws {
        do { try await save(on: database) }
        catch let error as any DatabaseError where error.isConstraintFailure {
            throw Abort(.conflict, reason: "Entity conflicts with existing data (including link_name)")
        }
    }
}

func validateLinkName(_ value: String) throws {
    guard value.utf8.count <= 160,
          value.range(of: "^[a-z0-9]+([-_][a-z0-9]+)*$", options: .regularExpression) != nil,
          UUID(uuidString: value) == nil,
          !["search", "path"].contains(value) else {
        throw Abort(.badRequest, reason: "link_name must be 1–160 lowercase Latin letters, digits, hyphens or underscores; UUIDs and reserved routes are not allowed")
    }
}

func generatedLinkName(_ value: String, fallback: String) -> String {
    let latin = value.applyingTransform(.toLatin, reverse: false)?
        .applyingTransform(.stripDiacritics, reverse: false) ?? value
    let result = latin.lowercased().replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
        .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    let base = String(result.prefix(140)).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    let candidate = base.isEmpty ? fallback : base
    return (try? validateLinkName(candidate)) != nil ? candidate : "\(fallback)-\(candidate)"
}

/// Include both legacy primary authors and every author attached through a role, without duplicates.
func booksByAuthor(_ author: Author, on database: any Database) async throws -> [Book] {
    let id = try author.requireID()
    let roles = try await Role.query(on: database).filter(\.$author.$id == id).all()
    let ids = Array(Set(roles.map { $0.$book.id }))
    return try await Book.query(on: database)
        .group(.or) { query in
            query.filter(\.$author.$id == id)
            if !ids.isEmpty { query.filter(\.$id ~~ ids) }
        }
        .sort(\.$publishDate)
        .sort(\.$id)
        .with(\.$user)
        .with(\.$section)
        .all()
}
