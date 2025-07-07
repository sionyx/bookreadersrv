import Fluent

struct CreateAuthor: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Author.schema)
            .id()
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .field("photo_url", .string, .required)
            .field("link", .string, .required)
            .field("description", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Author.schema).delete()
    }
}
