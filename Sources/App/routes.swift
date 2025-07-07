import Fluent
import Vapor

func routes(_ app: Application) throws {

    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    app.middleware.use(cors, at: .beginning)
    
    try app.group("app") { app in
        try app.register(collection: AppSectionController())
    }
    
    try app.group("api") { api in
        try api.register(collection: SectionController())
        try api.register(collection: AuthorController())
        try api.register(collection: BookController())
        try api.register(collection: ViewsController(path: "views", localDirectory: app.directory.viewsDirectory))
    }

}
