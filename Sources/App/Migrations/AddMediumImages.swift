import Fluent

struct AddMediumImages: AsyncMigration {
    func prepare(on database: Database) async throws {
        for schema in [Author.schema, User.schema, Section.schema, Book.schema, Chapter.schema] {
            try await database.schema(schema).field("medium_url", .string).update()
        }
    }

    func revert(on database: Database) async throws {
        for schema in [Author.schema, User.schema, Section.schema, Book.schema, Chapter.schema] {
            try await database.schema(schema).deleteField("medium_url").update()
        }
    }
}
