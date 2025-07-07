//
//  BookDTO.swift
//  bookreadersrv
//
//  Created by v.balashov on 16.10.2024.
//

import Fluent
import Vapor

struct BookDTO: Content {
    var id: UUID?
    var createDate: TimeInterval?
    var updateDate: TimeInterval?
    var deleteDate: TimeInterval?
    var authorId: Author.IDValue
    var sectionId: Section.IDValue
    var title: String
    var duration: Int32
    var mediaUrl: String
    var previewUrl: String
    var coverUrl: String
    var textLink: String
    var description: String
    var publishDate: TimeInterval
    var template: String

    func toModel() -> Book {
        let model = Book(id: self.id,
                         authorID: self.authorId,
                         sectionID: self.sectionId,
                         title: self.title,
                         duration: self.duration,
                         mediaUrl: self.mediaUrl,
                         previewUrl: self.previewUrl,
                         coverUrl: self.coverUrl,
                         textLink: self.textLink,
                         description: self.description,
                         publishDate: Date(timeIntervalSince1970: self.publishDate),
                         template: self.template)
                
        return model
    }
}

struct BookShortDTO: Content {
    var id: UUID?
    var author: String
    var section: String
    var title: String
    var previewUrl: String
}

struct BookDetailsDTO: Content {
    var id: UUID?
    var authorFirstName: String
    var authorLastName: String
    var sectionTitle: String
    var title: String
    var duration: Int32
    var mediaUrl: String
    var previewUrl: String
    var coverUrl: String
    var textLink: String
    var description: String
    var publishDate: TimeInterval
    var template: String
}
