import Foundation

/// Email/password sign in and sign up.
extension AuthenticationManager {

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
        
        setAuthState(isAuthenticated: true, user: user)
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

        let personalSeedKey = "user_\(user.id)_personal_seeded"
        if !UserDefaults.standard.bool(forKey: personalSeedKey) {
            UserDefaults.standard.set(true, forKey: personalSeedKey)
            Task {
                let result = await PersonalRecipeSeedService().seed()
                if result.imported > 0 {
                    NotificationCenter.default.post(name: .userScopeDidChange, object: nil)
                    logger.info("Seeded \(result.imported) personal recipes")
                }
            }
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

    #if DEBUG
    /// Synchronous sign-in for UI tests: bypasses async `completeSignIn` so `isAuthenticated` is true before the first frame, avoiding a race with the test's first tap.
    func signInSyncForUITesting(email: String, password: String) throws {
        try validateSignInInput(email: email, password: password)
        let userInfo = try verifyAndRetrieveUser(email: email, password: password)
        let user = createUser(from: userInfo, email: email)
        try saveUser(user)
        setAuthState(isAuthenticated: true, user: user)
        UserDefaults.standard.set(true, forKey: isAuthenticatedKey)
        UserDefaults.standard.set(email, forKey: currentEmailKey)
        updateLastActiveTimestamp()
        UserScopedStorage.shared.currentUserId = user.id
        reloadAllManagers()

        let userKey = "user_\(user.id)_initialized"
        if !UserDefaults.standard.bool(forKey: userKey) {
            PersistenceController.shared.populateDatabase()
            UserDefaults.standard.set(true, forKey: userKey)
        }
    }
    #endif

    func signUp(email: String, password: String, fullName: String) async throws {
        guard Validator.isValidEmail(email) else {
            throw AppError.invalidEmail
        }
        
        try Validator.validatePassword(password)
        
        guard !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.emptyField(field: "Full name")
        }
        
        // Prevent overwriting an existing account's credentials (and inheriting its data)
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
        
        setAuthState(isAuthenticated: true, user: user)
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

        let personalSeedKey = "user_\(user.id)_personal_seeded"
        if !UserDefaults.standard.bool(forKey: personalSeedKey) {
            UserDefaults.standard.set(true, forKey: personalSeedKey)
            Task {
                let result = await PersonalRecipeSeedService().seed()
                if result.imported > 0 {
                    NotificationCenter.default.post(name: .userScopeDidChange, object: nil)
                    logger.info("Seeded \(result.imported) personal recipes on sign-up")
                }
            }
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
        // Enforce the same policy as the UI so no caller can bypass it
        guard Validator.isValidEmail(email) else {
            throw AppError.invalidEmail
        }
        try Validator.validatePassword(password)
        
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
}
