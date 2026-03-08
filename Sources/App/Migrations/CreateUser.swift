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
        
        let user = User(id: UUID.empty,
                        login: "unknown",
                        pass: "")
        try await user.save(on: database)
        
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
