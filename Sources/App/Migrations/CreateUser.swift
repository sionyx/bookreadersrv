//
//  CreateUser.swift
//  bookreadersrv
//
//  Created by sionyx on 02.01.2026.
//

import Fluent
import struct Foundation.UUID

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(User.schema)
            .id()
            .field("create_date", .datetime, .required)
            .field("update_date", .datetime, .required)
            .field("delete_date", .datetime)
            .field("login", .string, .required)
            .field("pass", .string, .required)
            .field("photo_url", .string)
            .field("link", .string)
            .field("description", .string)
            .unique(on: "login")
            .create()
        
        // Insert only the fields available at this migration stage. Later migrations
        // add fields to User, so saving the current model here would include them.
        try await User.query(on: database)
            .set(\.$id, to: UUID.empty)
            .set(\.$login, to: "unknown")
            .set(\.$pass, to: "")
            .set(\.$photoUrl, to: "")
            .set(\.$link, to: "")
            .set(\.$description, to: "")
            .create()

        try await database.schema(Book.schema)
            .field("user_id", .uuid, .required, .sql(.default(UUID.empty.uuidString)))
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Book.schema)
            .deleteField("user_id")
            .update()

        try await database.schema(User.schema).delete()
    }
}
