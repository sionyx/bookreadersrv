
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
final class Section: LinkNamedModel, @unchecked Sendable {
    static let schema = "sections"
    
    @ID(key: .id)
    var id: UUID?
    
    @OptionalParent(key: "section_id")
    var parent: Section?
    
    // Stable readable identifier used in URLs.
    @Field(key: "link_name")
    var linkName: String

    @Field(key: "title")
    var title: String

    @Field(key: "cover_url")
    var coverUrl: String

    @Field(key: "preview_url")
    var previewUrl: String?

    @Field(key: "medium_url")
    var mediumUrl: String?

    @Field(key: "text_link")
    var textLink: String

    @Field(key: "description")
    var description: String

    @Field(key: "template")
    var template: String

    @Field(key: "book_template")
    var bookTemplate: String?


    init() { }

    init(id: UUID? = nil, parentID: Section.IDValue? = nil, name: String, title: String, coverUrl: String?, textLink: String?, description: String?, template: String?, bookTemplate: String?, previewUrl: String? = nil, mediumUrl: String? = nil) {
        self.id = id
        self.$parent.id = parentID
        self.linkName = name
        self.title = title
        self.coverUrl = coverUrl ?? ""
        self.textLink = textLink ?? ""
        self.description = description ?? ""
        self.template = template ?? ""
        self.bookTemplate = bookTemplate ?? ""
        self.previewUrl = previewUrl
        self.mediumUrl = mediumUrl
    }
}
