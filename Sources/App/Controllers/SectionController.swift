import Fluent
import Vapor

struct SectionController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let sections = routes.grouped("sections")

        sections.get(use: self.index)
        sections.post(use: self.create)
        sections.group(":sectionID") { section in
            section.get(use: self.one)
            section.put(use: self.update)
            section.delete(use: self.delete)
        }
        sections.group("search") { section in
            section.get(use: self.search)
        }
        sections.group("path", ":sectionID") { section in
            section.get(use: self.path)
        }
    }

    @Sendable
    func index(req: Request) async throws -> [SectionDTO] {
        try await Section.query(on: req.db)
            .filter(\.$parent.$id == .null)
            .all()
            .map { $0.toDTO() }
    }

    @Sendable
    func one(req: Request) async throws -> SectionContent {
        guard let section = try await Section.find(req.parameters.get("sectionID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let subsections = try await Section.query(on: req.db)
            .filter(\.$parent.$id == section.requireID())
            .all()
        
        let books = try await Book.query(on: req.db)
            .filter(\.$section.$id == section.requireID())
            .with(\.$author)
            .with(\.$section)
            .all()
        
        return SectionContent(section: section.toDTO(),
                              sections: subsections.map { $0.toDTO() },
                              books: books.map { $0.toShortDTO() })
    }

    @Sendable
    func search(req: Request) async throws -> [SectionDTO] {
        let sectionSearch = try req.query.decode(SectionSearch.self)
        guard let title = sectionSearch.title  else {
            throw Abort(.badRequest)
        }
        
        return try await Section
            .query(on: req.db)
            .filter(\.$title, .custom("ilike"), "%\(title)%")
            .all()
            .map { $0.toDTO() }
    }
    
    @Sendable
    func path(req: Request) async throws -> [SectionDTO] {
        var section = try await Section.find(req.parameters.get("sectionID"), on: req.db)
        if section == nil {
            throw Abort(.notFound)
        }
        
        var path = [section!.toDTO()]
        repeat {
            let parentId = section?.$parent.id
            section = try await Section.find(parentId, on: req.db)
            if let section = section {
                path.insert(section.toDTO(), at: 0)
            }
            
        } while(section?.$parent.id != nil)
        
        return path
    }

    @Sendable
    func create(req: Request) async throws -> SectionDTO {
        let section = try req.content.decode(SectionDTO.self).toModel()

        try await section.save(on: req.db)
        return section.toDTO()
    }
    
    @Sendable
    func update(req: Request) async throws -> SectionDTO {
        guard let section = try await Section.find(req.parameters.get("sectionID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let updatedSection = try req.content.decode(SectionDTO.self)
        section.$parent.id = updatedSection.parentId
        section.name = updatedSection.name
        section.title = updatedSection.title
        section.coverUrl = updatedSection.coverUrl ?? ""
        section.textLink = updatedSection.textLink ?? ""
        section.description = updatedSection.description ?? ""
        section.template = updatedSection.template
        section.bookTemplate = updatedSection.bookTemplate

        try await section.save(on: req.db)
        return section.toDTO()
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let section = try await Section.find(req.parameters.get("sectionID"), on: req.db) else {
            throw Abort(.notFound)
        }

        try await section.delete(on: req.db)
        return .noContent
    }
}

struct SectionContent: Content {
    let section: SectionDTO
    let sections: [SectionDTO]
    let books: [BookShortDTO]
}

struct SectionSearch: Content {
    var title: String?
}

struct SectionPath: Content {
    var id: String?
}
