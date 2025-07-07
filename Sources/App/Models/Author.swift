//
//  Author.swift
//  bookreadersrv
//
//  Created by v.balashov on 16.10.2024.
//

import Fluent
import struct Foundation.UUID

final class Author: Model, @unchecked Sendable {
    static let schema = "authors"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String

    @Field(key: "photo_url")
    var photoUrl: String
    
    @Field(key: "link")
    var link: String

    @Field(key: "description")
    var description: String

    init() { }

    init(id: UUID? = nil, firstName: String, lastName: String, photoUrl: String? = nil, link: String? = nil, description: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.photoUrl = photoUrl ?? ""
        self.link = link ?? ""
        self.description = description ?? ""
    }
    
    func toDTO() -> AuthorDTO {
        .init(
            id: self.id,
            firstName: self.$firstName.value,
            lastName: self.$lastName.value,
            photoUrl: self.$photoUrl.value,
            link: self.$link.value,
            description: self.$description.value
        )
    }
}
