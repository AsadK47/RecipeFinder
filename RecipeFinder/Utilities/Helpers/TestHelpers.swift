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
    
    static let testEmail = "test@recipe.app"
    static let testPassword = "Test123!"
    
    // MARK: - Clear All Auth Data
    
    /// Clear all authentication data for clean testing
    static func clearAllAuthData() {
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "userData")
        UserDefaults.standard.removeObject(forKey: "guestMode")
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
