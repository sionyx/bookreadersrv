//
//  BookDTO.swift
//  bookreadersrv
//
//  Created by v.balashov on 16.10.2024.
//

import Fluent
import Vapor

struct SectionDTO: Content {
    var id: UUID?
    var parentId: Section.IDValue?
    var link_name: String?
    // Input alias for older administration clients; never encoded.
    var name: String? = nil
    var title: String
    var previewUrl: String?
    var coverUrl: String?
    var textLink: String?
    var description: String?
    var template: String
    var bookTemplate: String

    enum CodingKeys: String, CodingKey {
        case id, parentId, link_name, name, title, previewUrl, coverUrl, textLink, description, template, bookTemplate
    }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(parentId, forKey: .parentId)
        try c.encodeIfPresent(link_name, forKey: .link_name)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(previewUrl, forKey: .previewUrl)
        try c.encodeIfPresent(coverUrl, forKey: .coverUrl)
        try c.encodeIfPresent(textLink, forKey: .textLink)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encode(template, forKey: .template)
        try c.encode(bookTemplate, forKey: .bookTemplate)
    }

    func toModel() -> Section {
        let model = Section(id: self.id,
                            parentID: self.parentId,
                            name: self.link_name ?? self.name ?? "",
                            title: self.title,
                            coverUrl: self.coverUrl,
                            textLink: self.textLink,
                            description: self.description,
                            template: self.template,
                            bookTemplate: self.bookTemplate)
                
        model.previewUrl = self.previewUrl
        return model
    }
}

extension Section {
    func toDTO() -> SectionDTO {
        .init(
            id: self.id,
            parentId: self.$parent.id,
            link_name: self.linkName,
            title: self.$title.value ?? "",
            previewUrl: self.previewUrl,
            coverUrl: self.$coverUrl.value,
            textLink: self.$textLink.value,
            description: self.$description.value,
            template: self.$template.value ?? "",
            bookTemplate: self.bookTemplate ?? ""
        )
    }
}
