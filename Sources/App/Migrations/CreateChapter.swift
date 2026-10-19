//
//  CreateChapter.swift
//  bookreadersrv
//
//  Created by sionyx on 12.01.2026.
//

import Fluent
import Foundation

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
            // Use the original columns: later migrations have not added duration yet.
            let now = Date()
            try await Chapter.query(on: database)
                .set([
                    .id: .bind(UUID()),
                    "create_date": .bind(now),
                    "update_date": .bind(now),
                    "book_id": .bind(try book.requireID()),
                    "title": .bind(book.title),
                    "cover_url": .bind(""),
                    "preview_url": .bind(""),
                    "media_url": .bind(book.mediaUrl),
                    "publish_date": book.publishDate.map { .bind($0) } ?? .null,
                    "link": .bind(""),
                    "description": .bind("")
                ])
                .create()
        }
    }

    func revert(on database: Database) async throws {
        try await database.schema(Chapter.schema).delete()
    }
}
