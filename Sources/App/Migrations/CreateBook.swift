import Fluent

struct CreateBook: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Book.schema)
            .id()
            .field("section_id", .uuid, .references(Section.schema, "id"))
            .field("author_id", .uuid, .required, .references(Author.schema, "id"))
            .field("title", .string, .required)
            .field("duration", .int32, .required)
            .field("media_url", .string, .required)
            .field("cover_url", .string, .required)
            .field("text_link", .string, .required)
            .field("description", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Book.schema).delete()
    }
}
