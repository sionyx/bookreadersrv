@testable import App
import Foundation
import Testing
import XCTVapor

@Suite("Chapter ordering")
struct ChapterOrderingTests {
    private func makeBook() -> Book {
        let book = Book(
            id: UUID(), userID: UUID(), authorID: UUID(), sectionID: UUID(),
            title: "Book", previewUrl: "", coverUrl: "", textLink: "",
            description: "", publishDate: Date(), template: ""
        )
        book.$roles.value = []
        book.$user.value = User(id: book.$user.id, login: "publisher", pass: "")
        book.$section.value = Section(
            id: book.$section.id, name: "section", title: "Section", coverUrl: nil,
            textLink: nil, description: nil, template: nil, bookTemplate: nil
        )
        return book
    }

    @Test("Book and detail responses order chapters by creation date with stable UUID ties")
    func ordering() throws {
        let book = makeBook()
        let bookID = try book.requireID()
        let early = Chapter(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            bookID: bookID, title: "Early", mediaUrl: "early.mp3",
            createDate: Date(timeIntervalSince1970: 100)
        )
        let tiedFirst = Chapter(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            bookID: bookID, title: "Tied first", mediaUrl: "first.mp3",
            createDate: Date(timeIntervalSince1970: 200)
        )
        let tiedSecond = Chapter(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            bookID: bookID, title: "Tied second", mediaUrl: "second.mp3",
            createDate: Date(timeIntervalSince1970: 200)
        )
        let expectedIDs = [early.id, tiedFirst.id, tiedSecond.id]
        let permutations = [
            [tiedSecond, tiedFirst, early], [tiedFirst, early, tiedSecond],
            [early, tiedSecond, tiedFirst], [tiedSecond, early, tiedFirst],
            [tiedFirst, tiedSecond, early], [early, tiedFirst, tiedSecond]
        ]
        for chapters in permutations {
            book.$chapters.value = chapters
            let response = try #require(book.toDTO().chapters)
            let details = book.toDetailsDTO().chapters
            #expect(response.map(\.id) == expectedIDs)
            #expect(details.map(\.id) == expectedIDs)
            #expect(response.map(\.index) == [0, 1, 2])
            #expect(details.map(\.index) == [0, 1, 2])
        }
    }

    @Test("HTTP responses retain subsecond chapter order even though ISO dates omit fractions")
    func httpCreationDate() async throws {
        let book = makeBook()
        let bookID = try book.requireID()
        let early = Chapter(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            bookID: bookID, title: "Early", mediaUrl: "early.mp3",
            createDate: Date(timeIntervalSince1970: 100.1)
        )
        let later = Chapter(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            bookID: bookID, title: "Later", mediaUrl: "later.mp3",
            createDate: Date(timeIntervalSince1970: 100.2)
        )
        book.$chapters.value = [later, early]
        let app = try await Application.make(.testing)
        do {
            app.get("book") { _ in book.toDTO() }
            try await app.test(.GET, "book", afterResponse: { response async throws in
                #expect(response.status == .ok)
                let object = try #require(JSONSerialization.jsonObject(with: Data(response.body.readableBytesView)) as? [String: Any])
                let chapters = try #require(object["chapters"] as? [[String: Any]])
                #expect(chapters.compactMap { $0["title"] as? String } == ["Early", "Later"])
                #expect(chapters.compactMap { $0["index"] as? Int } == [0, 1])
                #expect(chapters.compactMap { $0["createDate"] as? String } == ["1970-01-01T00:01:40Z", "1970-01-01T00:01:40Z"])
            })
        } catch {
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }

    @Test("Chapter updates preserve the server creation date even if a client sends another date")
    func immutableCreationDate() throws {
        let original = Date(timeIntervalSince1970: 100)
        let chapter = Chapter(bookID: UUID(), title: "Old", mediaUrl: "old.mp3", createDate: original)
        let json = Data(#"{"title":"Updated","mediaUrl":"new.mp3","createDate":999}"#.utf8)
        let update = try JSONDecoder().decode(ChapterDTO.self, from: json)
        chapter.update(with: update)
        #expect(chapter.title == "Updated")
        #expect(chapter.createDate == original)
        #expect(update.toModel().createDate == nil)

        let data = try JSONEncoder().encode(chapter.toDTO(0))
        let response = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(response["createDate"] as? Double == original.timeIntervalSinceReferenceDate)
        #expect(try JSONDecoder().decode(ChapterDTO.self, from: data).createDate == original)
    }
}
