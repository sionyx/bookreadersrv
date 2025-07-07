import Fluent

struct CreateSection: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Section.schema)
            .id()
            .field("section_id", .uuid, .references(Section.schema, "id"))
            .field("name", .string, .required)
            .field("title", .string, .required)
            .field("cover_url", .string, .required)
            .field("text_link", .string, .required)
            .field("description", .string, .required)
            .field("template", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Section.schema).delete()
    }
}
