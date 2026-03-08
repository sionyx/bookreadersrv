//
//  Book.swift
//  bookreadersrv
//
//  Created by v.balashov on 16.10.2024.
//

import Fluent
import struct Foundation.UUID
import struct Foundation.Date

/// Property wrappers interact poorly with `Sendable` checking, causing a warning for the `@ID` property
/// It is recommended you write your model with sendability checking on and then suppress the warning
/// afterwards with `@unchecked Sendable`.
final class Book: Model, @unchecked Sendable {
    static let schema = "books"
    
    @ID(key: .id)
    var id: UUID?
    
    @Timestamp(key: "create_date", on: .create)
    var createDate: Date?

    @Timestamp(key: "update_date", on: .update)
    var updateDate: Date?

    @Timestamp(key: "delete_date", on: .delete)
    var deleteDate: Date?

    @Parent(key: "user_id")
    var user: User

    @Parent(key: "section_id")
    var section: Section

    @Parent(key: "author_id")
    var author: Author

    @Field(key: "title")
    var title: String

    @Field(key: "duration")
    var duration: Int32

    @Field(key: "media_url")
    var mediaUrl: String

    @Field(key: "preview_url")
    var previewUrl: String?

    @Field(key: "cover_url")
    var coverUrl: String

    @Field(key: "text_link")
    var textLink: String

    @Field(key: "description")
    var description: String

    @Field(key: "publish_date")
    var publishDate: Date?

    @Field(key: "template")
    var template: String?

    @Siblings(through: Role.self, from: \.$book, to: \.$author)
    var authors: [Author]
    
    @Children(for:\.$book)
    var roles: [Role]

    @Children(for:\.$book)
    var chapters: [Chapter]


    init() { }

    init(id: UUID? = nil, userID: User.IDValue, authorID: Author.IDValue, sectionID: Section.IDValue, title: String, previewUrl: String, coverUrl: String, textLink: String, description: String, publishDate: Date, template: String) {
        self.id = id
        self.$user.id = userID
        self.title = title
        self.$author.id = authorID
        self.$section.id = sectionID
        self.duration = 0
        self.mediaUrl = ""
        self.previewUrl = previewUrl
        self.coverUrl = coverUrl
        self.textLink = textLink
        self.description = description
        self.publishDate = publishDate
        self.template = template
    }
}


