import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    print("DATABASE_NAME: \(Environment.get("DATABASE_NAME") ?? "[unknown]")")

    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)
    
    
    app.migrations.add(CreateSection())
    app.migrations.add(CreateAuthor())
    app.migrations.add(CreateBook())
    app.migrations.add(UpdateBook1())
    app.migrations.add(UpdateSection1())

    app.views.use(.leaf)
    
    app.routes.defaultMaxBodySize = "512kb"

    // register routes
    try routes(app)
}
