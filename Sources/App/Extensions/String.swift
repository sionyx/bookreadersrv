//
//  String.swift
//  bookreadersrv
//
//  Created by sionyx on 10.01.2026.
//

import Vapor
import struct Foundation.UUID

extension String {
    func sha1() -> String? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        // Use Vapor's Crypto or CryptoKit directly
        let digest = Insecure.SHA1.hash(data: data)

        // Convert the digest to a hexadecimal string representation
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    func toUUID() -> UUID? {
        return Foundation.UUID(uuidString: self)
    }
    
    func nilIfEmpty() -> String? {
        return self.isEmpty ? nil : self
    }
    
    func int() -> Int? {
        return Int(self)
    }
}
