//
//  InfoDTO.swift
//  bookreadersrv
//
//  Created by sionyx on 12.02.2026.
//

import Fluent
import Vapor

struct InfoDTO: Content {
    var link_name: String? = nil
    var title: String
    var description: String
    var previewUrl: String
}

extension Book {
    func toInfoDTO() -> InfoDTO {
        InfoDTO(link_name: self.linkName, title: self.title,
                description: self.description,
                previewUrl: self.coverUrl)
    }
}

extension Section {
    func toInfoDTO() -> InfoDTO {
        InfoDTO(link_name: self.linkName, title: self.title,
                description: self.description,
                previewUrl: self.coverUrl)
    }
}

extension Author {
    func toInfoDTO() -> InfoDTO {
        InfoDTO(link_name: self.linkName, title: "\(self.firstName) \(self.lastName)",
                description: self.description,
                previewUrl: self.photoUrl)
    }
}

extension User {
    func toInfoDTO() -> InfoDTO {
        InfoDTO(title: self.login,
                description: self.description,
                previewUrl: self.photoUrl)
    }
}
