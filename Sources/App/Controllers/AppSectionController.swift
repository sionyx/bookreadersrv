
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
        
        // Existing featured cards keep their entity IDs internally; navigation uses current link_name.
        let featured: [(String, String, UUID)] = [
            ("item1", "books", UUID(uuidString: "E740F417-7352-4F8D-9DAF-A51D6AA98994")!),
            ("item2", "books", UUID(uuidString: "5EA6D77D-95E3-441E-A4C6-C26B10A5C0B6")!),
            ("item3", "books", UUID(uuidString: "63A78E52-F82C-4281-A031-D889E443A697")!),
            ("item4", "books", UUID(uuidString: "3B11DCE7-3E1C-4FED-9212-DCA2A0401B52")!),
            ("item5", "books", UUID(uuidString: "CF3207C6-220A-490E-9401-CA3CF757B3D7")!),
            ("item6", "authors", UUID(uuidString: "12BF57E6-B7BF-4648-9A50-8E1F463D8C20")!)
        ]
        let featuredBooks = try await Book.query(on: req.db)
            .filter(\.$id ~~ featured.filter { $0.1 == "books" }.map { $0.2 }).all()
        let featuredAuthors = try await Author.query(on: req.db)
            .filter(\.$id ~~ featured.filter { $0.1 == "authors" }.map { $0.2 }).all()
        var featuredLinks: [String: String] = [:]
        for (key, kind, id) in featured {
            let name = kind == "books" ? featuredBooks.first { $0.id == id }?.linkName
                : featuredAuthors.first { $0.id == id }?.linkName
            featuredLinks[key] = name.map { "/app/\(kind)/\($0)" } ?? "/app/sections"
        }

        return try await req.view.render("root", SectionModel(featuredLinks: featuredLinks, title: "Каталог",
                                                              description: "Разделы приложения",
                                                              sections: sections,
                                                              books: [],
                                                              baseUrl: req.baseUrl,
                                                              platform: req.platform))
    }
    
    @Sendable
    func section(req: Request) async throws -> View {
        let section = try await Section.resolve(req.parameters.get("sectionName"), on: req.db)

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

        
        let book = try await Book.matching(req.parameters.get("bookId"), on: req.db)
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
        let author = try await Author.resolve(req.parameters.get("authorId"), on: req.db)
        let books = try await booksByAuthor(author, on: req.db)
            .filter { ($0.publishDate ?? .distantFuture) < Date.now }
            .map { $0.toShortDTO() }

        let template = "author"
        
        return try await req.view.render(template, AuthorModel(author: author.toDTO(),
                                                               books: books,
                                                               baseUrl: req.baseUrl,
                                                               platform: req.platform))
    }
    
    @Sendable
    func player(req: Request) async throws -> View {

                
        let book = try await Book.matching(req.parameters.get("bookId"), on: req.db)
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
    var featuredLinks: [String: String] = [:]
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
