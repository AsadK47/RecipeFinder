
import Foundation
import Security
import CryptoKit

private let logger = AppLogger.logger(category: "SecureCredential")

final class SecureCredentialManager: Sendable {
    static let shared = SecureCredentialManager()

    private let keychain: KeychainStore
    private let hasher: PasswordHasher

    init(keychain: KeychainStore = SystemKeychainStore(),
         hasher: PasswordHasher = PasswordHasher()) {
        self.keychain = keychain
        self.hasher = hasher
    }

    func hashEmail(_ email: String) -> String {
        let data = Data(email.lowercased().utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.hexEncodedString
    }
    
    @discardableResult
    func saveCredentials(email: String, password: String, fullName: String) -> Bool {
        let salt = hasher.generateSalt()

        guard let hashedPassword = hasher.hash(password: password, salt: salt) else {
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
        
        _ = keychain.delete(query)

        let status = keychain.add(query)
        return status == errSecSuccess
    }

    func verifyCredentials(email: String, password: String) -> Bool {
        let hashedEmail = hashEmail(email)

        guard let stored = retrieveCredentials(hashedEmail: hashedEmail),
              let storedHash = stored["hashedPassword"] as? String,
              let salt = stored["salt"] as? String else {
            return false
        }

        guard let hashedPassword = hasher.hash(password: password, salt: salt) else {
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

        let (status, data) = keychain.copyMatching(query)

        guard status == errSecSuccess,
              let data,
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

        let status = keychain.delete(query)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    @discardableResult
    func deleteAllCredentials() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.recipefinder.credentials"
        ]

        let status = keychain.delete(query)
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

        _ = keychain.delete(query)

        let status = keychain.add(query)
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

        let (status, data) = keychain.copyMatching(query)

        guard status == errSecSuccess,
              let data,
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

        let status = keychain.delete(query)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

