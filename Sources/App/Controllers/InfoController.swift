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
        guard let section = req.parameters.get("section") else {
            throw Abort(.notFound)
        }
        
        guard let info = try await Section
            .query(on: req.db)
            .filter(\.$name, .equal, section)
            .first()?.toInfoDTO() else {
            throw Abort(.notFound)
        }
        
        return info
    }

    @Sendable
    func books(req: Request) async throws -> InfoDTO {
        guard let book = req.parameters.get("book"),
              let bookId = UUID(uuidString: book) else {
            throw Abort(.notFound)
        }
        
        guard let info = try await Book
            .query(on: req.db)
            .filter(\.$id, .equal, bookId)
            .first()?.toInfoDTO() else {
            throw Abort(.notFound)
        }
        
        return info
    }
    
    @Sendable
    func authors(req: Request) async throws -> InfoDTO {
        guard let author = req.parameters.get("author"),
              let authorId = UUID(uuidString: author) else {
            throw Abort(.notFound)
        }
        
        guard let info = try await Author
            .query(on: req.db)
            .filter(\.$id, .equal, authorId)
            .first()?.toInfoDTO() else {
            throw Abort(.notFound)
        }
        
        return info
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
