//
//  File.swift
//
//
//  Created by skytoup on 2021/6/25.
//

import CommonCrypto
import Foundation

/// RFC4122 compliant uuid5
///
/// - <https://github.com/python/cpython/blob/main/Lib/uuid.py>
/// - <https://gist.github.com/eliburke/1a55ed616bb15a7f908b>
extension UUID {
    enum UUIDNamespace: String {
        case DNS = "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
        case URL = "6ba7b811-9dad-11d1-80b4-00c04fd430c8"
        case OID = "6ba7b812-9dad-11d1-80b4-00c04fd430c8"
        case X500 = "6ba7b814-9dad-11d1-80b4-00c04fd430c8"
        
        var toUUID: UUID { UUID(uuidString: rawValue)! }
    }

    static func uuid5(namespace: UUIDNamespace, input: String) -> UUID {
        let uuidLen = MemoryLayout<uuid_t>.size
        var uuidBytes = namespace.toUUID.uuid
        let inputData = input.data(using: .utf8) ?? Data()
        
        var hashData = Data(bytes: &uuidBytes, count: uuidLen)
        hashData.append(inputData)
        
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        
        _ = hashData.withUnsafeBytes {
            CC_SHA1($0.baseAddress, CC_LONG(hashData.count), &digest)
        }
        
        memcpy(&uuidBytes, &digest, uuidLen)
        
        // this is uuid5, so always set the version to 5
        uuidBytes.6 = (uuidBytes.6 & 0x0F) | 0x50
        
        // https://www.ietf.org/rfc/rfc4122.txt
        // we want a RFC4122 hash, so the leftmost bits should be 10xxxxxx
        // to achieve that, first AND with 00111111, then OR with 10000000
        uuidBytes.8 = (uuidBytes.8 & 0x3F) | 0x80
        
        return UUID(uuid: uuidBytes)
    }
}
