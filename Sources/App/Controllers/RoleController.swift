//
//  RoleController.swift
//  bookreadersrv
//
//  Created by sionyx on 08.01.2026.
//

import Fluent
import Vapor

struct RoleController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let roles = routes.grouped("roles")
        
        roles.group(":roleID") { role in
            role.get(use: self.one)
            role.put(use: self.update)
            role.delete(use: self.delete)
        }
    }
    
    @Sendable
    func one(req: Request) async throws -> [RoleDTO] {
        guard let bookIdStr = req.parameters.get("bookID"),
              let bookId = UUID(uuidString: bookIdStr) else {
            throw Abort(.badRequest)
        }
        let roles = try await Role.query(on: req.db).filter(\.$book.$id, .equal, bookId).all()

        return roles.map { $0.toDTO() }
    }
    
    @Sendable
    func update(req: Request) async throws -> RoleDTO {
        guard let role = try await Role.find(req.parameters.get("roleID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let updatedRole = try req.content.decode(RoleDTO.self)
        role.type = updatedRole.type
        
        try await role.save(on: req.db)
        return role.toDTO()
    }
    
    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let role = try await Role.find(req.parameters.get("roleID"), on: req.db) else {
            throw Abort(.notFound)
        }

        try await role.delete(on: req.db)
        return .ok
    }
}
