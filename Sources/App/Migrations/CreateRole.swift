//
//  CreateRole.swift
//  bookreadersrv
//
//  Created by sionyx on 02.01.2026.
//



import Fluent

struct CreateRole: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Role.schema)
            .id()
            .field("create_date", .datetime, .required)
            .field("update_date", .datetime, .required)
            .field("delete_date", .datetime)
            .field("book_id", .uuid, .required, .references(Book.schema, "id"))
            .field("author_id", .uuid, .required, .references(Author.schema, "id"))
            .field("type", .string, .required)
            .unique(on: "book_id", "author_id")
            .create()
        
        let books = try await Book.query(on: database).all()
        for book in books {
            let role = try Role(bookID: book.requireID(), authorID: book.$author.id, type: .author)
            try await role.save(on: database)
        }
    }

    func revert(on database: Database) async throws {
        try await database.schema(Role.schema).delete()
    }
}
