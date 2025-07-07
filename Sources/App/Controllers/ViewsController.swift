import Fluent
import Vapor
import NIOFileSystem

struct ViewsController: RouteCollection {
    let path: String
    let localDirectory: URL
    
    init(path: String, localDirectory: String) {
        self.path = path
        self.localDirectory = URL(fileURLWithPath: localDirectory)
    }
    
    func boot(routes: RoutesBuilder) throws {
        let views = routes.grouped(.constant(path))

        views.get(use: self.index)
        views.group(":viewName") { section in
            section.get(use: self.get)
            section.post(use: self.post)
            section.delete(use: self.delete)
        }
    }

    @Sendable
    func index(req: Request) async throws -> [FileInfo] {
        let files = try await req.application.fileio.listDirectory(path: localDirectory.relativePath)
        
        return files.filter { $0.type == 8 && !$0.name.starts(with: ".") }.map { FileInfo(filename: $0.name.filename()) }
    }
    
    @Sendable
    func get(req: Request) async throws -> Response {
        guard let viewName = req.parameters.get("viewName") else {
            throw Abort(.badRequest)
        }
        let path = localDirectory.appending(path: viewName).appendingPathExtension("leaf")

        return req.fileio.streamFile(at: path.relativePath)
    }
    
    @Sendable
    func post(req: Request) async throws -> Response {
        guard let viewName = req.parameters.get("viewName"),
              let fileData = req.body.data else {
            throw Abort(.badRequest)
        }
        let path = localDirectory.appending(path: viewName).appendingPathExtension("leaf")

        // rewrite template file
        try? await req.application.fileio.remove(path: path.relativePath)
        try await req.fileio.writeFile(fileData, at: path.relativePath)
        
        // remove template from cache
        let _ = try? await req.application.leaf.cache.remove(viewName, on: req.eventLoop).get()
        
        return .init(status: .ok)
    }
    
    @Sendable
    func delete(req: Request) async throws -> Response {
        guard let viewName = req.parameters.get("viewName") else {
            throw Abort(.badRequest)
        }
        let path = localDirectory.appending(path: viewName).appendingPathExtension("leaf")

        // delete template file
        try await req.application.fileio.remove(path: path.relativePath)
        
        return .init(status: .ok)
    }
}


struct FileInfo: Content {
    var filename: String
}

fileprivate extension String {
    func filename() -> String {
        return URL(string: self)?.deletingPathExtension().lastPathComponent ?? self
    }
}
