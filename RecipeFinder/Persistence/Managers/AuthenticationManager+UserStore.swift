import Foundation
import Security

/// Keychain persistence for the current `User`, plus account deletion.
extension AuthenticationManager {

    func saveUser(_ user: User) throws {
        guard let data = try? JSONEncoder().encode(user) else {
            throw AuthError.userCreationFailed
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userDataKey,
            kSecAttrService as String: "com.recipefinder.userdata",
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        
        var addQuery = query
        addQuery[kSecValueData as String] = data
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AuthError.userCreationFailed
        }
        
        UserDefaults.standard.removeObject(forKey: userDataKey)
    }
    
    func loadUser() {
        guard let data = loadUserData(),
              let user = try? JSONDecoder().decode(User.self, from: data) else { return }
        setCurrentUser(user)
    }
    
    func loadUserData() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userDataKey,
            kSecAttrService as String: "com.recipefinder.userdata",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data {
            return data
        }
        
        guard let legacyData = UserDefaults.standard.data(forKey: userDataKey) else {
            return nil
        }
        
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userDataKey,
            kSecAttrService as String: "com.recipefinder.userdata",
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: legacyData
        ]
        
        if SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess {
            UserDefaults.standard.removeObject(forKey: userDataKey)
            logger.debug("✅ Migrated user data from UserDefaults to Keychain")
        }
        
        return legacyData
    }
    
    func updateCurrentUser(_ user: User) {
        setCurrentUser(user)
        try? saveUser(user)
        logger.debug("✅ Current user updated: \(user.displayName)")
    }
    
    func deleteAccount() async throws {
        let userId = currentUser?.id
        
        if let email = UserDefaults.standard.string(forKey: currentEmailKey) {
            credentialManager.deleteCredentials(email: email)
            credentialManager.deleteSessionToken(for: email)
        }
        
        let userDataQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userDataKey,
            kSecAttrService as String: "com.recipefinder.userdata"
        ]
        SecItemDelete(userDataQuery as CFDictionary)
        UserDefaults.standard.removeObject(forKey: userDataKey)
        UserDefaults.standard.removeObject(forKey: isAuthenticatedKey)
        UserDefaults.standard.removeObject(forKey: biometricsEnabledKey)
        UserDefaults.standard.removeObject(forKey: currentEmailKey)
        UserDefaults.standard.removeObject(forKey: lastActiveTimestampKey)
        UserDefaults.standard.removeObject(forKey: appleUserCacheKey)
        if let userId {
            UserDefaults.standard.removeObject(forKey: "user_\(userId)_initialized")
        }
        
        AccountManager.shared.clearAllData()
        
        UserScopedStorage.shared.clearCurrentUserData()
        UserScopedStorage.shared.currentUserId = nil
        
        setAuthState(isAuthenticated: false, user: nil)
        HapticManager.shared.success()
    }
}
