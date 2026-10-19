//
//  ChapterDTO.swift
//  bookreadersrv
//
//  Created by sionyx on 12.01.2026.
//

import Fluent
import Vapor

struct ChapterDTO: Content {
    var id: UUID?
    var createDate: Date?
    var updateDate: Date?
    var deleteDate: Date?
    var bookId: Book.IDValue?
    var title: String
    var mediaUrl: String
    var duration: Int32?
    var coverUrl: String?
    var previewUrl: String?
    var publishDate: TimeInterval?
    var link: String?
    var description: String?
    var index: Int?
    
    func toModel(bookId: UUID = UUID.empty) -> Chapter {
        let model = Chapter(id: self.id,
                            bookID: self.bookId ?? bookId,
                            title: self.title,
                            coverUrl: self.coverUrl,
                            previewUrl: self.previewUrl,
                            mediaUrl: self.mediaUrl,
                            duration: self.duration,
                            link: self.link,
                            description: self.description,
                            publishDate: Date(timeIntervalSince1970: self.publishDate ?? 0))
        return model
    }
}
    
extension Chapter {
    func toDTO(_ index: Int) -> ChapterDTO {
        return ChapterDTO(id: self.$id.value,
                          createDate: self.createDate,
                          bookId: self.$book.id,
                          title: self.title,
                          mediaUrl: self.mediaUrl,
                          duration: self.duration,
                          coverUrl: self.coverUrl,
                          previewUrl: self.previewUrl,
                          publishDate: self.publishDate?.timeIntervalSince1970,
                          link: self.link,
                          description: self.description,
                          index: index)
    }
    
    func update(with dto: ChapterDTO) {
        self.title = dto.title
        self.mediaUrl = dto.mediaUrl
        if let duration = dto.duration {
            self.duration = duration
        }
        if let coverUrl = dto.coverUrl {
            self.coverUrl = coverUrl
        }
        if let previewUrl = dto.previewUrl {
            self.previewUrl = previewUrl
        }
        if let publishDate = dto.publishDate {
            self.publishDate = Date(timeIntervalSince1970: publishDate)
        }
        if let link = dto.link {
            self.link = link
        }
        if let description = dto.description {
            self.description = description
        }
    }
}


