import Fluent
import Vapor

/// Copy section names without raw SQL; minimal migration models can read nullable new columns.
struct AddLinkNames: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.transaction { try await prepareSchema(on: $0) }
    }

    private func prepareSchema(on database: any Database) async throws {
        for schema in [Section.schema, Book.schema, Author.schema] {
            try await database.schema(schema).field("link_name", .string).update()
        }
        var sectionNames = Set<String>()
        for section in try await LegacySectionLink.query(on: database).sort(\.$id).all() {
            guard let name = section.name else { throw Abort(.badRequest, reason: "Section has no name") }
            try validateLinkName(name)
            guard sectionNames.insert(name).inserted else {
                throw Abort(.conflict, reason: "Existing section names must be unique before migrating link_name")
            }
            section.linkName = name
            try await section.save(on: database)
        }
        var authorNames = Set<String>()
        for author in try await LegacyAuthorLink.query(on: database).sort(\.$id).all() {
            author.linkName = unique(generatedLinkName("\(author.firstName) \(author.lastName)", fallback: "author"), used: &authorNames)
            try await author.save(on: database)
        }
        var bookNames = Set<String>()
        // This model has no soft-delete filter: deleted books also reserve their addresses.
        for book in try await LegacyBookLink.query(on: database).sort(\.$id).all() {
            book.linkName = unique(generatedLinkName(book.title, fallback: "book"), used: &bookNames)
            try await book.save(on: database)
        }
        for schema in [Section.schema, Book.schema, Author.schema] {
            try await database.schema(schema).unique(on: "link_name").update()
        }
        try await database.schema(Section.schema).deleteField("name").update()
    }

    func revert(on database: any Database) async throws {
        try await database.transaction { try await revertSchema(on: $0) }
    }

    private func revertSchema(on database: any Database) async throws {
        try await database.schema(Section.schema).field("name", .string).update()
        for section in try await LegacySectionLink.query(on: database).all() {
            section.name = section.linkName ?? ""
            try await section.save(on: database)
        }
        for schema in [Section.schema, Book.schema, Author.schema] {
            try await database.schema(schema).deleteUnique(on: "link_name").update()
            try await database.schema(schema).deleteField("link_name").update()
        }
    }

    private func unique(_ base: String, used: inout Set<String>) -> String {
        var name = base
        var suffix = 2
        while !used.insert(name).inserted { name = "\(base)-\(suffix)"; suffix += 1 }
        return name
    }
}

private final class LegacySectionLink: Model, @unchecked Sendable {
    static let schema = Section.schema
    @ID(key: .id) var id: UUID?
    @OptionalField(key: "name") var name: String?
    @OptionalField(key: "link_name") var linkName: String?
    init() {}
}
private final class LegacyAuthorLink: Model, @unchecked Sendable {
    static let schema = Author.schema
    @ID(key: .id) var id: UUID?
    @Field(key: "first_name") var firstName: String
    @Field(key: "last_name") var lastName: String
    @OptionalField(key: "link_name") var linkName: String?
    init() {}
}
private final class LegacyBookLink: Model, @unchecked Sendable {
    static let schema = Book.schema
    @ID(key: .id) var id: UUID?
    @Field(key: "title") var title: String
    @OptionalField(key: "link_name") var linkName: String?
    init() {}
}
