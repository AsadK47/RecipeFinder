//
//  TestHelpers.swift
//  RecipeFinder
//
//  Debug-only helpers for testing authentication
//

import Foundation

#if DEBUG

/// Test Helper for Authentication Testing
struct AuthTestHelper {
    
    // MARK: - Test Credentials
    
    static let testEmail = "test@email.com"
    static let testPassword = "Password123!"
    
    // MARK: - Auto-Create Test Account
    
    /// Ensures the test account exists in Keychain (call on app launch in DEBUG)
    static func ensureTestAccountExists() {
        let credentialManager = SecureCredentialManager.shared
        
        // Only create if it doesn't already exist
        if credentialManager.getUserInfo(email: testEmail) == nil {
            let success = credentialManager.saveCredentials(
                email: testEmail,
                password: testPassword,
                fullName: "Test User"
            )
            
            if success {
                debugLog("✅ Test account created: \(testEmail) / \(testPassword)")
            } else {
                debugLog("❌ Failed to create test account")
            }
        } else {
            debugLog("ℹ️ Test account already exists: \(testEmail)")
        }
    }
    
    // MARK: - Clear All Auth Data
    
    /// Clear all authentication data for clean testing
    @MainActor
    static func clearAllAuthData() {
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "userData")
        UserDefaults.standard.removeObject(forKey: "currentUserEmail")
        UserDefaults.standard.removeObject(forKey: "lastActiveTimestamp")
        UserDefaults.standard.removeObject(forKey: "biometricsEnabled")
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "hasSeenBiometricOnboarding")
        UserDefaults.standard.removeObject(forKey: "appleUserCache")
        
        // Clear Keychain credentials
        SecureCredentialManager.shared.deleteAllCredentials()
        
        // Sign out
        AuthenticationManager.shared.signOut()
        
        debugLog("🧹 All authentication data cleared (UserDefaults + Keychain)")
    }
    
    /// Delete a specific user from Keychain
    static func deleteUser(email: String) {
        SecureCredentialManager.shared.deleteCredentials(email: email)
        debugLog("🗑️ Deleted user: \(email)")
    }
}

#endif
