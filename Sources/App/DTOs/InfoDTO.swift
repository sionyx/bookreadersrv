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
                description: self.infoContributors,
                previewUrl: self.previewUrl?.nilIfEmpty() ?? self.coverUrl)
    }

    private var infoContributors: String {
        // The presence of hosts identifies podcast seasons in the shared Book model.
        let roles = self.roles
        let type: RoleType = roles.contains { $0.type == .host } ? .host : .author
        var seen = Set<UUID>()
        return roles.filter { $0.type == type }.sorted { lhs, rhs in
            let lhsDate = lhs.createDate ?? .distantPast
            let rhsDate = rhs.createDate ?? .distantPast
            if lhsDate != rhsDate { return lhsDate < rhsDate }
            return (lhs.id?.uuidString ?? "") < (rhs.id?.uuidString ?? "")
        }.compactMap { role -> String? in
            guard seen.insert(role.$author.id).inserted,
                  let author = role.$author.value else { return nil }
            let surname = author.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
            let firstName = author.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
            let initial = firstName.first.map { String($0).uppercased() + "." } ?? ""
            let name = [surname, initial].filter { !$0.isEmpty }.joined(separator: " ")
            return name.isEmpty ? nil : name
        }.joined(separator: ", ")
    }
}

extension Section {
    func toInfoDTO() -> InfoDTO {
        InfoDTO(link_name: self.linkName, title: self.title,
                description: self.description,
                previewUrl: self.previewUrl?.nilIfEmpty() ?? self.coverUrl)
    }
}

extension Author {
    func toInfoDTO() -> InfoDTO {
        InfoDTO(link_name: self.linkName, title: "\(self.firstName) \(self.lastName)",
                description: self.description,
                previewUrl: self.previewUrl?.nilIfEmpty() ?? self.photoUrl)
    }
}

extension User {
    func toInfoDTO() -> InfoDTO {
        InfoDTO(title: self.login,
                description: self.description,
                previewUrl: self.previewUrl?.nilIfEmpty() ?? self.photoUrl)
    }
}
