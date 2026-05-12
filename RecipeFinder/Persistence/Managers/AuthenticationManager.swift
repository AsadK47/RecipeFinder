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
    
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: User?
    @Published var authError: AuthError?
    
    private let isAuthenticatedKey = "isAuthenticated"
    private let userDataKey = "userData"
    private let biometricsEnabledKey = "biometricsEnabled"
    private let currentEmailKey = "currentUserEmail"
    private let lastActiveTimestampKey = "lastActiveTimestamp"
    private let appleUserCacheKey = "appleUserCache"
    private let sessionTimeoutSeconds: TimeInterval = 86400
    
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
    
    func checkAuthenticationStatus() {
        isAuthenticated = UserDefaults.standard.bool(forKey: isAuthenticatedKey)
        guard isAuthenticated else { return }
        
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
        
        UserScopedStorage.shared.currentUserId = user.id
        reloadAllManagers()
        updateLastActiveTimestamp()
    }
    
    func updateLastActiveTimestamp() {
        UserDefaults.standard.set(Date(), forKey: lastActiveTimestampKey)
    }
    
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
    
    func signInWithApple() async throws {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func signIn(email: String, password: String) async throws {
        try validateSignInInput(email: email, password: password)
        let userInfo = try verifyAndRetrieveUser(email: email, password: password)
        let user = createUser(from: userInfo, email: email)
        try await completeSignIn(user: user, email: email)
    }
    
    private func validateSignInInput(email: String, password: String) throws {
        guard !email.isEmpty else {
            throw AppError.emptyField(field: "Email")
        }
        guard !password.isEmpty else {
            throw AppError.emptyField(field: "Password")
        }
        
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
        
        let existingUser: User? = {
            guard let data = loadUserData(),
                  let user = try? JSONDecoder().decode(User.self, from: data),
                  user.email == email else { return nil }
            return user
        }()
        
        let stableId: String
        if let keychainId = credentialManager.getUserId(email: email) {
            stableId = keychainId
        } else if let existingUser {
            stableId = existingUser.id
        } else {
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
        
        UserScopedStorage.shared.currentUserId = user.id
        reloadAllManagers()
        
        let userKey = "user_\(user.id)_initialized"
        let isNewUser = !UserDefaults.standard.bool(forKey: userKey)
        
        if isNewUser {
            logger.debug("🆕 New user detected - populating sample recipes")
            PersistenceController.shared.populateDatabase()
            UserDefaults.standard.set(true, forKey: userKey)
            
            BadgeManager.shared.unlockBadge(.welcomeAboard)
        }
        
        let accountManager = AccountManager.shared
        if accountManager.firstName.isEmpty {
            let fullName = user.fullName ?? ""
            let nameComponents = fullName.components(separatedBy: " ").filter { !$0.isEmpty }
            let firstName = nameComponents.first ?? ""
            let lastName = nameComponents.count > 1 ? nameComponents.last ?? "" : ""
            
            accountManager.updateProfile(
                firstName: firstName,
                lastName: lastName,
                chefType: accountManager.chefType
            )
        }
        HapticManager.shared.success()
    }
    
    func signUp(email: String, password: String, fullName: String) async throws {
        guard Validator.isValidEmail(email) else {
            throw AppError.invalidEmail
        }
        
        try Validator.validatePassword(password)
        
        guard !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.emptyField(field: "Full name")
        }
        
        let saved = credentialManager.saveCredentials(
            email: email,
            password: password,
            fullName: fullName.isEmpty ? "User" : fullName
        )
        
        guard saved else {
            throw AuthError.userCreationFailed
        }
        
        let sessionToken = credentialManager.generateSessionToken()
        credentialManager.saveSessionToken(sessionToken, for: email)
        
        let components = fullName.components(separatedBy: " ")
        let givenName = components.first
        let familyName = components.count > 1 ? components.dropFirst().joined(separator: " ") : nil
        
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
        
        UserScopedStorage.shared.currentUserId = user.id
        reloadAllManagers()
        
        let userKey = "user_\(user.id)_initialized"
        if !UserDefaults.standard.bool(forKey: userKey) {
            PersistenceController.shared.populateDatabase()
            UserDefaults.standard.set(true, forKey: userKey)
            BadgeManager.shared.unlockBadge(.welcomeAboard)
        }
        
        if let givenName = givenName {
            AccountManager.shared.updateProfile(
                firstName: givenName,
                lastName: familyName ?? "",
                chefType: .homeCook
            )
        }
        
        HapticManager.shared.success()
    }
    
    func signUpWithoutLogin(email: String, password: String, fullName: String) async throws {
        guard !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            throw AuthError.invalidCredentials
        }
        
        guard credentialManager.getUserInfo(email: email) == nil else {
            throw AuthError.accountAlreadyExists
        }
        
        let saved = credentialManager.saveCredentials(
            email: email,
            password: password,
            fullName: fullName.isEmpty ? "User" : fullName
        )
        
        guard saved else {
            throw AuthError.userCreationFailed
        }
        
        logger.debug("✅ Account created for \(email) - user must sign in manually")
    }
    
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
            
            if let user = currentUser {
                UserScopedStorage.shared.currentUserId = user.id
                reloadAllManagers()
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
    
    func signOut() {
        logger.debug("🚪 Sign out initiated")
        
        if let email = UserDefaults.standard.string(forKey: currentEmailKey) {
            credentialManager.deleteSessionToken(for: email)
            logger.debug("🗑️ Deleted session token for: \(email)")
        }
        
        UserScopedStorage.shared.currentUserId = nil
        
        self.isAuthenticated = false
        self.currentUser = nil
        
        UserDefaults.standard.set(false, forKey: self.isAuthenticatedKey)
        UserDefaults.standard.removeObject(forKey: self.currentEmailKey)
        UserDefaults.standard.removeObject(forKey: self.lastActiveTimestampKey)
        
        self.logger.debug("✅ Sign out complete - UI should now show login screen")
        HapticManager.shared.light()
    }
    
    private func reloadAllManagers() {
        AccountManager.shared.loadProfile()
        ShoppingListManager.shared.reloadForCurrentUser()
        NotesManager.shared.reloadForCurrentUser()
        KitchenInventoryManager.shared.reloadForCurrentUser()
        MealPlanningManager.shared.reloadForCurrentUser()
        CookingTipsManager.shared.reloadForCurrentUser()
        BadgeManager.shared.reloadForCurrentUser()
    }
    
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
        
        UserDefaults.standard.removeObject(forKey: userDataKey)
    }
    
    private func loadUser() {
        guard let data = loadUserData(),
              let user = try? JSONDecoder().decode(User.self, from: data) else { return }
        self.currentUser = user
    }
    
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
        currentUser = user
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
        
        isAuthenticated = false
        currentUser = nil
        HapticManager.shared.success()
    }
}

extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            authError = .signInFailed
            return
        }
        
        var cachedUserData: (email: String?, fullName: String?, givenName: String?, familyName: String?)?
        if let cachedData = UserDefaults.standard.data(forKey: appleUserCacheKey),
           let cached = try? JSONDecoder().decode(AppleUserCache.self, from: cachedData),
           cached.appleUserID == appleIDCredential.user {
            cachedUserData = (cached.email, cached.fullName, cached.givenName, cached.familyName)
        }
        
        let email = appleIDCredential.email ?? cachedUserData?.email
        let givenName = appleIDCredential.fullName?.givenName ?? cachedUserData?.givenName
        let familyName = appleIDCredential.fullName?.familyName ?? cachedUserData?.familyName
        let fullName = appleIDCredential.fullName?.formatted() ?? cachedUserData?.fullName ?? "Apple User"
        
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
            id: appleIDCredential.user,
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
                
                UserScopedStorage.shared.currentUserId = user.id
                reloadAllManagers()
                
                let userKey = "user_\(user.id)_initialized"
                if !UserDefaults.standard.bool(forKey: userKey) {
                    PersistenceController.shared.populateDatabase()
                    UserDefaults.standard.set(true, forKey: userKey)
                    BadgeManager.shared.unlockBadge(.welcomeAboard)
                }
                
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

private struct AppleUserCache: Codable {
    let appleUserID: String
    let email: String?
    let fullName: String?
    let givenName: String?
    let familyName: String?
}

extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first ?? ASPresentationAnchor()
    }
}

extension PersonNameComponents {
    func formatted() -> String {
        var parts: [String] = []
        if let givenName = givenName { parts.append(givenName) }
        if let familyName = familyName { parts.append(familyName) }
        return parts.joined(separator: " ")
    }
}

