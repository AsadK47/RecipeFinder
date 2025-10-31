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
    static let testPassword = "Test123456"
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
            print("✅ Test accounts seeded successfully!")
            print("📧 Test User: \(testEmail) / \(testPassword)")
            print("👨‍💼 Admin User: \(adminEmail) / \(adminPassword)")
        } else {
            print("❌ Failed to seed test accounts")
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
        
        print("🧹 All authentication data cleared")
    }
    
    // MARK: - Quick Sign In
    
    /// Quick sign in with test account
    static func quickSignInAsTest() async throws {
        try await AuthenticationManager.shared.signIn(
            email: testEmail,
            password: testPassword
        )
        print("✅ Signed in as Test User")
    }
    
    /// Quick sign in with admin account
    static func quickSignInAsAdmin() async throws {
        try await AuthenticationManager.shared.signIn(
            email: adminEmail,
            password: adminPassword
        )
        print("✅ Signed in as Admin User")
    }
}

// MARK: - Print Helpers

extension AuthTestHelper {
    
    /// Print current authentication state
    static func printAuthState() {
        let authManager = AuthenticationManager.shared
        print("📊 === Authentication State ===")
        print("   Authenticated: \(authManager.isAuthenticated)")
        print("   Guest Mode: \(authManager.isGuestMode)")
        print("   Current User: \(authManager.currentUser?.displayName ?? "None")")
        print("   Email: \(authManager.currentUser?.email ?? "None")")
        print("   Biometrics Available: \(authManager.biometricsAvailable)")
        print("   Biometric Type: \(authManager.biometricType)")
        print("================================")
    }
}

#endif
