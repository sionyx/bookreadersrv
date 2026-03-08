//
//  User.swift
//  bookreadersrv
//
//  Created by sionyx on 02.01.2026.
//

import Vapor
import Fluent
import struct Foundation.UUID

final class User: Model, Authenticatable, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Timestamp(key: "create_date", on: .create)
    var createDate: Date?

    @Timestamp(key: "update_date", on: .update)
    var updateDate: Date?

    @Timestamp(key: "delete_date", on: .delete)
    var deleteDate: Date?

    @Field(key: "login")
    var login: String
    
    @Field(key: "pass")
    var pass: String
    
    @Field(key: "photo_url")
    var photoUrl: String
    
    @Field(key: "link")
    var link: String

    @Field(key: "description")
    var description: String
    
    init() { }

    init(id: UUID? = nil, login: String, pass: String, photoUrl: String? = nil, link: String? = nil, description: String? = nil, createDate: Date? = nil, updateDate: Date? = nil, deleteDate: Date? = nil) {
        self.id = id
        self.createDate = createDate
        self.updateDate = updateDate
        self.deleteDate = deleteDate
        self.login = login
        self.pass = pass
        self.photoUrl = photoUrl ?? ""
        self.link = link ?? ""
        self.description = description ?? ""
    }
}



