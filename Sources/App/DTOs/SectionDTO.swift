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
    var name: String
    var title: String
    var coverUrl: String?
    var textLink: String?
    var description: String?
    var template: String
    var bookTemplate: String

    func toModel() -> Section {
        let model = Section(id: self.id,
                            parentID: self.parentId,
                            name: self.name,
                            title: self.title,
                            coverUrl: self.coverUrl,
                            textLink: self.textLink,
                            description: self.description,
                            template: self.template,
                            bookTemplate: self.bookTemplate)
                
        return model
    }
}
