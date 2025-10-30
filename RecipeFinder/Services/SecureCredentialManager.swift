//  Secure credential storage using iOS Keychain and password hashing

import Foundation
import Security
import CryptoKit

/// Manages secure storage of user credentials using iOS Keychain
/// Never stores passwords in plain text - uses SHA256 hashing
class SecureCredentialManager {
    static let shared = SecureCredentialManager()
    
    private init() {}
    
    // MARK: - Password Hashing
    
    /// Hash a password using SHA256
    /// - Parameter password: Plain text password
    /// - Returns: Hashed password as hex string
    func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
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
    ///   - password: User's password (will be hashed for storage)
    ///   - fullName: User's full name (stored in plain text)
    /// - Returns: Success status
    @discardableResult
    func saveCredentials(email: String, password: String, fullName: String) -> Bool {
        // Hash the password before storage
        let hashedPassword = hashPassword(password)
        let hashedEmail = hashEmail(email)
        
        // Store hashed credentials
        let credentials: [String: Any] = [
            "email": email, // Store original for display/autofill
            "hashedEmail": hashedEmail,
            "hashedPassword": hashedPassword,
            "fullName": fullName,
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
        let hashedPassword = hashPassword(password)
        
        guard let stored = retrieveCredentials(hashedEmail: hashedEmail) else {
            return false
        }
        
        return stored["hashedPassword"] as? String == hashedPassword
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

