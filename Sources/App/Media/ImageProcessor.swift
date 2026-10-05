import Foundation
import Vapor
#if canImport(ImageIO) && !MEDIA_USE_IMAGEMAGICK
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers
#endif

struct ImageProcessor {
    /// Runs on the application's blocking thread pool, never on an event loop.
    static func process(source: URL, directory: URL) throws -> (URL, URL) {
        let base = directory.appendingPathComponent("image.png")
        let mini = directory.appendingPathComponent("image_mini.jpg")
        #if canImport(ImageIO) && !MEDIA_USE_IMAGEMAGICK
        guard let input = CGImageSourceCreateWithURL(source as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(input, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0, width <= 20_000, height <= 20_000,
              Int64(width) * Int64(height) <= 100_000_000 else {
            throw Abort(.unprocessableEntity, reason: "Invalid image or image exceeds 100 megapixels / 20000 pixels per side")
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: min(1024, max(width, height)),
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(input, 0, options as CFDictionary) else {
            throw Abort(.unprocessableEntity, reason: "Cannot decode image")
        }
        try write(image, to: base, type: UTType.png.identifier, options: [:])
        let side = min(image.width, image.height)
        guard let cropped = image.cropping(to: CGRect(x: (image.width - side) / 2,
                                                      y: (image.height - side) / 2, width: side, height: side)),
              let context = CGContext(data: nil, width: 96, height: 96, bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
            throw Abort(.unprocessableEntity, reason: "Cannot create image preview")
        }
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 96, height: 96))
        context.interpolationQuality = .high
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: 96, height: 96))
        guard let thumbnail = context.makeImage() else {
            throw Abort(.unprocessableEntity, reason: "Cannot create image preview")
        }
        try write(thumbnail, to: mini, type: UTType.jpeg.identifier,
                  options: [kCGImageDestinationLossyCompressionQuality: 0.8])
        #else
        let executable = Environment.get("MEDIA_IMAGE_CONVERTER") ?? "/usr/bin/convert"
        // Explicit decoder selected from the signature; no filename/pseudo-protocol input from clients.
        let prefix = try imageFormat(source)
        let input = "\(prefix):\(source.path)[0]"
        let dimensions = try convert(executable, arguments: ["-limit", "time", "60", "-ping", input,
                                                              "-format", "%w %h", "info:"], capture: true)
            .split(separator: " ").compactMap { Int($0) }
        guard dimensions.count == 2, dimensions[0] > 0, dimensions[1] > 0,
              dimensions[0] <= 20_000, dimensions[1] <= 20_000,
              Int64(dimensions[0]) * Int64(dimensions[1]) <= 100_000_000 else {
            throw Abort(.unprocessableEntity, reason: "Image exceeds 100 megapixels / 20000 pixels per side")
        }
        try convert(executable, arguments: ["-limit", "memory", "128MiB", "-limit", "map", "256MiB",
                                            "-limit", "disk", "512MiB", "-limit", "time", "60",
                                            input, "-auto-orient", "-resize", "1024x1024>", "-strip", "PNG:\(base.path)"])
        try convert(executable, arguments: ["PNG:\(base.path)", "-resize", "96x96^", "-gravity", "center", "-extent", "96x96", "-background", "white", "-alpha", "remove",
                                            "-alpha", "off", "-strip", "-quality", "80", "JPEG:\(mini.path)"])
        #endif
        return (base, mini)
    }

    static func imageFormat(_ url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let bytes = [UInt8](try handle.read(upToCount: 12) ?? Data())
        if bytes.starts(with: [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]) { return "PNG" }
        if bytes.starts(with: [0xff, 0xd8, 0xff]) { return "JPEG" }
        if bytes.count >= 12, String(bytes: bytes[0..<4], encoding: .ascii) == "RIFF",
           String(bytes: bytes[8..<12], encoding: .ascii) == "WEBP" { return "WEBP" }
        throw Abort(.unsupportedMediaType, reason: "Only JPEG, PNG and WebP images are supported")
    }

    #if canImport(ImageIO) && !MEDIA_USE_IMAGEMAGICK
    private static func write(_ image: CGImage, to url: URL, type: String, options: [CFString: Any]) throws {
        guard let output = CGImageDestinationCreateWithURL(url as CFURL, type as CFString, 1, nil) else {
            throw Abort(.internalServerError, reason: "Cannot create image file")
        }
        CGImageDestinationAddImage(output, image, options as CFDictionary)
        guard CGImageDestinationFinalize(output) else {
            throw Abort(.internalServerError, reason: "Cannot write image file")
        }
    }
    #else
    @discardableResult
    private static func convert(_ executable: String, arguments: [String], capture: Bool = false) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = capture ? output : FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch {
            throw Abort(.serviceUnavailable, reason: "ImageMagick is not available; configure MEDIA_IMAGE_CONVERTER")
        }
        let result = capture ? output.fileHandleForReading.readDataToEndOfFile() : Data()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw Abort(.unprocessableEntity, reason: "Image cannot be decoded or exceeds processing limits")
        }
        return String(decoding: result, as: UTF8.self)
    }
    #endif
}
