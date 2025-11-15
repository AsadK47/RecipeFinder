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
    
    static let testEmail = "test@recipefinder.com"
    static let testPassword = "Test!1*"
    static let testFullName = "Test User"
    
    static let adminEmail = "admin@recipefinder.com"
    static let adminPassword = "RecipeAdmin2024!"
    static let adminFullName = "Recipe Chef"
    
    // MARK: - Setup Test Users
    
    /// Create test accounts for easy testing
    /// Call this once during development to seed test accounts
     
    static func seedTestAccounts() {
        let credentialManager = SecureCredentialManager.shared
        
        // Create test user
        let testSaved = credentialManager.saveCredentials(
            email: testEmail,
            password: testPassword,
            fullName: testFullName
        )
        
        // Create admin user
        let adminSaved = credentialManager.saveCredentials(
            email: adminEmail,
            password: adminPassword,
            fullName: adminFullName
        )
        
        if testSaved && adminSaved {
            debugLog("✅ Test accounts seeded successfully!")
            debugLog("📧 Test User: \(testEmail) / \(testPassword)")
            debugLog("👨‍💼 Admin User: \(adminEmail) / \(adminPassword)")
        } else {
            debugLog("❌ Failed to seed test accounts")
        }
    }
    
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
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
        UserDefaults.standard.removeObject(forKey: "appleUserCache")
        
        // Sign out
        AuthenticationManager.shared.signOut()
        
        debugLog("🧹 All authentication data cleared")
    }
    
    // MARK: - Quick Sign In
    
    /// Quick sign in with test account
    static func quickSignInAsTest() async throws {
        try await AuthenticationManager.shared.signIn(
            email: testEmail,
            password: testPassword
        )
        debugLog("✅ Signed in as Test User")
    }
    
    /// Quick sign in with admin account
    static func quickSignInAsAdmin() async throws {
        try await AuthenticationManager.shared.signIn(
            email: adminEmail,
            password: adminPassword
        )
        debugLog("✅ Signed in as Admin User")
    }
}

// MARK: - Print Helpers

extension AuthTestHelper {
    
    /// Print current authentication state
     
    static func printAuthState() {
        let authManager = AuthenticationManager.shared
        debugLog("📊 === Authentication State ===")
        debugLog("   Authenticated: \(authManager.isAuthenticated)")
        debugLog("   Guest Mode: \(authManager.isGuestMode)")
        debugLog("   Current User: \(authManager.currentUser?.displayName ?? "None")")
        debugLog("   Email: \(authManager.currentUser?.email ?? "None")")
        debugLog("   Biometrics Available: \(authManager.biometricsAvailable)")
        debugLog("   Biometric Type: \(authManager.biometricType)")
        debugLog("================================")
    }
}

#endif
