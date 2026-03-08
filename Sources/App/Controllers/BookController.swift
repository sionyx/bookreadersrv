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
        guard let bookIdStr = req.parameters.get("bookID"),
              let bookId = UUID(uuidString: bookIdStr) else {
            throw Abort(.badRequest)
        }
        
        let book = try await Book.query(on: req.db)
            .filter(\.$id, .equal, bookId)
            .with(\.$roles) { role in
                role.with(\.$author)
            }
            .with(\.$chapters)
            .first()

        guard let book = book else {
            throw Abort(.notFound)
        }

        return book.toDTO()
    }

    @Sendable
    func create(req: Request) async throws -> BookDTO {
        let bookDTO = try req.content.decode(BookDTO.self)
        let book = bookDTO.toModel()

        guard let authorId = bookDTO.roles?.first?.authorId else {
            throw Abort(.badRequest, reason: "Book has no author")
        }
        book.$author.id = authorId

        try await book.save(on: req.db)
        let bookId = try book.requireID()
        
        if let roleDTOs = bookDTO.roles {
            for roleDTO in roleDTOs {
                guard let authorId = roleDTO.authorId else {
                    continue
                }
                let role = try await Role.query(on: req.db)
                    .filter(\.$book.$id, .equal, bookId)
                    .filter(\.$author.$id, .equal, authorId)
                    .first()
                ?? Role(bookID: bookId, authorID: authorId, type: .author)
                
                role.type = roleDTO.type
                try await role.save(on: req.db)
            }
        }
        
        if let chapterDTOs = bookDTO.chapters {
            for chapterDTO in chapterDTOs {
                if let chapterId = chapterDTO.id,
                   let chapter = try await Chapter.find(chapterId, on: req.db) {
                    chapter.update(with: chapterDTO)
                    try await chapter.save(on: req.db)
                } else {
                    let chapter = chapterDTO.toModel(bookId: bookId)
                    try await chapter.save(on: req.db)
                }
            }
        }


        let finaleBook = try await Book.query(on: req.db)
            .filter(\.$id, .equal, bookId)
            .with(\.$roles) { role in
                role.with(\.$author)
            }
            .with(\.$chapters)
            .first() ?? book

        return finaleBook.toDTO()
    }
    
    @Sendable
    func update(req: Request) async throws -> BookDTO {
        guard let bookIdStr = req.parameters.get("bookID"),
              let bookId = UUID(uuidString: bookIdStr) else {
            throw Abort(.badRequest)
        }
        
        let book = try await Book.query(on: req.db)
            .filter(\.$id, .equal, bookId)
            .with(\.$roles) { role in
                role.with(\.$author)
            }
            .first()
        
        guard let book = book else {
            throw Abort(.notFound)
        }

        let updatedBook = try req.content.decode(BookDTO.self)
        book.$author.id = updatedBook.authorId
        book.$section.id = updatedBook.sectionId
        book.$user.id = updatedBook.userId
        book.title = updatedBook.title
        book.duration = 0
        book.mediaUrl = ""
        book.previewUrl = updatedBook.previewUrl
        book.coverUrl = updatedBook.coverUrl
        book.textLink = updatedBook.textLink
        book.description = updatedBook.description
        book.publishDate = Date(timeIntervalSince1970: updatedBook.publishDate)
        book.template = updatedBook.template
        try await book.save(on: req.db)

        if let roleDTOs = updatedBook.roles {
            for roleDTO in roleDTOs {
                guard let authorId = roleDTO.authorId else {
                    continue
                }
                let role = try await Role.query(on: req.db)
                    .filter(\.$book.$id, .equal, bookId)
                    .filter(\.$author.$id, .equal, authorId)
                    .first()
                ?? Role(bookID: bookId, authorID: authorId, type: .author)
                
                role.type = roleDTO.type
                try await role.save(on: req.db)
            }
        }
        
        if let chapterDTOs = updatedBook.chapters {
            for chapterDTO in chapterDTOs {
                if let chapterId = chapterDTO.id,
                   let chapter = try await Chapter.find(chapterId, on: req.db) {
                    chapter.update(with: chapterDTO)
                    try await chapter.save(on: req.db)
                } else {
                    let chapter = chapterDTO.toModel(bookId: bookId)
                    try await chapter.save(on: req.db)
                }
            }
        }

        let finaleBook = try await Book.query(on: req.db)
            .filter(\.$id, .equal, bookId)
            .with(\.$roles) { role in
                role.with(\.$author)
            }
            .with(\.$chapters)
            .first() ?? book
        
        return finaleBook.toDTO()
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let book = try await Book.find(req.parameters.get("bookID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let bookId = try book.requireID()
        
        try await req.db.transaction { transaction in
            let roles = try await Role.query(on: transaction)
                .filter(\.$book.$id, .equal, bookId)
                .all()
            for role in roles {
                try await role.delete(on: transaction)
            }

            let chapters = try await Chapter.query(on: transaction)
                .filter(\.$book.$id, .equal, bookId)
                .all()
            for chapter in chapters {
                try await chapter.delete(on: transaction)
            }
            
            try await book.delete(on: transaction)
        }

        return .ok
    }
}
