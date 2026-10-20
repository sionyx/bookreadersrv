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
    func index(req: Request) async throws -> Page<AuthorDTO> {
        try await Author.query(on: req.db)
            .sort(\.$lastName)
            .sort(\.$firstName)
            .paginate(for: req)
            .map { $0.toDTO() }
    }
    
    @Sendable
    func one(req: Request) async throws -> AuthorDTO {
        let author = try await Author.resolve(req.parameters.get("authorID"), on: req.db)
        
        let books = try await booksByAuthor(author, on: req.db)
        var dto = author.toDTO()
        dto.books = books.map { $0.toShortDTO() }
        return dto
    }

    @Sendable
    func search(req: Request) async throws -> Page<AuthorDTO> {
        // если не работает case insensitive, нужно выполнить команду
        // update pg_database set datcollate='ru_RU.UTF-8', datctype='ru_RU.UTF-8' where datname='YOUR_DATABASE_NAME';
        // https://stackoverflow.com/questions/56559216/search-is-not-working-with-lowercase-like-for-russian-characters
        
        let authorSearch = try req.query.decode(AuthorSearch.self)
        guard let name = authorSearch.name  else {
            throw Abort(.badRequest)
        }
        
        if name.isEmpty {
            return try await Author
                .query(on: req.db)
                //.sort(\.$updateDate)
                .paginate(for: req)
                .map { $0.toDTO() }
        }
        else {
            return try await Author
                .query(on: req.db)
                .group(.or) { group in
                    group
                        .filter(\.$firstName, .custom("ilike"), "%\(name)%")
                        .filter(\.$lastName, .custom("ilike"), "%\(name)%")
                }
                .sort(\.$lastName)
                .sort(\.$firstName)
                .paginate(for: req)
                .map { $0.toDTO() }
        }
    }

    @Sendable
    func create(req: Request) async throws -> AuthorDTO {
        let dto = try req.content.decode(AuthorDTO.self)
        let author = dto.toModel()
        try await author.assignLinkName(dto.link_name, source: "\(author.firstName) \(author.lastName)", on: req.db)

        try await author.saveWithLinkName(on: req.db)
        return author.toDTO()
    }
    
    @Sendable
    func update(req: Request) async throws -> AuthorDTO {
        let author = try await Author.resolve(req.parameters.get("authorID"), on: req.db)
        let updatedAuthor = try req.content.decode(AuthorDTO.self)
        try await author.assignLinkName(updatedAuthor.link_name, source: "\(updatedAuthor.firstName ?? "") \(updatedAuthor.lastName ?? "")", on: req.db)
        author.firstName = updatedAuthor.firstName ?? ""
        author.lastName = updatedAuthor.lastName ?? ""
        // Renaming without media fields keeps the existing S3 links.
        if let url = updatedAuthor.photoUrl { author.photoUrl = url }
        if let url = updatedAuthor.previewUrl { author.previewUrl = url }
        author.link = updatedAuthor.link ?? ""
        author.description = updatedAuthor.description ?? ""
        
        try await author.saveWithLinkName(on: req.db)
        return author.toDTO()
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        let author = try await Author.resolve(req.parameters.get("authorID"), on: req.db)

        try await author.delete(on: req.db)
        return .ok
    }
}


struct AuthorSearch: Content {
    var name: String?
}
