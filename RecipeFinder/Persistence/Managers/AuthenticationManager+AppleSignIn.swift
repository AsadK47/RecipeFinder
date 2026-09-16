import Foundation
import AuthenticationServices
import UIKit

/// Sign in with Apple: request kick-off, authorization delegate, and presentation.
extension AuthenticationManager {

    func signInWithApple() async throws {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
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
                
                setAuthState(isAuthenticated: true, user: user)
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

                let personalSeedKey = "user_\(user.id)_personal_seeded"
                if !UserDefaults.standard.bool(forKey: personalSeedKey) {
                    UserDefaults.standard.set(true, forKey: personalSeedKey)
                    Task {
                        let result = await PersonalRecipeSeedService().seed()
                        if result.imported > 0 {
                            NotificationCenter.default.post(name: .userScopeDidChange, object: nil)
                        }
                    }
                }
                
                let existingChefType = AccountManager.shared.chefType
                AccountManager.shared.updateProfile(
                    firstName: user.givenName ?? "",
                    lastName: user.familyName ?? "",
                    chefType: existingChefType
                )
                
                HapticManager.shared.success()
            } catch {
                self.logger.error("❌ Apple Sign In failed to persist user: \(error)")
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

extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first ?? ASPresentationAnchor()
    }
}

private struct AppleUserCache: Codable {
    let appleUserID: String
    let email: String?
    let fullName: String?
    let givenName: String?
    let familyName: String?
}

extension PersonNameComponents {
    func formatted() -> String {
        var parts: [String] = []
        if let givenName = givenName { parts.append(givenName) }
        if let familyName = familyName { parts.append(familyName) }
        return parts.joined(separator: " ")
    }
}
