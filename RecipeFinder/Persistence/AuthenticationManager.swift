import Foundation
import AuthenticationServices
import SwiftUI
import LocalAuthentication

final class AuthenticationManager: NSObject, ObservableObject {
    static let shared = AuthenticationManager()
    private let credentialManager = SecureCredentialManager.shared
    
    // Authentication State
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: User?
    @Published var authError: AuthError?
    @Published private(set) var isGuestMode: Bool = false
    
    // UserDefaults Keys
    private let isAuthenticatedKey = "isAuthenticated"
    private let userDataKey = "userData"
    private let biometricsEnabledKey = "biometricsEnabled"
    private let guestModeKey = "guestMode"
    private let currentEmailKey = "currentUserEmail"
    private let lastActiveTimestampKey = "lastActiveTimestamp"
    private let appleUserCacheKey = "appleUserCache" // Cache Apple ID user data
    private let sessionTimeoutSeconds: TimeInterval = 300 // 5 minutes
    
    // User Model
    struct User: Codable {
        let id: String
        let email: String?
        let fullName: String?
        let givenName: String?
        let familyName: String?
        let appleUserID: String?
        let createdAt: Date
        var lastLoginAt: Date
        
        var displayName: String {
            if let fullName = fullName, !fullName.isEmpty {
                return fullName
            }
            if let givenName = givenName {
                return givenName
            }
            return email ?? "User"
        }
        
        var initials: String {
            if let givenName = givenName?.first,
               let familyName = familyName?.first {
                return "\(givenName)\(familyName)".uppercased()
            }
            if let name = fullName?.components(separatedBy: " "),
               name.count >= 2 {
                return "\(name[0].first ?? "U")\(name[1].first ?? "U")".uppercased()
            }
            return "U"
        }
    }
    
    // Authentication Errors
    enum AuthError: LocalizedError {
        case signInFailed
        case signInCancelled
        case invalidCredentials
        case biometricsNotAvailable
        case biometricsFailed
        case userCreationFailed
        case accountAlreadyExists
        
        var errorDescription: String? {
            switch self {
            case .signInFailed:
                return "Sign in failed. Please try again."
            case .signInCancelled:
                return "Sign in was cancelled."
            case .invalidCredentials:
                return "Invalid email or password."
            case .biometricsNotAvailable:
                return "Biometric authentication is not available on this device."
            case .biometricsFailed:
                return "Biometric authentication failed."
            case .userCreationFailed:
                return "Failed to create user account."
            case .accountAlreadyExists:
                return "An account with this email already exists."
            }
        }
    }
    
    private override init() {
        super.init()
        setupTestUser()
        checkAuthenticationStatus()
    }
    
    // MARK: - Test User Setup
    
    private func setupTestUser() {
        // Create a test user if it doesn't exist
        let testEmail = "test@recipefinder.com"
        let testPassword = "test123"
        let testFullName = "Test Chef"
        
        // Check if test user already exists
        if credentialManager.getUserInfo(email: testEmail) == nil {
            // Save test user credentials
            _ = credentialManager.saveCredentials(
                email: testEmail,
                password: testPassword,
                fullName: testFullName
            )
            debugLog("✅ Test user created: \(testEmail) / \(testPassword)")
        }
    }
    
    // MARK: - Authentication Status
    
    func checkAuthenticationStatus() {
        isAuthenticated = UserDefaults.standard.bool(forKey: isAuthenticatedKey)
        isGuestMode = UserDefaults.standard.bool(forKey: guestModeKey)
        
        // Check if session has expired (user was away too long)
        if isAuthenticated && !isGuestMode {
            if let lastActive = UserDefaults.standard.object(forKey: lastActiveTimestampKey) as? Date {
                let timeAway = Date().timeIntervalSince(lastActive)
                if timeAway > sessionTimeoutSeconds {
                    // Session expired - require re-authentication
                    debugLog("⏱️ Session expired after \(Int(timeAway))s away")
                    signOut()
                    return
                }
            }
        }
        
        if isAuthenticated {
            loadUser()
            updateLastActiveTimestamp()
        }
    }
    
    /// Update the last active timestamp when app comes to foreground
    func updateLastActiveTimestamp() {
        UserDefaults.standard.set(Date(), forKey: lastActiveTimestampKey)
    }
    
