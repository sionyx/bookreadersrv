
import Fluent
import Vapor

struct AppSectionController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let sections = routes.grouped("sections")
        
        sections.get(use: self.index)
        sections.get(":sectionName", use: self.section)
        
        let books = routes.grouped("books")
        books.get(":bookId", use: self.book)
        
        let authors = routes.grouped("authors")
        authors.get(":authorId", use: self.author)
    }
    
    @Sendable
    func index(req: Request) async throws -> View {
        let sections = try await Section.query(on: req.db)
            .filter(\.$parent.$id == .none)
            .all()
            .map { $0.toDTO() }
        
        return try await req.view.render("section", PageModel(title: "Каталог",
                                                              description: "Разделы приложения",
                                                              baseUrl: req.baseUrl,
                                                              sections: sections,
                                                              books: []))
    }
    
    @Sendable
    func section(req: Request) async throws -> View {
        guard let sectionName = req.parameters.get("sectionName") else {
            throw Abort(.badRequest)
        }
        
        guard let section = try await Section.query(on: req.db)
            .filter(\.$name == sectionName)
            .first() else {
            throw Abort(.notFound)
        }
        
        guard let sectionId = section.id else {
            throw Abort(.internalServerError, reason: "Section has no id")
        }
        
        let sections = try await Section.query(on: req.db)
            .filter(\.$parent.$id == sectionId)
            .all()
            .map { $0.toDTO() }
        
        let books = try await Book.query(on: req.db)
            .filter(\.$section.$id == sectionId)
            .with(\.$author)
            .with(\.$section)
            .all()
            .map { $0.toShortDTO() }
        
        var template = "books"
        if !section.template.isEmpty {
            template = section.template
        }
        
        return try await req.view.render(template, PageModel(title: section.title,
                                                             description: section.description,
                                                             baseUrl: req.baseUrl,
                                                             sections: sections,
                                                             books: books))
    }
    
    @Sendable
    func book(req: Request) async throws -> View {
        // https://bookreader.hb.ru-msk.vkcloud-storage.ru/bookreader-player.json
        guard let bookIdStr = req.parameters.get("bookId"),
              let bookId = UUID(uuidString: bookIdStr) else {
            throw Abort(.badRequest)
        }
        
        let book = try await Book.query(on: req.db)
            .filter(\.$id == bookId)
            .with(\.$author)
            .with(\.$section)
            .first()
        
        guard let book = book else {
            throw Abort(.notFound)
        }
        
        let sectionBooks = try await Book.query(on: req.db)
            .filter(\.$id != book.requireID())
            .filter(\.$section.$id == book.$section.id)
            .with(\.$author)
            .range(..<10)
            .all()
            .map { $0.toShortDTO(sectionTitle: book.section.title) }
        
        let authorBooks = try await Book.query(on: req.db)
            .filter(\.$id != book.requireID())
            .filter(\.$author.$id == book.$author.id)
            .with(\.$section)
            .range(..<10)
            .all()
            .map { $0.toShortDTO(authorFirstName: book.author.firstName, authorLastName: book.author.lastName) }
        
        var template = "bookplayer"
        if let bookTemplate = book.template,
           !bookTemplate.isEmpty {
            template = bookTemplate
        }
        else if let sectionBookTemplate = book.section.bookTemplate,
                !sectionBookTemplate.isEmpty {
            template = sectionBookTemplate
        }
        
        return try await req.view.render(template, PlayerModel(book: book.toDetailsDTO(),
                                                               baseUrl: req.baseUrl,
                                                               sectionBooks: sectionBooks,
                                                               authorBooks: authorBooks ))
    }
    
    @Sendable
    func author(req: Request) async throws -> View {
        guard let author = try await Author.find(req.parameters.get("authorId"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let books = try await Book.query(on: req.db)
            .filter(\.$author.$id == author.requireID())
            .with(\.$section)
            .all()
            .map { $0.toShortDTO(authorFirstName: author.firstName, authorLastName: author.lastName) }
        
        let template = "author"
        
        return try await req.view.render(template, AuthorModel(author: author.toDTO(),
                                                               baseUrl: req.baseUrl,
                                                               books: books ))
    }
}

fileprivate struct PageModel: Codable {
    let title: String
    let description: String
    let baseUrl: String
    let sections: [SectionDTO]
    let books: [BookShortDTO]
}

fileprivate struct PlayerModel: Codable {
    let book: BookDetailsDTO
    let baseUrl: String
    let sectionBooks: [BookShortDTO]
    let authorBooks: [BookShortDTO]
}

fileprivate struct AuthorModel: Codable {
    let author: AuthorDTO
    let baseUrl: String
    let books: [BookShortDTO]
}



// Получить baseUrl можно через хедер от nginx
// https://stackoverflow.com/questions/44182742/get-ip-address-from-request-object-in-vapor-2-0
extension Request {
    var baseUrl: String {
        if let baseUrl = headers.first(name: "X-Base-Url") {
            return baseUrl
        }
        
        let configuration = application.http.server.configuration
        let scheme = configuration.tlsConfiguration == nil ? "http" : "https"
        let host = configuration.hostname
        let port = configuration.port
        return "\(scheme)://\(host):\(port)"
    }
}
