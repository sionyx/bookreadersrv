
//
//  AuthorDTO.swift
//  bookreadersrv
//
//  Created by v.balashov on 16.10.2024.
//

import Fluent
import Vapor

struct AuthorDTO: Content {
    var id: UUID?
    var firstName: String?
    var lastName: String?
    var photoUrl: String?
    var link: String?
    var description: String?
    
    func toModel() -> Author {
        let model = Author(id: self.id,
                           firstName: self.firstName ?? "",
                           lastName: self.lastName ?? "",
                           photoUrl: self.photoUrl,
                           link: self.link,
                           description: self.description)
        
        return model
    }
}
