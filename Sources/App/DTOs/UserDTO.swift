//
//  UserDTO.swift
//  bookreadersrv
//
//  Created by sionyx on 02.01.2026.
//

import Fluent
import Vapor

struct UserDTO: Content {
    var id: UUID?
    var createDate: Date?
    var updateDate: Date?
    var deleteDate: Date?
    var login: String?
    var pass: String?
    var previewUrl: String?
    var medium_url: String? = nil
    var photoUrl: String?
    var link: String?
    var description: String?
    
    func toModel() -> User {
        let model = User(id: self.id,
                         login: self.login ?? "",
                         pass: self.pass ?? "",
                         photoUrl: self.photoUrl,
                         link: self.link,
                         description: self.description,
                         createDate: self.createDate,
                         updateDate: self.updateDate,
                         deleteDate: self.deleteDate,
                         previewUrl: self.previewUrl,
                         mediumUrl: self.medium_url)

        return model
    }
}

extension User {
    func toDTO() -> UserDTO {
        .init(
            id: self.id,
            createDate: self.createDate,
            updateDate: self.updateDate,
            deleteDate: self.deleteDate,
            login: self.$login.value,
            pass: nil,
            previewUrl: self.previewUrl,
            medium_url: self.mediumUrl,
            photoUrl: self.$photoUrl.value,
            link: self.$link.value,
            description: self.$description.value
        )
    }
}
