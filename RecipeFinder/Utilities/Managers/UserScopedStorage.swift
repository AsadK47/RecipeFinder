import Foundation

/// Manages user-scoped storage to ensure data isolation between different user accounts
final class UserScopedStorage {
    nonisolated(unsafe) static let shared = UserScopedStorage()
    
    private let userDefaults = UserDefaults.standard
    private let currentUserKey = "currentUserId"
    
    private init() {}
    
    /// Get the current user ID
    var currentUserId: String? {
        get {
            userDefaults.string(forKey: currentUserKey)
        }
        set {
            if let newValue = newValue {
                userDefaults.set(newValue, forKey: currentUserKey)
            } else {
                userDefaults.removeObject(forKey: currentUserKey)
            }
        }
    }
    
    /// Create a user-scoped key
    /// Returns a prefixed key to prevent data leaking between user accounts.
    /// When no user is logged in, uses a "no_user" prefix so writes never
    /// collide with any real user's scoped data.
    private func scopedKey(_ key: String) -> String {
        let userId = currentUserId ?? "no_user"
        return "\(userId)_\(key)"
    }
    
    // MARK: - String
    
    func string(forKey key: String) -> String? {
        userDefaults.string(forKey: scopedKey(key))
    }
    
    func set(_ value: String?, forKey key: String) {
        if let value = value {
            userDefaults.set(value, forKey: scopedKey(key))
        } else {
            userDefaults.removeObject(forKey: scopedKey(key))
        }
    }
    
    // MARK: - Data
    
    func data(forKey key: String) -> Data? {
        userDefaults.data(forKey: scopedKey(key))
    }
    
    func set(_ value: Data?, forKey key: String) {
        if let value = value {
            userDefaults.set(value, forKey: scopedKey(key))
        } else {
            userDefaults.removeObject(forKey: scopedKey(key))
        }
    }
    
    // MARK: - Bool
    
    func bool(forKey key: String) -> Bool {
        userDefaults.bool(forKey: scopedKey(key))
    }
    
    func set(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: scopedKey(key))
    }
    
    // MARK: - Integer
    
    func integer(forKey key: String) -> Int {
        userDefaults.integer(forKey: scopedKey(key))
    }
    
    func set(_ value: Int, forKey key: String) {
        userDefaults.set(value, forKey: scopedKey(key))
    }
    
    // MARK: - Double
    
    func double(forKey key: String) -> Double {
        userDefaults.double(forKey: scopedKey(key))
    }
    
    func set(_ value: Double, forKey key: String) {
        userDefaults.set(value, forKey: scopedKey(key))
    }
    
    // MARK: - Object
    
    func object(forKey key: String) -> Any? {
        userDefaults.object(forKey: scopedKey(key))
    }
    
    func set(_ value: Any?, forKey key: String) {
        if let value = value {
            userDefaults.set(value, forKey: scopedKey(key))
        } else {
            userDefaults.removeObject(forKey: scopedKey(key))
        }
    }
    
    // MARK: - Array
    
    func array(forKey key: String) -> [Any]? {
        userDefaults.array(forKey: scopedKey(key))
    }
    
    // MARK: - Remove
    
    func removeObject(forKey key: String) {
        userDefaults.removeObject(forKey: scopedKey(key))
    }
    
    // MARK: - Clear User Data
    
    /// Clear all data for the current user
    func clearCurrentUserData() {
        guard let userId = currentUserId else { return }
        
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let userKeys = allKeys.filter { $0.hasPrefix("\(userId)_") }
        
        for key in userKeys {
            userDefaults.removeObject(forKey: key)
        }
    }
}
