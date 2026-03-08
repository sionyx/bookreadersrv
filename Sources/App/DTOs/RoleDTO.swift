//
//  RoleDTO.swift
//  bookreadersrv
//
//  Created by sionyx on 02.01.2026.
//

import Fluent
import Vapor

struct RoleDTO: Content {
    var id: UUID?
    var createDate: Date?
    var updateDate: Date?
    var deleteDate: Date?
    var bookId: Book.IDValue?
    var authorId: Section.IDValue?
    var type: RoleType
    var author: AuthorDTO?
    var typeString: String? // Для локализации сериализации

    func toModel(bookId: UUID = UUID.empty) -> Role {
        let model = Role(id: self.id,
                         bookID: self.bookId ?? bookId,
                         authorID: self.authorId ?? UUID.empty,
                         type: self.type,
                         createDate: self.createDate,
                         updateDate: self.updateDate,
                         deleteDate: self.deleteDate)
                
        return model
    }
}

extension Role {
    func toDTO() -> RoleDTO {
        RoleDTO(id: self.id,
                createDate: self.createDate,
                updateDate: self.updateDate,
                deleteDate: self.deleteDate,
                bookId: self.$book.id,
                authorId: self.$author.id,
                type: self.type,
                author: self.$author.value?.toDTO(),
                typeString: self.type.description
        )
    }
}
