import Fluent

struct AddChapterDuration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Chapter.schema)
            .field("duration", .int32)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Chapter.schema)
            .deleteField("duration")
            .update()
    }
}
