
import Foundation
import Security
import CryptoKit
import CommonCrypto

private let logger = AppLogger.logger(category: "SecureCredential")

final class SecureCredentialManager: Sendable {
    static let shared = SecureCredentialManager()
    
    private init() {}
    
    private func generateSalt() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
    
    private func hashPasswordWithSalt(_ password: String, salt: String) -> String? {
        guard let passwordData = password.data(using: .utf8),
              let saltData = Data(hexString: salt) else {
            return nil
        }
        
        let derivedKey = pbkdf2(password: passwordData,
                                salt: saltData,
                                keyByteCount: 32,
                                rounds: 100_000)
        
        // A failed derivation returns empty data; never treat that as a valid hash
        guard !derivedKey.isEmpty else {
            return nil
        }
        
        return derivedKey.map { String(format: "%02x", $0) }.joined()
    }
    
    private func pbkdf2(password: Data,
                        salt: Data,
                        keyByteCount: Int,
                        rounds: Int) -> Data {
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
        
        return derivationStatus == kCCSuccess ? derivedKeyData : Data()
    }
    
    func hashEmail(_ email: String) -> String {
        let data = Data(email.lowercased().utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    @discardableResult
    func saveCredentials(email: String, password: String, fullName: String) -> Bool {
        let salt = generateSalt()
        
        guard let hashedPassword = hashPasswordWithSalt(password, salt: salt) else {
            logger.error("❌ Failed to hash password")
            return false
        }
        
        let hashedEmail = hashEmail(email)
        
        let existingUserId = getUserId(email: email)
        let stableUserId = existingUserId ?? UUID().uuidString
        
        let credentials: [String: Any] = [
            "hashedEmail": hashedEmail,
            "hashedPassword": hashedPassword,
            "salt": salt,
            "fullName": fullName,
            "userId": stableUserId,
            "createdAt": Date().timeIntervalSince1970
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: credentials) else {
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: hashedEmail,
            kSecAttrService as String: "com.recipefinder.credentials",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func verifyCredentials(email: String, password: String) -> Bool {
        let hashedEmail = hashEmail(email)
        
        guard let stored = retrieveCredentials(hashedEmail: hashedEmail),
              let storedHash = stored["hashedPassword"] as? String,
              let salt = stored["salt"] as? String else {
            return false
        }
        
        guard let hashedPassword = hashPasswordWithSalt(password, salt: salt) else {
            return false
        }
        
        return constantTimeEquals(hashedPassword, storedHash)
    }
    
    /// Compares two strings in constant time to avoid leaking match position via timing
    private func constantTimeEquals(_ lhs: String, _ rhs: String) -> Bool {
        let lhsBytes = Array(lhs.utf8)
        let rhsBytes = Array(rhs.utf8)
        
        guard lhsBytes.count == rhsBytes.count else { return false }
        
        var difference: UInt8 = 0
        for (lhsByte, rhsByte) in zip(lhsBytes, rhsBytes) {
            difference |= lhsByte ^ rhsByte
        }
        return difference == 0
    }
    
    private func retrieveCredentials(hashedEmail: String) -> [String: Any]? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: hashedEmail,
            kSecAttrService as String: "com.recipefinder.credentials",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let credentials = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        return credentials
    }
    
    func getUserInfo(email: String) -> (email: String, fullName: String)? {
        let hashedEmail = hashEmail(email)

        guard let credentials = retrieveCredentials(hashedEmail: hashedEmail),
              let fullName = credentials["fullName"] as? String else {
            return nil
        }

        return (email, fullName)
    }
    
    func getUserId(email: String) -> String? {
        let hashedEmail = hashEmail(email)
        guard let credentials = retrieveCredentials(hashedEmail: hashedEmail) else {
            return nil
        }
        return credentials["userId"] as? String
    }
    
    @discardableResult
    func deleteCredentials(email: String) -> Bool {
        let hashedEmail = hashEmail(email)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: hashedEmail,
            kSecAttrService as String: "com.recipefinder.credentials"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    @discardableResult
    func deleteAllCredentials() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.recipefinder.credentials"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    func generateSessionToken() -> String {
        return UUID().uuidString
    }
    
    @discardableResult
    func saveSessionToken(_ token: String, for email: String) -> Bool {
        let hashedEmail = hashEmail(email)
        let data = Data(token.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "\(hashedEmail).token",
            kSecAttrService as String: "com.recipefinder.session",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func getSessionToken(for email: String) -> String? {
        let hashedEmail = hashEmail(email)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "\(hashedEmail).token",
            kSecAttrService as String: "com.recipefinder.session",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    @discardableResult
    func deleteSessionToken(for email: String) -> Bool {
        let hashedEmail = hashEmail(email)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "\(hashedEmail).token",
            kSecAttrService as String: "com.recipefinder.session"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hexString.index(hexString.startIndex, offsetBy: i*2)
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

