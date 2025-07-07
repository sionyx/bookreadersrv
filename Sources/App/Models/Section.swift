
//
//  Book.swift
//  bookreadersrv
//
//  Created by v.balashov on 16.10.2024.
//

import Fluent
import struct Foundation.UUID

/// Property wrappers interact poorly with `Sendable` checking, causing a warning for the `@ID` property
/// It is recommended you write your model with sendability checking on and then suppress the warning
/// afterwards with `@unchecked Sendable`.
final class Section: Model, @unchecked Sendable {
    static let schema = "sections"
    
    @ID(key: .id)
    var id: UUID?
    
    @OptionalParent(key: "section_id")
    var parent: Section?
    
    // Name - readable id of section
    @Field(key: "name")
    var name: String

    @Field(key: "title")
    var title: String

    @Field(key: "cover_url")
    var coverUrl: String

    @Field(key: "text_link")
    var textLink: String

    @Field(key: "description")
    var description: String

    @Field(key: "template")
    var template: String

    @Field(key: "book_template")
    var bookTemplate: String?


    init() { }

    init(id: UUID? = nil, parentID: Section.IDValue? = nil, name: String, title: String, coverUrl: String?, textLink: String?, description: String?, template: String?, bookTemplate: String?) {
        self.id = id
        self.$parent.id = parentID
        self.name = name
        self.title = title
        self.coverUrl = coverUrl ?? ""
        self.textLink = textLink ?? ""
        self.description = description ?? ""
        self.template = template ?? ""
        self.bookTemplate = bookTemplate ?? ""
    }
    
    func toDTO() -> SectionDTO {
        .init(
            id: self.id,
            parentId: self.$parent.id,
            name: self.$name.value ?? "",
            title: self.$title.value ?? "",
            coverUrl: self.$coverUrl.value,
            textLink: self.$textLink.value,
            description: self.$description.value,
            template: self.$template.value ?? "",
            bookTemplate: self.bookTemplate ?? ""
        )
    }
}
