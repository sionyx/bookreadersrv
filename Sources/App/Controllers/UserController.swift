//
//  UserController.swift
//  bookreadersrv
//
//  Created by sionyx on 08.01.2026.
//

import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users")

        users.get(use: self.index)
        users.post(use: self.create)
        users.group(":userID") { user in
            user.get(use: self.one)
            user.put(use: self.update)
            user.delete(use: self.delete)
        }
        users.group("search") { user in
            user.get(use: self.search)
        }
    }

    @Sendable
    func index(req: Request) async throws -> Page<UserDTO> {
        try await User.query(on: req.db)
            .sort(\.$login)
            .paginate(for: req)
            .map { $0.toDTO() }
    }
    
    @Sendable
    func one(req: Request) async throws -> UserDTO {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return user.toDTO()
    }

    @Sendable
    func search(req: Request) async throws -> Page<UserDTO> {
        let userSearch = try req.query.decode(UserSearch.self)
        guard let name = userSearch.name  else {
            throw Abort(.badRequest)
        }
        
        if name.isEmpty {
            return try await User
                .query(on: req.db)
                .sort(\.$updateDate)
                .paginate(for: req)
                .map { $0.toDTO() }
        }
        else {
            return try await User
                .query(on: req.db)
                .filter(\.$login, .custom("ilike"), "%\(name)%")
                .sort(\.$login)
                .paginate(for: req)
                .map { $0.toDTO() }
        }
    }

    @Sendable
    func create(req: Request) async throws -> UserDTO {
        let user = try req.content.decode(UserDTO.self).toModel()

        try await user.save(on: req.db)
        return user.toDTO()
    }
    
    @Sendable
    func update(req: Request) async throws -> UserDTO {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let updatedUser = try req.content.decode(UserDTO.self)
        user.login = updatedUser.login ?? ""
        user.photoUrl = updatedUser.photoUrl ?? ""
        user.link = updatedUser.link ?? ""
        user.description = updatedUser.description ?? ""
        if let pass = updatedUser.pass,
           !pass.isEmpty,
           let hash = pass.sha1() {
            user.pass = hash
        }

        try await user.save(on: req.db)
        return user.toDTO()
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound)
        }

        try await user.delete(on: req.db)
        return .ok
    }
}

struct UserPage: Content {
    var limit: UInt?
    var offset: UInt?
}


struct UserSearch: Content {
    var name: String?
}
