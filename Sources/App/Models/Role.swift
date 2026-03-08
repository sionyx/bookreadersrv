//
//  Role.swift
//  bookreadersrv
//
//  Created by sionyx on 02.01.2026.
//

import Vapor
import Fluent
import struct Foundation.UUID


enum RoleType: String, Codable {
    case author
    case translator
    case reader
    case host
}

extension RoleType: CustomStringConvertible {
    var description: String {
        switch self {
        case .author:
            return "Автор"
        case .translator:
            return "Переводчик"
        case .reader:
            return "Чтец"
        case .host:
            return "Ведущий"
        }
    }
}


final class Role: Model, @unchecked Sendable {
    static let schema = "roles"
    
    @ID(key: .id)
    var id: UUID?
    
    @Timestamp(key: "create_date", on: .create)
    var createDate: Date?

    @Timestamp(key: "update_date", on: .update)
    var updateDate: Date?

    @Timestamp(key: "delete_date", on: .delete)
    var deleteDate: Date?

    @Parent(key: "book_id")
    var book: Book

    @Parent(key: "author_id")
    var author: Author

    @Field(key: "type")
    var type: RoleType

    init() { }

    init(id: UUID? = nil, bookID: Book.IDValue, authorID: Author.IDValue, type: RoleType, createDate: Date? = nil, updateDate: Date? = nil, deleteDate: Date? = nil) {
        self.id = id
        self.createDate = createDate
        self.updateDate = updateDate
        self.deleteDate = deleteDate
        self.$book.id = bookID
        self.$author.id = authorID
        self.type = type
        
    }
}
