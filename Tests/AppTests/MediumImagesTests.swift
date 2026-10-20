@testable import App
import Foundation
import Testing

@Suite("Medium images")
struct MediumImagesTests {
    private let medium = "https://media.example/medium.webp"

    private func json<T: Encodable>(_ value: T) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as? [String: Any])
    }

    @Test("All entity responses use medium_url and retain legacy image fields")
    func serialization() throws {
        let author = Author(firstName: "A", lastName: "B", photoUrl: "original.png")
        author.mediumUrl = medium
        let user = User(login: "publisher", pass: "", photoUrl: "original.png")
        user.mediumUrl = medium
        let section = Section(name: "s", title: "S", coverUrl: "original.png", textLink: nil,
                              description: nil, template: nil, bookTemplate: nil)
        section.mediumUrl = medium
        let chapter = Chapter(bookID: UUID(), title: "C", coverUrl: "original.png", mediaUrl: "audio.mp3")
        chapter.mediumUrl = medium
        let book = Book(userID: UUID(), authorID: UUID(), sectionID: UUID(), title: "B",
                        previewUrl: "preview.jpg", coverUrl: "original.png", textLink: "",
                        description: "", publishDate: Date(), template: "")
        book.mediumUrl = medium
        book.$user.value = user
        book.$section.value = section
        book.$roles.value = []
        book.$chapters.value = [chapter]
        let responses = try [json(author.toDTO()), json(user.toDTO()), json(section.toDTO()),
                             json(chapter.toDTO(0)), json(book.toDTO()), json(book.toShortDTO()),
                             json(book.toDetailsDTO())]
        for response in responses {
            #expect(response["medium_url"] as? String == medium)
            #expect(response["mediumUrl"] == nil)
        }
        #expect(try json(book.toDTO())["coverUrl"] as? String == "original.png")
        #expect(try json(book.toDTO())["previewUrl"] as? String == "preview.jpg")
    }

    @Test("Legacy clients may omit medium_url and chapter updates preserve it")
    func compatibility() throws {
        let dto = try JSONDecoder().decode(ChapterDTO.self, from: Data(#"{"title":"C","mediaUrl":"audio.mp3"}"#.utf8))
        #expect(dto.toModel().mediumUrl == nil)
        let chapter = dto.toModel()
        chapter.mediumUrl = medium
        chapter.update(with: dto)
        #expect(chapter.mediumUrl == medium)
        let withMedium = try JSONDecoder().decode(ChapterDTO.self, from: Data(#"{"title":"C","mediaUrl":"audio.mp3","medium_url":"new.webp"}"#.utf8))
        chapter.update(with: withMedium)
        #expect(chapter.mediumUrl == "new.webp")
    }

    @Test("Image deletion includes medium; audio operations remain independent")
    func deletionTargets() throws {
        let chapter = Chapter(bookID: UUID(), title: "C", coverUrl: "original.png",
                              previewUrl: "preview.jpg", mediaUrl: "audio.mp3")
        chapter.mediumUrl = medium
        #expect(Set(MediaTarget.chapter(chapter, "", false).urls) == ["original.png", "preview.jpg", medium])
        #expect(MediaTarget.chapter(chapter, "", true).urls == ["audio.mp3"])
        #expect(try json(MediaResponse(success: true, url: "audio.mp3", previewUrl: nil))["medium_url"] == nil)
        #expect(try json(MediaResponse(success: true, url: nil, previewUrl: nil))["medium_url"] == nil)
    }
}
