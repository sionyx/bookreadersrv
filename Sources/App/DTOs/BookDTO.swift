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
    var userId: User.IDValue
    var authorId: Author.IDValue
    var sectionId: Section.IDValue
    var title: String
    var previewUrl: String
    var coverUrl: String
    var textLink: String
    var description: String
    var publishDate: TimeInterval
    var template: String
    var roles: [RoleDTO]?
    var chapters: [ChapterDTO]?

    func toModel() -> Book {
        let model = Book(id: self.id,
                         userID: self.userId,
                         authorID: self.authorId,
                         sectionID: self.sectionId,
                         title: self.title,
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
    var user: String
    var section: String
    var title: String
    var previewUrl: String
}

struct BookDetailsDTO: Content {
    var id: UUID?
    var user: UserDTO
    var section: SectionDTO
    var title: String
    var previewUrl: String
    var coverUrl: String
    var textLink: String?
    var description: String?
    var publishDate: TimeInterval
    var template: String
    var roles: [RoleDTO]
    var chapters: [ChapterDTO]
}



extension Book {
    func toDTO() -> BookDTO {
        BookDTO(
            id: self.id,
            createDate: self.createDate?.timeIntervalSince1970,
            updateDate: self.updateDate?.timeIntervalSince1970,
            deleteDate: self.deleteDate?.timeIntervalSince1970,
            userId: self.$user.id,
            authorId: self.$author.id,
            sectionId: self.$section.id,
            title: self.$title.value ?? "",
            previewUrl: self.previewUrl ?? "",
            coverUrl: self.$coverUrl.value ?? "",
            textLink: self.$textLink.value ?? "",
            description: self.$description.value ?? "",
            publishDate: self.publishDate?.timeIntervalSince1970 ?? 0,
            template: self.template ?? "",
            roles: self.roles.map { $0.toDTO() },
            chapters: self.chapters.enumerated().map { $1.toDTO($0) }
        )
    }
    
    func toShortDTO(authorFirstName: String? = nil, authorLastName: String? = nil, sectionTitle: String? = nil) -> BookShortDTO {
        BookShortDTO(
            id: self.id,
            user: self.user.login,
            section: sectionTitle ?? self.section.title,
            title: self.title,
            previewUrl: self.previewUrl ?? ""
        )
    }
    
    func toDetailsDTO() -> BookDetailsDTO {
        BookDetailsDTO(
            id: self.id,
            user: self.user.toDTO(),
            section: self.section.toDTO(),
            title: self.$title.value ?? "",
            previewUrl: self.previewUrl ?? "",
            coverUrl: self.$coverUrl.value ?? "",
            textLink: self.$textLink.value?.nilIfEmpty(),
            description: self.$description.value?.nilIfEmpty(),
            publishDate: self.publishDate?.timeIntervalSince1970 ?? 0,
            template: self.template ?? "",
            roles: self.roles.map { $0.toDTO() },
            chapters: self.chapters.enumerated().map { $1.toDTO($0) }
        )
    }
}
