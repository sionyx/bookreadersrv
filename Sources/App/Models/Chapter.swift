//
//  Chapter.swift
//  bookreadersrv
//
//  Created by sionyx on 12.01.2026.
//

import Vapor
import Fluent
import struct Foundation.UUID

final class Chapter: Model, @unchecked Sendable {
    static let schema = "chapters"
    
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
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "cover_url")
    var coverUrl: String?

    @Field(key: "preview_url")
    var previewUrl: String?

    @Field(key: "media_url")
    var mediaUrl: String

    @Field(key: "publish_date")
    var publishDate: Date?
    
    @Field(key: "link")
    var link: String?

    @Field(key: "description")
    var description: String?
    
    init() { }

    init(id: UUID? = nil, bookID: Book.IDValue, title: String, coverUrl: String? = nil, previewUrl: String? = nil, mediaUrl: String, link: String? = nil, description: String? = nil, publishDate: Date? = nil, createDate: Date? = nil, updateDate: Date? = nil, deleteDate: Date? = nil) {
        self.id = id
        self.createDate = createDate
        self.updateDate = updateDate
        self.deleteDate = deleteDate
        self.$book.id = bookID
        self.title = title
        self.coverUrl = coverUrl ?? ""
        self.previewUrl = previewUrl ?? ""
        self.mediaUrl = mediaUrl
        self.publishDate = publishDate
        self.link = link ?? ""
        self.description = description ?? ""
    }
}



