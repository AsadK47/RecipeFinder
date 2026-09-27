import Foundation
import Security
import CommonCrypto

/// Pure PBKDF2/HMAC-SHA256 password hashing and salt generation, kept separate from Keychain storage for isolated unit-testing (a failed derivation once passed as a valid empty hash).
struct PasswordHasher: Sendable {
    /// PBKDF2 iteration count; configurable so tests use fewer rounds than the OWASP-scale production default.
    let rounds: Int
    /// Derived-key length in bytes.
    let keyByteCount: Int

    init(rounds: Int = 100_000, keyByteCount: Int = 32) {
        self.rounds = rounds
        self.keyByteCount = keyByteCount
    }

    /// A cryptographically random 32-byte salt, hex-encoded.
    func generateSalt() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.hexEncodedString
    }

    /// Derives a hex hash for `password` using hex `salt`; returns `nil` (never an empty string) on invalid hex or failed derivation.
    func hash(password: String, salt: String) -> String? {
        guard let passwordData = password.data(using: .utf8),
              let saltData = Data(hexString: salt) else {
            return nil
        }

        guard let derivedKey = pbkdf2(password: passwordData, salt: saltData) else {
            return nil
        }

        return derivedKey.hexEncodedString
    }

    /// Returns `nil` (never partial/empty `Data`) on failure so a failed hash can't be mistaken for a valid value.
    private func pbkdf2(password: Data, salt: Data) -> Data? {
        var derivedKeyData = Data(count: keyByteCount)
        let derivationStatus = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            let derivedKeyRawBytes = derivedKeyBytes.bindMemory(to: UInt8.self).baseAddress
            return salt.withUnsafeBytes { saltBytes in
                let saltRawBytes = saltBytes.bindMemory(to: UInt8.self).baseAddress
                return password.withUnsafeBytes { passwordBytes in
                    let passwordRawBytes = passwordBytes.bindMemory(to: Int8.self).baseAddress
                    return CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordRawBytes,
                        password.count,
                        saltRawBytes,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(rounds),
                        derivedKeyRawBytes,
                        keyByteCount
                    )
                }
            }
        }

        return derivationStatus == kCCSuccess ? derivedKeyData : nil
    }
}

extension Sequence where Element == UInt8 {
    /// Lowercase hex encoding of the byte sequence.
    var hexEncodedString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

extension Data {
    /// Decodes an even-length hex string into bytes; `nil` for odd-length input or any non-hex character.
    init?(hexString: String) {
        let len = hexString.count / 2
        guard hexString.count == len * 2 else { return nil }
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hexString.index(hexString.startIndex, offsetBy: i * 2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
}
