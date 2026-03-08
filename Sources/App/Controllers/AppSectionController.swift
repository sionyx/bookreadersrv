
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
        
        let player = routes.grouped("player")
        player.get(":bookId", use: self.player)

        let page = routes.grouped("page")
        page.get(":template", use: self.page)
    }
    
    @Sendable
    func index(req: Request) async throws -> View {
        let sections = try await Section.query(on: req.db)
            .filter(\.$parent.$id == .none)
            .all()
            .map { $0.toDTO() }
        
        return try await req.view.render("root", SectionModel(title: "Каталог",
                                                              description: "Разделы приложения",
                                                              sections: sections,
                                                              books: [],
                                                              baseUrl: req.baseUrl,
                                                              platform: req.platform))
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
            .filter(\.$publishDate < Date.now)
            .sort(\.$publishDate)
            .with(\.$user)
            .with(\.$author)
            .with(\.$section)
            .with(\.$roles) { role in
                role.with(\.$author)
            }
            .all()
            .map { $0.toShortDTO() }
        
        var template = "section"
        if !section.template.isEmpty {
            template = section.template
        }
        
        return try await req.view.render(template, SectionModel(title: section.title,
                                                                description: section.description,
                                                                sections: sections,
                                                                books: books,
                                                                baseUrl: req.baseUrl,
                                                                platform: req.platform))
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
            .with(\.$user)
            .with(\.$author)
            .with(\.$section)
            .with(\.$roles) { role in
                role.with(\.$author)
            }
            .with(\.$chapters)
            .first()
        
        guard let bookDTO = book?.toDetailsDTO() else {
            throw Abort(.notFound)
        }
        
        let sectionBooks = try await Book.query(on: req.db)
            .filter(\.$id != bookDTO.id!)
            .filter(\.$section.$id == bookDTO.section.id!)
            .filter(\.$publishDate < Date.now)
            .sort(\.$publishDate)
            .with(\.$user)
            .range(..<10)
            .all()
            .map { $0.toShortDTO(sectionTitle: bookDTO.section.title) }
        
        let userBooks = try await Book.query(on: req.db)
            .filter(\.$id != bookDTO.id!)
            .filter(\.$user.$id == bookDTO.user.id!)
            .filter(\.$publishDate < Date.now)
            .sort(\.$publishDate)
            .with(\.$user)
            .with(\.$section)
            .range(..<10)
            .all()
            .map { $0.toShortDTO() }
        
        var template = "book"
        if !bookDTO.template.isEmpty {
            template = bookDTO.template
        }
        else if !bookDTO.section.bookTemplate.isEmpty {
            template = bookDTO.section.bookTemplate
        }
        
        return try await req.view.render(template, BookModel(book: bookDTO,
                                                             sectionBooks: sectionBooks,
                                                             userBooks: userBooks,
                                                             baseUrl: req.baseUrl,
                                                             platform: req.platform))
    }
    
    @Sendable
    func author(req: Request) async throws -> View {
        guard let author = try await Author.find(req.parameters.get("authorId"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let books = try await Book.query(on: req.db)
            .filter(\.$author.$id == author.requireID())
            .filter(\.$publishDate < Date.now)
            .sort(\.$publishDate)
            .with(\.$user)
            .with(\.$section)
            .with(\.$roles) { role in
                role.with(\.$author)
            }
            .all()
            .map { $0.toShortDTO() }
        
        let template = "author"
        
        return try await req.view.render(template, AuthorModel(author: author.toDTO(),
                                                               books: books,
                                                               baseUrl: req.baseUrl,
                                                               platform: req.platform))
    }
    
    @Sendable
    func player(req: Request) async throws -> View {
        guard let bookIdStr = req.parameters.get("bookId"),
              let bookId = UUID(uuidString: bookIdStr) else {
            throw Abort(.badRequest)
        }
                
        let book = try await Book.query(on: req.db)
            .filter(\.$id == bookId)
            .with(\.$user)
            .with(\.$author)
            .with(\.$section)
            .with(\.$roles) { role in
                role.with(\.$author)
            }
            .with(\.$chapters)
            .first()
        
        guard let bookDTO = book?.toDetailsDTO() else {
            throw Abort(.notFound)
        }
        
        let template = "player"
        return try await req.view.render(template,
                                         PlayerModel(book: bookDTO,
                                                     baseUrl: req.baseUrl,
                                                     platform: req.platform))
    }

    @Sendable
    func page(req: Request) async throws -> View {
        guard let template = req.parameters.get("template"),
              template.starts(with: "page-") else {
            throw Abort(.badRequest)
        }
        
        return try await req.view.render(template, PageModel(baseUrl: req.baseUrl,
                                                             platform: req.platform ))
    }

}


fileprivate struct SectionModel: Codable {
    let title: String
    let description: String
    let sections: [SectionDTO]
    let books: [BookShortDTO]
    let baseUrl: String
    let platform: String
}

fileprivate struct BookModel: Codable {
    let book: BookDetailsDTO
    let sectionBooks: [BookShortDTO]
    let userBooks: [BookShortDTO]
    let baseUrl: String
    let platform: String
}

fileprivate struct AuthorModel: Codable {
    let author: AuthorDTO
    let books: [BookShortDTO]
    let baseUrl: String
    let platform: String
}

fileprivate struct PlayerModel: Codable {
    let book: BookDetailsDTO
    let baseUrl: String
    let platform: String
}

fileprivate struct PageModel: Codable {
    let baseUrl: String
    let platform: String
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
    
    var platform: String {
        return headers.first(name: "X-Platform") ?? "any"
    }
}
