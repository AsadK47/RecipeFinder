//  Secure credential storage using iOS Keychain and password hashing

import Foundation
import Security
import CryptoKit
import CommonCrypto

private let logger = AppLogger.logger(category: "SecureCredential")


/// Manages secure storage of user credentials using iOS Keychain
/// Uses PBKDF2 with unique salts for production-grade password security
final class SecureCredentialManager: @unchecked Sendable {
    static let shared = SecureCredentialManager()
    
    private init() {}
    
    // MARK: - Password Hashing with PBKDF2
    
    /// Generate a cryptographically secure random salt
    /// - Returns: 32-byte salt as hex string
    private func generateSalt() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Hash a password using PBKDF2 with salt
    /// - Parameters:
    ///   - password: Plain text password
    ///   - salt: Unique salt for this user
    /// - Returns: Hashed password as hex string
    private func hashPasswordWithSalt(_ password: String, salt: String) -> String? {
        guard let passwordData = password.data(using: .utf8),
              let saltData = Data(hexString: salt) else {
            return nil
        }
        
        // PBKDF2 with 100,000 iterations (OWASP recommended minimum)
        // This makes brute force attacks computationally expensive
        let derivedKey = pbkdf2(password: passwordData,
                                salt: saltData,
                                keyByteCount: 32,
                                rounds: 100_000)
        
        return derivedKey.map { String(format: "%02x", $0) }.joined()
    }
    
    /// PBKDF2 key derivation function
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
    
    /// Hash email for secure storage
    /// - Parameter email: Plain text email
    /// - Returns: Hashed email as hex string
    func hashEmail(_ email: String) -> String {
        let data = Data(email.lowercased().utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Keychain Operations
    
    /// Save credentials to Keychain
    /// - Parameters:
    ///   - email: User's email (will be hashed for storage)
    ///   - password: User's password (will be hashed with salt)
    ///   - fullName: User's full name (stored in plain text)
    /// - Returns: Success status
    @discardableResult
    func saveCredentials(email: String, password: String, fullName: String) -> Bool {
        // Generate unique salt for this user
        let salt = generateSalt()
        
        // Hash the password with salt
        guard let hashedPassword = hashPasswordWithSalt(password, salt: salt) else {
            logger.error("❌ Failed to hash password")
            return false
        }
        
        let hashedEmail = hashEmail(email)
        
        // Preserve existing userId if the account already exists, otherwise generate a new stable one
        let existingUserId = getUserId(email: email)
        let stableUserId = existingUserId ?? UUID().uuidString
        
        // Store hashed credentials with salt
        let credentials: [String: Any] = [
            "email": email, // Store original for display/autofill
            "hashedEmail": hashedEmail,
            "hashedPassword": hashedPassword,
            "salt": salt, // Store salt for verification
            "fullName": fullName,
            "userId": stableUserId, // Stable identifier tied to this account
            "createdAt": Date().timeIntervalSince1970
        ]
        
        guard let data = try? JSONSerialization.data(withJSONObject: credentials) else {
            return false
        }
        
        // Keychain query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: hashedEmail,
            kSecAttrService as String: "com.recipefinder.credentials",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete old entry if exists
        SecItemDelete(query as CFDictionary)
        
        // Add new entry
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Verify credentials against stored hash
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    /// - Returns: True if credentials match
    func verifyCredentials(email: String, password: String) -> Bool {
        let hashedEmail = hashEmail(email)
        
        guard let stored = retrieveCredentials(hashedEmail: hashedEmail),
              let storedHash = stored["hashedPassword"] as? String,
              let salt = stored["salt"] as? String else {
            return false
        }
        
        // Hash the provided password with the stored salt
        guard let hashedPassword = hashPasswordWithSalt(password, salt: salt) else {
            return false
        }
        
        // Compare hashes
        return hashedPassword == storedHash
    }
    
    /// Retrieve stored credentials
    /// - Parameter hashedEmail: Hashed email to lookup
    /// - Returns: Dictionary of stored credentials
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
    
    /// Get stored user info without password
    /// - Parameter email: User's email
    /// - Returns: User information
    func getUserInfo(email: String) -> (email: String, fullName: String)? {
        let hashedEmail = hashEmail(email)
        
        guard let credentials = retrieveCredentials(hashedEmail: hashedEmail),
              let storedEmail = credentials["email"] as? String,
              let fullName = credentials["fullName"] as? String else {
            return nil
        }
        
        return (storedEmail, fullName)
    }
    
    /// Get the stable user ID stored for this email account.
    /// Returns nil if the account doesn't exist or was created before userId storage was added.
    func getUserId(email: String) -> String? {
        let hashedEmail = hashEmail(email)
        guard let credentials = retrieveCredentials(hashedEmail: hashedEmail) else {
            return nil
        }
        return credentials["userId"] as? String
    }
    
    /// Delete stored credentials
    /// - Parameter email: User's email
    /// - Returns: Success status
    @discardableResult
    func deleteCredentials(email: String) -> Bool {
        let hashedEmail = hashEmail(email)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: hashedEmail,
            kSecAttrService as String: "com.recipefinder.credentials"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    /// Delete all stored credentials (for logout/reset)
    @discardableResult
    func deleteAllCredentials() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.recipefinder.credentials"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Token Management (for session management)
    
    /// Generate a secure session token
    /// - Returns: UUID-based session token
    func generateSessionToken() -> String {
        return UUID().uuidString
    }
    
    /// Save session token to Keychain
    /// - Parameters:
    ///   - token: Session token
    ///   - email: User's email
    /// - Returns: Success status
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
        
        // Delete old token
        SecItemDelete(query as CFDictionary)
        
        // Add new token
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieve session token
    /// - Parameter email: User's email
    /// - Returns: Session token if exists
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
    
    /// Delete session token
    /// - Parameter email: User's email
    /// - Returns: Success status
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

// MARK: - Data Extension for Hex String Conversion
extension Data {
    /// Convert hex string to Data
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

