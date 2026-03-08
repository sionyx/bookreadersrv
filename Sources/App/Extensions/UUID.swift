//
//  UUID.swift
//  bookreadersrv
//
//  Created by sionyx on 02.01.2026.
//

import struct Foundation.UUID

extension UUID {
    static let empty: UUID = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
}
