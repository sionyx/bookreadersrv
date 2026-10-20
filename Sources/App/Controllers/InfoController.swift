//
//  InfoController.swift
//  bookreadersrv
//
//  Created by sionyx on 12.02.2026.
//

import Fluent
import Vapor

struct InfoController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let info = routes.grouped("info")
        
        info.get("books", ":book", use: self.books)
        info.get("player", ":book", use: self.books)
        info.get("sections", ":section", use: self.sections)
        info.get("authors", ":author", use: self.authors)
        info.get("users", ":user", use: self.users)
    }
    
    @Sendable
    func sections(req: Request) async throws -> InfoDTO {
        try await Section.resolve(req.parameters.get("section"), on: req.db).toInfoDTO()
    }

    @Sendable
    func books(req: Request) async throws -> InfoDTO {
        let book = try await Book.matching(req.parameters.get("book"), on: req.db)
            .with(\.$roles) { role in role.with(\.$author) }
            .first()
        guard let book else {
            throw Abort(.notFound)
        }
        return book.toInfoDTO()
    }

    @Sendable
    func authors(req: Request) async throws -> InfoDTO {
        try await Author.resolve(req.parameters.get("author"), on: req.db).toInfoDTO()
    }

    @Sendable
    func users(req: Request) async throws -> InfoDTO {
        guard let user = req.parameters.get("user") else {
            throw Abort(.notFound)
        }
        
        guard let info = try await User
            .query(on: req.db)
            .filter(\.$login, .equal, user)
            .first()?.toInfoDTO() else {
            throw Abort(.notFound)
        }
        
        return info
    }
}
