import Fluent
import Vapor

struct AuthorController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let authors = routes.grouped("authors")

        authors.get(use: self.index)
        authors.post(use: self.create)
        authors.group(":authorID") { author in
            author.get(use: self.one)
            author.put(use: self.update)
            author.delete(use: self.delete)
        }
        authors.group("search") { author in
            author.get(use: self.search)
        }
    }

    @Sendable
    func index(req: Request) async throws -> [AuthorDTO] {
        try await Author.query(on: req.db).all().map { $0.toDTO() }
    }
    
    @Sendable
    func one(req: Request) async throws -> AuthorDTO {
        guard let author = try await Author.find(req.parameters.get("authorID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return author.toDTO()
    }

    @Sendable
    func search(req: Request) async throws -> [AuthorDTO] {
        // если не работает case insensitive, нужно выполнить команду
        // update pg_database set datcollate='ru_RU.UTF-8', datctype='ru_RU.UTF-8' where datname='YOUR_DATABASE_NAME';
        // https://stackoverflow.com/questions/56559216/search-is-not-working-with-lowercase-like-for-russian-characters
        
        let authorSearch = try req.query.decode(AuthorSearch.self)
        guard let name = authorSearch.name  else {
            throw Abort(.badRequest)
        }
        
        return try await Author
            .query(on: req.db)
            .group(.or) { group in
                group
                    .filter(\.$firstName, .custom("ilike"), "%\(name)%")
                    .filter(\.$lastName, .custom("ilike"), "%\(name)%")
            }
            .all()
            .map { $0.toDTO() }
    }

    @Sendable
    func create(req: Request) async throws -> AuthorDTO {
        let author = try req.content.decode(AuthorDTO.self).toModel()

        try await author.save(on: req.db)
        return author.toDTO()
    }
    
    @Sendable
    func update(req: Request) async throws -> AuthorDTO {
        guard let author = try await Author.find(req.parameters.get("authorID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let updatedAuthor = try req.content.decode(AuthorDTO.self)
        author.firstName = updatedAuthor.firstName ?? ""
        author.lastName = updatedAuthor.lastName ?? ""
        author.photoUrl = updatedAuthor.photoUrl ?? ""
        author.link = updatedAuthor.link ?? ""
        author.description = updatedAuthor.description ?? ""
        
        try await author.save(on: req.db)
        return author.toDTO()
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let author = try await Author.find(req.parameters.get("authorID"), on: req.db) else {
            throw Abort(.notFound)
        }

        try await author.delete(on: req.db)
        return .noContent
    }
}


struct AuthorSearch: Content {
    var name: String?
}
