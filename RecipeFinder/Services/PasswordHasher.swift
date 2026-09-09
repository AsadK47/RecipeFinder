import Foundation
import Security
import CommonCrypto

/// Pure, dependency-free password hashing (PBKDF2 / HMAC-SHA256) and salt
/// generation.
///
/// Kept separate from Keychain storage so the cryptographic behaviour can be
/// unit-tested in isolation — historically this logic shipped a bug where a
/// failed derivation was mistaken for a valid (empty) hash.
struct PasswordHasher: Sendable {
    /// PBKDF2 iteration count. Configurable so tests can run with fewer rounds;
    /// production uses an OWASP-scale default.
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

    /// Derives a hex-encoded hash for `password` using the hex-encoded `salt`.
    ///
    /// Returns `nil` when the salt is not valid hex or the derivation fails —
    /// never an empty string, which must not be treated as a valid hash.
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

    /// Returns `nil` (never partial/empty `Data`) when derivation fails, so a
    /// failed hash cannot be mistaken for a valid value.
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
    /// Decodes an even-length hex string into bytes. Returns `nil` for odd-length
    /// input or any non-hex character.
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
