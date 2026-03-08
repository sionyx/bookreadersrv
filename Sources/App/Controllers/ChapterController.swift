//
//  ChapterController.swift
//  bookreadersrv
//
//  Created by sionyx on 15.01.2026.
//

import Fluent
import Vapor

struct ChapterController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let chapters = routes.grouped("chapters")
        
        chapters.group(":chapterID") { chapter in
            chapter.get(use: self.one)
            chapter.put(use: self.update)
            chapter.delete(use: self.delete)
        }
    }
    
    @Sendable
    func one(req: Request) async throws -> ChapterDTO {
        guard let chapter = try await Chapter.find(req.parameters.get("chapterID"), on: req.db) else {
            throw Abort(.notFound)
        }

        return chapter.toDTO(0)
    }
    
    @Sendable
    func update(req: Request) async throws -> ChapterDTO {
        guard let chapter = try await Chapter.find(req.parameters.get("chapterID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let updatedChapter = try req.content.decode(ChapterDTO.self)
        chapter.update(with: updatedChapter)
        
        try await chapter.save(on: req.db)
        return chapter.toDTO(0)
    }
    
    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let chapter = try await Chapter.find(req.parameters.get("chapterID"), on: req.db) else {
            throw Abort(.notFound)
        }

        try await chapter.delete(on: req.db)
        return .ok
    }
}
