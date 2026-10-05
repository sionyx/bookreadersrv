import Fluent

struct AddMediaPreviews: AsyncMigration {
    func prepare(on database: Database) async throws {
        for schema in [Author.schema, User.schema, Section.schema] {
            try await database.schema(schema).field("preview_url", .string).update()
        }
    }

    func revert(on database: Database) async throws {
        for schema in [Author.schema, User.schema, Section.schema] {
            try await database.schema(schema).deleteField("preview_url").update()
        }
    }
}
