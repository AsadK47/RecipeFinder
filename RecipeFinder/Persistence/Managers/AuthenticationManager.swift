import Foundation
import AuthenticationServices
import SwiftUI
import LocalAuthentication
import Security

@MainActor
final class AuthenticationManager: NSObject, ObservableObject {
    static let shared = AuthenticationManager()
    private let logger = AppLogger.logger(category: "Authentication")
    private let credentialManager = SecureCredentialManager.shared
    
    // Authentication State
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: User?
    @Published var authError: AuthError?
    
    // UserDefaults Keys
    private let isAuthenticatedKey = "isAuthenticated"
    private let userDataKey = "userData"
    private let biometricsEnabledKey = "biometricsEnabled"
    private let currentEmailKey = "currentUserEmail"
    private let lastActiveTimestampKey = "lastActiveTimestamp"
    private let appleUserCacheKey = "appleUserCache" // Cache Apple ID user data
    private let sessionTimeoutSeconds: TimeInterval = 86400 // 24 hours (24 * 60 * 60)
    
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
    
    override init() {
        super.init()
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication Status
    
    func checkAuthenticationStatus() {
        isAuthenticated = UserDefaults.standard.bool(forKey: isAuthenticatedKey)
        guard isAuthenticated else { return }
        
        // Check if session has expired (user was away too long)
        if let lastActive = UserDefaults.standard.object(forKey: lastActiveTimestampKey) as? Date {
            let timeAway = Date().timeIntervalSince(lastActive)
            guard timeAway <= sessionTimeoutSeconds else {
                logger.debug("⏱️ Session expired after \(Int(timeAway))s away")
                signOut()
                return
            }
        }
        
        loadUser()
        guard let user = currentUser else { return }
        
        // Restore user ID for scoped storage
        UserScopedStorage.shared.currentUserId = user.id
        
        // Reload all managers
        AccountManager.shared.loadProfile()
        ShoppingListManager.shared.reloadForCurrentUser()
        NotesManager.shared.reloadForCurrentUser()
        KitchenInventoryManager.shared.reloadForCurrentUser()
        MealPlanningManager.shared.reloadForCurrentUser()
        CookingTipsManager.shared.reloadForCurrentUser()
        BadgeManager.shared.reloadForCurrentUser()
        
        updateLastActiveTimestamp()
    }
    
    /// Update the last active timestamp when app comes to foreground
    func updateLastActiveTimestamp() {
        UserDefaults.standard.set(Date(), forKey: lastActiveTimestampKey)
    }
    
    /// Check if session is expired and sign out if needed
    func checkSessionExpiration() {
        guard isAuthenticated else { return }
        guard let lastActive = UserDefaults.standard.object(forKey: lastActiveTimestampKey) as? Date else { return }
        
        let timeAway = Date().timeIntervalSince(lastActive)
        guard timeAway <= sessionTimeoutSeconds else {
            logger.debug("⏱️ Session expired - signing out")
            signOut()
            return
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
        // Validate email and password are not empty
        guard !email.isEmpty else {
            throw AppError.emptyField(field: "Email")
        }
        guard !password.isEmpty else {
            throw AppError.emptyField(field: "Password")
        }
        
        // Validate email format
        guard Validator.isValidEmail(email) else {
            throw AppError.invalidEmail
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
        
        // Load existing user data (if any) to preserve stable ID and creation date
        let existingUser: User? = {
            guard let data = loadUserData(),
                  let user = try? JSONDecoder().decode(User.self, from: data),
                  user.email == email else { return nil }
            return user
        }()
        
        // Use the stable userId stored in the Keychain so the same user always gets
        // the same ID across sign-outs / sign-ins. Without this, every login produces
        // a new UUID which makes all previously saved recipes invisible (they are
        // filtered by userId in Core Data) and triggers populateDatabase() every time.
        let stableId: String
        if let keychainId = credentialManager.getUserId(email: email) {
            // Happy path: userId is stored in Keychain (accounts created/updated after this fix)
            stableId = keychainId
        } else if let existingUser {
            // Migration path: account pre-dates this fix. Reuse the persisted ID so
            // existing recipes/data are still visible under the same userId.
            stableId = existingUser.id
        } else {
            // Fallback: genuinely new identity (should not happen via normal signIn flow)
            stableId = UUID().uuidString
        }
        
        return User(
            id: stableId,
            email: email,
            fullName: userInfo.fullName,
            givenName: givenName,
            familyName: familyName,
            appleUserID: nil,
            createdAt: existingUser?.createdAt ?? Date(),
            lastLoginAt: Date()
        )
    }
    
    private func completeSignIn(user: User, email: String) async throws {
        try saveUser(user)
        
        self.currentUser = user
        self.isAuthenticated = true
        UserDefaults.standard.set(true, forKey: isAuthenticatedKey)
        UserDefaults.standard.set(email, forKey: currentEmailKey)
        updateLastActiveTimestamp()
        
        // Set user ID for scoped storage
        UserScopedStorage.shared.currentUserId = user.id
        
        // Reload all managers for the current user
        AccountManager.shared.loadProfile()
        ShoppingListManager.shared.reloadForCurrentUser()
        NotesManager.shared.reloadForCurrentUser()
        KitchenInventoryManager.shared.reloadForCurrentUser()
        MealPlanningManager.shared.reloadForCurrentUser()
        CookingTipsManager.shared.reloadForCurrentUser()
        BadgeManager.shared.reloadForCurrentUser()
        
        // Check if this is a new user (first time sign-in)
        let userKey = "user_\(user.id)_initialized"
        let isNewUser = !UserDefaults.standard.bool(forKey: userKey)
        
        if isNewUser {
            logger.debug("🆕 New user detected - populating sample recipes")
            PersistenceController.shared.populateDatabase()
            UserDefaults.standard.set(true, forKey: userKey)
            
            // Unlock welcome badge
            BadgeManager.shared.unlockBadge(.welcomeAboard)
        }
        
        // Sync user data to AccountManager if not already set
        let accountManager = AccountManager.shared
        if accountManager.firstName.isEmpty {
            // Parse full name into components
            let fullName = user.fullName ?? ""
            let nameComponents = fullName.components(separatedBy: " ").filter { !$0.isEmpty }
            let firstName = nameComponents.first ?? ""
            let lastName = nameComponents.count > 1 ? nameComponents.last ?? "" : ""
            
            accountManager.updateProfile(
                firstName: firstName,
                lastName: lastName,
                chefType: accountManager.chefType // Keep existing chef type
            )
        }
        HapticManager.shared.success()
    }
    
    // Sign Up (with Secure Password Storage)
    
    func signUp(email: String, password: String, fullName: String) async throws {
        // Validate email format
        guard Validator.isValidEmail(email) else {
            throw AppError.invalidEmail
        }
        
        // Validate password strength
        try Validator.validatePassword(password)
        
        // Validate full name
        guard !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.emptyField(field: "Full name")
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
        
        // Use the stable userId that was just stored in the Keychain by saveCredentials.
        // Using a different UUID here would cause recipes/data to be orphaned on the
        // next sign-in (which calls createUser → credentialManager.getUserId).
        let stableId = credentialManager.getUserId(email: email) ?? UUID().uuidString
        
        let user = User(
            id: stableId,
            email: email,
            fullName: fullName.isEmpty ? nil : fullName,
            givenName: givenName,
            familyName: familyName,
            appleUserID: nil,
            createdAt: Date(),
            lastLoginAt: Date()
        )
        
        try saveUser(user)
        
        self.currentUser = user
        self.isAuthenticated = true
        UserDefaults.standard.set(true, forKey: isAuthenticatedKey)
        UserDefaults.standard.set(email, forKey: currentEmailKey)
        updateLastActiveTimestamp()
        
        // Set user ID for scoped storage so any data saved in this session is
        // tagged correctly, and populateDatabase() can assign the right userId.
        UserScopedStorage.shared.currentUserId = user.id
        
        // Reload managers for the new user
        AccountManager.shared.loadProfile()
        ShoppingListManager.shared.reloadForCurrentUser()
        NotesManager.shared.reloadForCurrentUser()
        KitchenInventoryManager.shared.reloadForCurrentUser()
        MealPlanningManager.shared.reloadForCurrentUser()
        CookingTipsManager.shared.reloadForCurrentUser()
        BadgeManager.shared.reloadForCurrentUser()
        
        // Populate sample recipes for this brand-new account
        let userKey = "user_\(user.id)_initialized"
        if !UserDefaults.standard.bool(forKey: userKey) {
            PersistenceController.shared.populateDatabase()
            UserDefaults.standard.set(true, forKey: userKey)
            BadgeManager.shared.unlockBadge(.welcomeAboard)
        }
        
        // Update AccountManager with user info
        if let givenName = givenName {
            AccountManager.shared.updateProfile(
                firstName: givenName,
                lastName: familyName ?? "",
                chefType: .homeCook
            )
        }
        
        HapticManager.shared.success()
    }
    
    // Sign Up Without Auto-Login (Defensive Programming)
    func signUpWithoutLogin(email: String, password: String, fullName: String) async throws {
        guard !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            throw AuthError.invalidCredentials
        }
        
        // Check if user already exists
        guard credentialManager.getUserInfo(email: email) == nil else {
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
        
        // Don't authenticate or update AccountManager - user must sign in manually (defensive)
        // Profile will be populated when the user actually signs in
        logger.debug("✅ Account created for \(email) - user must sign in manually")
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
            guard success else { return }
            
            self.isAuthenticated = true
            UserDefaults.standard.set(true, forKey: isAuthenticatedKey)
            updateLastActiveTimestamp()
            loadUser()
            
            // Restore user-scoped storage and managers (mirrors checkAuthenticationStatus)
            if let user = currentUser {
                UserScopedStorage.shared.currentUserId = user.id
                AccountManager.shared.loadProfile()
                ShoppingListManager.shared.reloadForCurrentUser()
                NotesManager.shared.reloadForCurrentUser()
                KitchenInventoryManager.shared.reloadForCurrentUser()
                MealPlanningManager.shared.reloadForCurrentUser()
                CookingTipsManager.shared.reloadForCurrentUser()
                BadgeManager.shared.reloadForCurrentUser()
            }
            
            HapticManager.shared.success()
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
        logger.debug("🚪 Sign out initiated")
        
        // Delete session token
        if let email = UserDefaults.standard.string(forKey: currentEmailKey) {
            credentialManager.deleteSessionToken(for: email)
            logger.debug("🗑️ Deleted session token for: \(email)")
        }
        
        // Clear user ID for scoped storage
        UserScopedStorage.shared.currentUserId = nil
        
        // Clear managers (loadProfile will reset to empty values when currentUserId is nil)
        AccountManager.shared.loadProfile()
        ShoppingListManager.shared.reloadForCurrentUser()
        NotesManager.shared.reloadForCurrentUser()
        KitchenInventoryManager.shared.reloadForCurrentUser()
        MealPlanningManager.shared.reloadForCurrentUser()
        CookingTipsManager.shared.reloadForCurrentUser()
        BadgeManager.shared.reloadForCurrentUser()
        
        // Ensure UI updates happen immediately on main thread
        self.isAuthenticated = false
        self.currentUser = nil
        
        UserDefaults.standard.set(false, forKey: self.isAuthenticatedKey)
        UserDefaults.standard.removeObject(forKey: self.currentEmailKey)
        UserDefaults.standard.removeObject(forKey: self.lastActiveTimestampKey)
        
        self.logger.debug("✅ Sign out complete - UI should now show login screen")
        HapticManager.shared.light()
    }
    
    // MARK: - User Persistence
    
    private func saveUser(_ user: User) throws {
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
        
        // Clean up legacy UserDefaults storage if present
        UserDefaults.standard.removeObject(forKey: userDataKey)
    }
    
    private func loadUser() {
        guard let data = loadUserData(),
              let user = try? JSONDecoder().decode(User.self, from: data) else { return }
        self.currentUser = user
    }
    
    /// Load user data from Keychain, falling back to UserDefaults for migration
    private func loadUserData() -> Data? {
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
        
        // Migration: move legacy data from UserDefaults to Keychain
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
    
    // Update Current User
    
    /// Update the current user's information (called when editing profile)
    func updateCurrentUser(_ user: User) {
        currentUser = user
        try? saveUser(user)
        logger.debug("✅ Current user updated: \(user.displayName)")
    }
    
    func deleteAccount() async throws {
        let userId = currentUser?.id
        
        // Delete from Keychain
        if let email = UserDefaults.standard.string(forKey: currentEmailKey) {
            credentialManager.deleteCredentials(email: email)
            credentialManager.deleteSessionToken(for: email)
        }
        
        // Clear user data from Keychain
        let userDataQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userDataKey,
            kSecAttrService as String: "com.recipefinder.userdata"
        ]
        SecItemDelete(userDataQuery as CFDictionary)
        UserDefaults.standard.removeObject(forKey: userDataKey) // legacy cleanup
        UserDefaults.standard.removeObject(forKey: isAuthenticatedKey)
        UserDefaults.standard.removeObject(forKey: biometricsEnabledKey)
        UserDefaults.standard.removeObject(forKey: currentEmailKey)
        UserDefaults.standard.removeObject(forKey: lastActiveTimestampKey)
        UserDefaults.standard.removeObject(forKey: appleUserCacheKey)
        if let userId {
            UserDefaults.standard.removeObject(forKey: "user_\(userId)_initialized")
        }
        
        // Clear all app data (recipes, kitchen, shopping, profile)
        AccountManager.shared.clearAllData()
        
        // Clear user-scoped storage and reset scope
        UserScopedStorage.shared.clearCurrentUserData()
        UserScopedStorage.shared.currentUserId = nil
        
        isAuthenticated = false
        currentUser = nil
        HapticManager.shared.success()
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
            id: appleIDCredential.user, // Stable Apple user identifier — never changes across sign-ins
            email: email,
            fullName: fullName,
            givenName: givenName,
            familyName: familyName,
            appleUserID: appleIDCredential.user,
            createdAt: Date(),
            lastLoginAt: Date()
        )
        
        Task { @MainActor in
            do {
                try saveUser(user)
                
                self.currentUser = user
                self.isAuthenticated = true
                UserDefaults.standard.set(true, forKey: isAuthenticatedKey)
                updateLastActiveTimestamp()
                
                // Set user ID for scoped storage
                UserScopedStorage.shared.currentUserId = user.id
                
                // Reload all managers for this user
                AccountManager.shared.loadProfile()
                ShoppingListManager.shared.reloadForCurrentUser()
                NotesManager.shared.reloadForCurrentUser()
                KitchenInventoryManager.shared.reloadForCurrentUser()
                MealPlanningManager.shared.reloadForCurrentUser()
                CookingTipsManager.shared.reloadForCurrentUser()
                BadgeManager.shared.reloadForCurrentUser()
                
                // Populate sample recipes only once per user
                let userKey = "user_\(user.id)_initialized"
                if !UserDefaults.standard.bool(forKey: userKey) {
                    PersistenceController.shared.populateDatabase()
                    UserDefaults.standard.set(true, forKey: userKey)
                    BadgeManager.shared.unlockBadge(.welcomeAboard)
                }
                
                // Sync name — preserve the stored chef type rather than overwriting with .homeCook
                let existingChefType = AccountManager.shared.chefType
                AccountManager.shared.updateProfile(
                    firstName: user.givenName ?? "",
                    lastName: user.familyName ?? "",
                    chefType: existingChefType
                )
                
                HapticManager.shared.success()
            } catch {
                self.authError = .signInFailed
            }
        }
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        guard let authError = error as? ASAuthorizationError else { return }
        self.authError = authError.code == .canceled ? .signInCancelled : .signInFailed
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


