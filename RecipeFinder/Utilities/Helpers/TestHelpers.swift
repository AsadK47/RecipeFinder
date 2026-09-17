
import Foundation

#if DEBUG

private let logger = AppLogger.logger(category: "TestHelpers")

struct AuthTestHelper {
    
    static let testEmail = "test@email.com"
    static let testPassword = "Password123!"
    
    static func ensureTestAccountExists() {
        let credentialManager = SecureCredentialManager.shared

        // Keep debug login deterministic: always ensure known credentials work.
        let hasAccount = credentialManager.getUserInfo(email: testEmail) != nil
        let hasExpectedPassword = credentialManager.verifyCredentials(email: testEmail, password: testPassword)

        if hasAccount && hasExpectedPassword {
            logger.debug("ℹ️ Test account already valid: \(testEmail)")
            return
        }

        if hasAccount {
            _ = credentialManager.deleteCredentials(email: testEmail)
            logger.debug("♻️ Recreated stale test account credentials for: \(testEmail)")
        }

        let success = credentialManager.saveCredentials(
            email: testEmail,
            password: testPassword,
            fullName: "Test User"
        )

        if success {
            logger.debug("✅ Test account ready: \(testEmail) / \(testPassword)")
        } else {
            logger.error("❌ Failed to create test account")
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
        UserDefaults.standard.removeObject(forKey: "guestModeEnabled")
        UserDefaults.standard.removeObject(forKey: "hasEverAuthenticated")

        SecureCredentialManager.shared.deleteAllCredentials()
        
        AuthenticationManager.shared.signOut()
        
        logger.debug("🧹 All authentication data cleared (UserDefaults + Keychain)")
    }
    
    static func deleteUser(email: String) {
        SecureCredentialManager.shared.deleteCredentials(email: email)
        logger.debug("🗑️ Deleted user: \(email)")
    }

    /// Synchronous sign-in for the app's `-skip-auth` init path: sets
    /// `isAuthenticated = true` before the first SwiftUI frame renders so UI
    /// tests never race against the async `autoSignIn` Task.
    @MainActor
    static func autoSignInSync() {
        do {
            try AuthenticationManager.shared.signInSyncForUITesting(
                email: testEmail, password: testPassword
            )
            logger.debug("✅ Debug sync auto-sign-in complete for: \(testEmail)")
        } catch {
            logger.error("❌ Debug sync auto-sign-in failed: \(error)")
        }
    }
}

#endif
