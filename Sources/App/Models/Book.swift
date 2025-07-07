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



    init() { }

    init(id: UUID? = nil, authorID: Author.IDValue, sectionID: Section.IDValue, title: String, duration: Int32, mediaUrl: String, previewUrl: String, coverUrl: String, textLink: String, description: String, publishDate: Date, template: String) {
        self.id = id
        self.title = title
        self.$author.id = authorID
        self.$section.id = sectionID
        self.duration = duration
        self.mediaUrl = mediaUrl
        self.previewUrl = previewUrl
        self.coverUrl = coverUrl
        self.textLink = textLink
        self.description = description
        self.publishDate = publishDate
        self.template = template
    }
    
    func toDTO() -> BookDTO {
        BookDTO(
            id: self.id,
            createDate: self.createDate?.timeIntervalSince1970,
            updateDate: self.updateDate?.timeIntervalSince1970,
            deleteDate: self.deleteDate?.timeIntervalSince1970,
            authorId: self.$author.id,
            sectionId: self.$section.id,
            title: self.$title.value ?? "",
            duration: self.$duration.value ?? 0,
            mediaUrl: self.$mediaUrl.value ?? "",
            previewUrl: self.previewUrl ?? "",
            coverUrl: self.$coverUrl.value ?? "",
            textLink: self.$textLink.value ?? "",
            description: self.$description.value ?? "",
            publishDate: self.publishDate?.timeIntervalSince1970 ?? 0,
            template: self.template ?? ""
        )
    }
    
    func toShortDTO(authorFirstName: String? = nil, authorLastName: String? = nil, sectionTitle: String? = nil) -> BookShortDTO {
        BookShortDTO(
            id: self.id,
            author: "\(authorFirstName ?? self.author.firstName) \(authorLastName ?? self.author.lastName)",
            section: sectionTitle ?? self.section.title,
            title: self.title,
            previewUrl: self.previewUrl ?? ""
        )
    }
    
    func toDetailsDTO() -> BookDetailsDTO {
        BookDetailsDTO(
            id: self.id,
            authorFirstName: self.author.firstName,
            authorLastName: self.author.lastName,
            sectionTitle: self.section.title,
            title: self.$title.value ?? "",
            duration: self.$duration.value ?? 0,
            mediaUrl: self.$mediaUrl.value ?? "",
            previewUrl: self.previewUrl ?? "",
            coverUrl: self.$coverUrl.value ?? "",
            textLink: self.$textLink.value ?? "",
            description: self.$description.value ?? "",
            publishDate: self.publishDate?.timeIntervalSince1970 ?? 0,
            template: self.template ?? ""
        )
    }
}


