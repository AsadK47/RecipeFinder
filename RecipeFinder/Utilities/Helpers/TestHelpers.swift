
import Foundation

private let logger = AppLogger.logger(category: "TestHelpers")

#if DEBUG

struct AuthTestHelper {
    
    static let testEmail = "test@email.com"
    static let testPassword = "Password123!"
    
    static func ensureTestAccountExists() {
        let credentialManager = SecureCredentialManager.shared
        
        if credentialManager.getUserInfo(email: testEmail) == nil {
            let success = credentialManager.saveCredentials(
                email: testEmail,
                password: testPassword,
                fullName: "Test User"
            )
            
            if success {
                logger.debug("✅ Test account created: \(testEmail) / \(testPassword)")
            } else {
                logger.error("❌ Failed to create test account")
            }
        } else {
            logger.debug("ℹ️ Test account already exists: \(testEmail)")
        }
    }
    
    @MainActor
    static func clearAllAuthData() {
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "userData")
        UserDefaults.standard.removeObject(forKey: "currentUserEmail")
        UserDefaults.standard.removeObject(forKey: "lastActiveTimestamp")
        UserDefaults.standard.removeObject(forKey: "biometricsEnabled")
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "hasSeenBiometricOnboarding")
        UserDefaults.standard.removeObject(forKey: "appleUserCache")
        
        SecureCredentialManager.shared.deleteAllCredentials()
        
        AuthenticationManager.shared.signOut()
        
        logger.debug("🧹 All authentication data cleared (UserDefaults + Keychain)")
    }
    
    static func deleteUser(email: String) {
        SecureCredentialManager.shared.deleteCredentials(email: email)
        logger.debug("🗑️ Deleted user: \(email)")
    }
}

#endif
