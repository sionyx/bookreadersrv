@testable import App
import Foundation
import Testing

@Suite("Chapter duration")
struct ChapterDurationTests {
    private func decode(_ duration: String = "") throws -> ChapterDTO {
        let json = """
        {"title":"Chapter","mediaUrl":"https://example.com/chapter.mp3"\(duration)}
        """
        return try JSONDecoder().decode(ChapterDTO.self, from: Data(json.utf8))
    }

    @Test("Creating a chapter accepts missing, null, zero and known durations")
    func create() throws {
        let bookID = UUID()
        for (input, expected): (String, Int32?) in [
            ("", nil), (",\"duration\":null", nil),
            (",\"duration\":0", 0), (",\"duration\":1234", 1234)
        ] {
            let chapter = try decode(input).toModel(bookId: bookID)
            #expect(chapter.duration == expected)
            #expect(chapter.$book.id == bookID)
            #expect(chapter.toDTO(0).duration == expected)
        }
    }

    @Test("Updating a chapter preserves duration when absent or null and accepts zero")
    func update() throws {
        let chapter = Chapter(bookID: UUID(), title: "Old", mediaUrl: "old.mp3", duration: 1234)
        chapter.update(with: try decode())
        #expect(chapter.duration == 1234)
        chapter.update(with: try decode(",\"duration\":null"))
        #expect(chapter.duration == 1234)
        chapter.update(with: try decode(",\"duration\":42"))
        #expect(chapter.duration == 42)
        chapter.update(with: try decode(",\"duration\":0"))
        #expect(chapter.duration == 0)
    }

    @Test("Legacy chapters omit unknown duration and decode it as nil")
    func unknownDurationResponse() throws {
        let chapter = Chapter(bookID: UUID(), title: "Legacy", mediaUrl: "legacy.mp3")
        let data = try JSONEncoder().encode(chapter.toDTO(0))
        let response = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(response["duration"] == nil)
        #expect(try JSONDecoder().decode(ChapterDTO.self, from: data).duration == nil)
    }

    @Test("Known duration is serialized as a JSON integer")
    func knownDurationResponse() throws {
        let data = try JSONEncoder().encode(decode(",\"duration\":1234"))
        let response = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(response["duration"] as? Int == 1234)
    }

    @Test("Book responses used by the website include duration for every chapter")
    func bookResponse() throws {
        let bookID = UUID()
        let book = Book(
            id: bookID, userID: UUID(), authorID: UUID(), sectionID: UUID(),
            title: "Book", previewUrl: "", coverUrl: "", textLink: "",
            description: "", publishDate: Date(), template: ""
        )
        book.$roles.value = []
        book.$chapters.value = [
            Chapter(bookID: bookID, title: "Known", mediaUrl: "known.mp3", duration: 1234),
            Chapter(bookID: bookID, title: "Unknown", mediaUrl: "unknown.mp3")
        ]

        // GET /api/books/{bookID} returns this DTO, including its nested chapters.
        let data = try JSONEncoder().encode(book.toDTO())
        let response = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let chapters = try #require(response["chapters"] as? [[String: Any]])
        #expect(chapters.count == 2)
        #expect(chapters.first?["duration"] as? Int == 1234)
        #expect(chapters.last?["duration"] == nil)

        let decoded = try JSONDecoder().decode(BookDTO.self, from: data)
        #expect(decoded.chapters?.first?.duration == 1234)
        #expect(decoded.chapters?.last?.duration == nil)
    }
}
