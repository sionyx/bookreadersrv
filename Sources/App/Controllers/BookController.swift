import Fluent
import Vapor

struct BookController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let books = routes.grouped("books")

        books.get(use: self.index)
        books.post(use: self.create)
        books.group(":bookID") { book in
            book.get(use: self.one)
            book.put(use: self.update)
            book.delete(use: self.delete)
        }
    }
    
    // загрузка фалйов в s3
    // https://swifttoolkit.dev/posts/vapor-file-upload

    @Sendable
    func index(req: Request) async throws -> [BookDTO] {
        try await Book.query(on: req.db).all().map { $0.toDTO() }
    }

    @Sendable
    func one(req: Request) async throws -> BookDTO {
        guard let book = try await Book.find(req.parameters.get("bookID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        return book.toDTO()
    }

    @Sendable
    func create(req: Request) async throws -> BookDTO {
        let section = try req.content.decode(BookDTO.self).toModel()

        try await section.save(on: req.db)
        return section.toDTO()
    }
    
    @Sendable
    func update(req: Request) async throws -> BookDTO {
        guard let book = try await Book.find(req.parameters.get("bookID"), on: req.db) else {
            throw Abort(.notFound)
        }
        let updatedBook = try req.content.decode(BookDTO.self)
        book.$author.id = updatedBook.authorId
        book.$section.id = updatedBook.sectionId
        book.title = updatedBook.title
        book.duration = updatedBook.duration
        book.mediaUrl = updatedBook.mediaUrl
        book.previewUrl = updatedBook.previewUrl
        book.coverUrl = updatedBook.coverUrl
        book.textLink = updatedBook.textLink
        book.description = updatedBook.description
        book.publishDate = Date(timeIntervalSince1970: updatedBook.publishDate)
        book.template = updatedBook.template
        
        try await book.save(on: req.db)
        return book.toDTO()
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let book = try await Book.find(req.parameters.get("bookID"), on: req.db) else {
            throw Abort(.notFound)
        }

        try await book.delete(on: req.db)
        return .noContent
    }
}
