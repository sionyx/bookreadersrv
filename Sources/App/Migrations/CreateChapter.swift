//
//  CreateChapter.swift
//  bookreadersrv
//
//  Created by sionyx on 12.01.2026.
//

import Fluent

struct CreateChapter: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Chapter.schema)
            .id()
            .field("create_date", .datetime, .required)
            .field("update_date", .datetime, .required)
            .field("delete_date", .datetime)
            .field("book_id", .uuid, .required, .references(Book.schema, "id"))
            .field("title", .string, .required)
            .field("cover_url", .string)
            .field("preview_url", .string)
            .field("media_url", .string, .required)
            .field("publish_date", .datetime)
            .field("link", .string)
            .field("description", .string)
            .create()
        
        let books = try await Book.query(on: database).all()
        for book in books {
            let chapter = try Chapter(bookID: book.requireID(), title: book.title, mediaUrl: book.mediaUrl, publishDate: book.publishDate)
            try await chapter.save(on: database)
        }
    }

    func revert(on database: Database) async throws {
        try await database.schema(Chapter.schema).delete()
    }
}
