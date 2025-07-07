import Fluent

struct UpdateSection1: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Section.schema)
            .field("book_template", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Section.schema)
            .deleteField("book_template")
            .update()
    }
}
