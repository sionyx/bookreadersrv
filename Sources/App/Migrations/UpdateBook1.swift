import Fluent

struct UpdateBook1: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Book.schema)
            .field("create_date", .datetime)
            .field("update_date", .datetime)
            .field("delete_date", .datetime)
            .field("preview_url", .string)
            .field("publish_date", .datetime)
            .field("template", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Book.schema)
            .deleteField("create_date")
            .deleteField("update_date")
            .deleteField("delete_date")
            .deleteField("preview_url")
            .deleteField("publish_date")
            .deleteField("template")
            .update()
    }
}
