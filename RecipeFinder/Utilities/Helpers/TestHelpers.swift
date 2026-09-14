
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

        SecureCredentialManager.shared.deleteAllCredentials()
        
        AuthenticationManager.shared.signOut()
        
        logger.debug("🧹 All authentication data cleared (UserDefaults + Keychain)")
    }
    
    static func deleteUser(email: String) {
        SecureCredentialManager.shared.deleteCredentials(email: email)
        logger.debug("🗑️ Deleted user: \(email)")
    }

    /// Silently signs in with the test account. Called when the `-skip-auth`
    /// launch argument is present so the dev always lands on the main content
    /// without touching the sign-in screen.
    static func autoSignIn() {
        Task { @MainActor in
            do {
                try await AuthenticationManager.shared.signIn(email: testEmail, password: testPassword)
                logger.debug("✅ Debug auto-sign-in complete for: \(testEmail)")
            } catch {
                logger.error("❌ Debug auto-sign-in failed: \(error)")
            }
        }
    }
}

#endif