    /// Check if session is expired and sign out if needed
    func checkSessionExpiration() {
        guard isAuthenticated && !isGuestMode else { return }
        
        if let lastActive = UserDefaults.standard.object(forKey: lastActiveTimestampKey) as? Date {
            let timeAway = Date().timeIntervalSince(lastActive)
            if timeAway > sessionTimeoutSeconds {
                debugLog("⏱️ Session expired - signing out")
                signOut()
            }
        }
    }
    
    // Guest Mode
    
    func skipLoginAsGuest() {
        // Post notification to show splash screen
        NotificationCenter.default.post(name: NSNotification.Name("ShowGuestSplash"), object: nil)
        
        // Delay authentication to allow splash screen to show
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let guestUser = User(
                id: UUID().uuidString,
                email: nil,
                fullName: "Guest User",
                givenName: "Guest",
                familyName: nil,
                appleUserID: nil,
                createdAt: Date(),
                lastLoginAt: Date()
            )
            
            self.currentUser = guestUser
            self.isAuthenticated = true
            self.isGuestMode = true
            
            UserDefaults.standard.set(true, forKey: self.isAuthenticatedKey)
            UserDefaults.standard.set(true, forKey: self.guestModeKey)
            
            HapticManager.shared.light()
        }
    }
    
    // Apple Sign In
    
    func signInWithApple() async throws {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // MARK: - Email/Password Sign In (Local with Secure Storage)
    
    func signIn(email: String, password: String) async throws {
        try validateSignInInput(email: email, password: password)
        let userInfo = try verifyAndRetrieveUser(email: email, password: password)
        let user = createUser(from: userInfo, email: email)
        try await completeSignIn(user: user, email: email)
    }
    
    private func validateSignInInput(email: String, password: String) throws {
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
    }
    
    private func verifyAndRetrieveUser(email: String, password: String) throws -> (email: String, fullName: String) {
        let isValid = credentialManager.verifyCredentials(email: email, password: password)
        guard isValid else {
            throw AuthError.invalidCredentials
        }
        
        guard let userInfo = credentialManager.getUserInfo(email: email) else {
            throw AuthError.invalidCredentials
        }
        
        let sessionToken = credentialManager.generateSessionToken()
        credentialManager.saveSessionToken(sessionToken, for: email)
        
        return userInfo
    }
    
    private func createUser(from userInfo: (email: String, fullName: String), email: String) -> User {
        let components = userInfo.fullName.components(separatedBy: " ")
        let givenName = components.first
        let familyName = components.count > 1 ? components.dropFirst().joined(separator: " ") : nil
        
        return User(
            id: UUID().uuidString,
            email: email,
            fullName: userInfo.fullName,
            givenName: givenName,
            familyName: familyName,
            appleUserID: nil,
            createdAt: Date(),
            lastLoginAt: Date()
        )
    }
    
    private func completeSignIn(user: User, email: String) async throws {
        try await saveUser(user)
        
        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
            self.isGuestMode = false
            UserDefaults.standard.set(true, forKey: isAuthenticatedKey)
            UserDefaults.standard.set(false, forKey: guestModeKey)
            UserDefaults.standard.set(email, forKey: currentEmailKey)
            updateLastActiveTimestamp()
            
            // Sync user data to AccountManager if not already set
            let accountManager = AccountManager.shared
            if accountManager.email.isEmpty || accountManager.email != email {
                // Parse full name into components
                let fullName = user.fullName ?? ""
                let nameComponents = fullName.components(separatedBy: " ").filter { !$0.isEmpty }
                let firstName = nameComponents.first ?? ""
                let lastName = nameComponents.count > 1 ? nameComponents.last ?? "" : ""
                let middleName = nameComponents.count > 2 ? nameComponents[1..<nameComponents.count-1].joined(separator: " ") : ""
                
                accountManager.updateProfile(
                    firstName: firstName,
                    middleName: middleName,
                    lastName: lastName,
                    email: email,
                    address: accountManager.address, // Keep existing address
                    dateOfBirth: accountManager.dateOfBirth, // Keep existing DOB
                    chefType: accountManager.chefType // Keep existing chef type
                )
            }
            
            HapticManager.shared.success()
        }
    }
    
    // Sign Up (with Secure Password Storage)
    
    func signUp(email: String, password: String, fullName: String) async throws {
        guard !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            throw AuthError.invalidCredentials
        }
        
        // Save hashed credentials to Keychain
        let saved = credentialManager.saveCredentials(
            email: email,
            password: password,
            fullName: fullName.isEmpty ? "User" : fullName
        )
        
        guard saved else {
            throw AuthError.userCreationFailed
        }
        
        // Generate session token
        let sessionToken = credentialManager.generateSessionToken()
        credentialManager.saveSessionToken(sessionToken, for: email)
        
        let components = fullName.components(separatedBy: " ")
        let givenName = components.first
        let familyName = components.count > 1 ? components.dropFirst().joined(separator: " ") : nil
        
        let user = User(
            id: UUID().uuidString,
            email: email,
            fullName: fullName.isEmpty ? nil : fullName,
            givenName: givenName,
            familyName: familyName,
            appleUserID: nil,
            createdAt: Date(),
            lastLoginAt: Date()
        )
        
        try await saveUser(user)
        
        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
            self.isGuestMode = false
            UserDefaults.standard.set(true, forKey: isAuthenticatedKey)
            UserDefaults.standard.set(false, forKey: guestModeKey)
            UserDefaults.standard.set(email, forKey: currentEmailKey)
            updateLastActiveTimestamp()
            
            // Update AccountManager with user info
            if let givenName = givenName {
                AccountManager.shared.updateProfile(
                    firstName: givenName,
                    middleName: "",
                    lastName: familyName ?? "",
                    email: email,
                    address: "",
                    dateOfBirth: nil,
                    chefType: .homeCook
                )
            }
            
            HapticManager.shared.success()
        }
    }
    
    // Sign Up Without Auto-Login (Defensive Programming)
    func signUpWithoutLogin(email: String, password: String, fullName: String) async throws {
        guard !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            throw AuthError.invalidCredentials
        }
        
        // Check if user already exists
        if credentialManager.getUserInfo(email: email) != nil {
            throw AuthError.accountAlreadyExists
        }
        
        // Save hashed credentials to Keychain
        let saved = credentialManager.saveCredentials(
            email: email,
            password: password,
            fullName: fullName.isEmpty ? "User" : fullName
        )
        
        guard saved else {
            throw AuthError.userCreationFailed
        }
        
        // Parse full name into components and populate AccountManager
        let nameComponents = fullName.components(separatedBy: " ").filter { !$0.isEmpty }
        let firstName = nameComponents.first ?? ""
        let lastName = nameComponents.count > 1 ? nameComponents.last ?? "" : ""
        let middleName = nameComponents.count > 2 ? nameComponents[1..<nameComponents.count-1].joined(separator: " ") : ""
        
        // Update AccountManager with parsed name and email
        await MainActor.run {
            AccountManager.shared.updateProfile(
                firstName: firstName,
                middleName: middleName,
                lastName: lastName,
                email: email,
                address: "",
                dateOfBirth: nil,
                chefType: .homeCook
            )
        }
        
        // Don't authenticate - user must sign in manually (defensive)
        debugLog("✅ Account created for \(email) - user must sign in manually")
    }
    
    // Biometric Authentication
    
    func authenticateWithBiometrics() async throws {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthError.biometricsNotAvailable
        }
        
        let reason = "Authenticate to access RecipeFinder"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                await MainActor.run {
                    self.isAuthenticated = true
                    UserDefaults.standard.set(true, forKey: isAuthenticatedKey)
                    updateLastActiveTimestamp()
                    loadUser()
                    HapticManager.shared.success()
                }
            }
        } catch {
            throw AuthError.biometricsFailed
        }
    }
    
    var biometricsAvailable: Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    var biometricType: String {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return "None"
        }
        
        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Biometrics"
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        debugLog("🚪 Sign out initiated")
        
        // Delete session token
        if let email = UserDefaults.standard.string(forKey: currentEmailKey) {
            credentialManager.deleteSessionToken(for: email)
            debugLog("🗑️ Deleted session token for: \(email)")
        }
        
        // Ensure UI updates happen immediately on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isAuthenticated = false
            self.currentUser = nil
            self.isGuestMode = false
            
            UserDefaults.standard.set(false, forKey: self.isAuthenticatedKey)
            UserDefaults.standard.set(false, forKey: self.guestModeKey)
            UserDefaults.standard.removeObject(forKey: self.currentEmailKey)
            UserDefaults.standard.removeObject(forKey: self.lastActiveTimestampKey)
            
            self.debugLog("✅ Sign out complete - UI should now show login screen")
            HapticManager.shared.light()
        }
    }
    
    // MARK: - User Persistence
    
    private func saveUser(_ user: User) async throws {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(user)
            
            // Save to secure storage (Keychain in production)
            UserDefaults.standard.set(data, forKey: userDataKey)
        } catch {
            throw AuthError.userCreationFailed
        }
    }
    
    private func loadUser() {
        guard let data = UserDefaults.standard.data(forKey: userDataKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return
        }
        
        currentUser = user
        
        // Sync with AccountManager
        AccountManager.shared.updateProfile(
            firstName: user.givenName ?? "",
            middleName: "",
            lastName: user.familyName ?? "",
            email: user.email ?? "",
            address: "",
            dateOfBirth: nil,
            chefType: .homeCook
        )
    }
    
    func deleteAccount() async throws {
        // Delete from Keychain
        if let email = UserDefaults.standard.string(forKey: currentEmailKey) {
            credentialManager.deleteCredentials(email: email)
            credentialManager.deleteSessionToken(for: email)
        }
        
        // Clear all user data
        UserDefaults.standard.removeObject(forKey: userDataKey)
        UserDefaults.standard.removeObject(forKey: isAuthenticatedKey)
        UserDefaults.standard.removeObject(forKey: biometricsEnabledKey)
        UserDefaults.standard.removeObject(forKey: guestModeKey)
        UserDefaults.standard.removeObject(forKey: currentEmailKey)
        
        // Clear all app data
        AccountManager.shared.clearAllData()
        
        await MainActor.run {
            isAuthenticated = false
            currentUser = nil
            isGuestMode = false
            HapticManager.shared.success()
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            authError = .signInFailed
            return
        }
        
        // Try to get cached user data first (for returning users)
        var cachedUserData: (email: String?, fullName: String?, givenName: String?, familyName: String?)?
        if let cachedData = UserDefaults.standard.data(forKey: appleUserCacheKey),
           let cached = try? JSONDecoder().decode(AppleUserCache.self, from: cachedData),
           cached.appleUserID == appleIDCredential.user {
            cachedUserData = (cached.email, cached.fullName, cached.givenName, cached.familyName)
        }
        
        // Use fresh data if available, otherwise fall back to cached data
        let email = appleIDCredential.email ?? cachedUserData?.email
        let givenName = appleIDCredential.fullName?.givenName ?? cachedUserData?.givenName
        let familyName = appleIDCredential.fullName?.familyName ?? cachedUserData?.familyName
        let fullName = appleIDCredential.fullName?.formatted() ?? cachedUserData?.fullName ?? "Apple User"
        
        // Cache the user data for future sign-ins
        if appleIDCredential.email != nil || appleIDCredential.fullName != nil {
            let cache = AppleUserCache(
                appleUserID: appleIDCredential.user,
                email: email,
                fullName: fullName,
                givenName: givenName,
                familyName: familyName
            )
            if let encoded = try? JSONEncoder().encode(cache) {
                UserDefaults.standard.set(encoded, forKey: appleUserCacheKey)
            }
        }
        
        let user = User(
            id: UUID().uuidString,
            email: email,
            fullName: fullName,
            givenName: givenName,
            familyName: familyName,
            appleUserID: appleIDCredential.user,
            createdAt: Date(),
            lastLoginAt: Date()
        )
        
        Task {
            do {
                try await saveUser(user)
                
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.isGuestMode = false
                    UserDefaults.standard.set(true, forKey: isAuthenticatedKey)
                    UserDefaults.standard.set(false, forKey: guestModeKey)
                    updateLastActiveTimestamp()
                    
                    // Update AccountManager
                    AccountManager.shared.updateProfile(
                        firstName: user.givenName ?? "",
                        middleName: "",
                        lastName: user.familyName ?? "",
                        email: user.email ?? "",
                        address: "",
                        dateOfBirth: nil,
                        chefType: .homeCook
                    )
                    
                    HapticManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    self.authError = .signInFailed
                }
            }
        }
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        if let authError = error as? ASAuthorizationError {
            if authError.code == .canceled {
                self.authError = .signInCancelled
            } else {
                self.authError = .signInFailed
            }
        }
    }
}

// MARK: - Apple User Cache Model

private struct AppleUserCache: Codable {
    let appleUserID: String
    let email: String?
    let fullName: String?
    let givenName: String?
    let familyName: String?
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first ?? ASPresentationAnchor()
    }
}

// MARK: - PersonNameComponents Extension

extension PersonNameComponents {
    func formatted() -> String {
        var parts: [String] = []
        if let givenName = givenName { parts.append(givenName) }
        if let familyName = familyName { parts.append(familyName) }
        return parts.joined(separator: " ")
    }
}

// MARK: - Debug Logging

extension AuthenticationManager {
    private func debugLog(_ message: String) {
        #if DEBUG
        print("[AuthenticationManager] \(message)")
        #endif
    }
}
