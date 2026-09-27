
import Foundation
import AuthenticationServices
import SwiftUI

private let logger = AppLogger.logger(category: "AppleSignIn")

/// Behavioural seam so views depend on this protocol, not the `AppleSignInManager` singleton, and tests can inject a fake.
@MainActor
protocol AppleSignInHandling: AnyObject, Observable {
    var errorMessage: String? { get }
    func signIn()
}

private struct AppleSignInHandlingKey: EnvironmentKey {
    // SwiftUI reads environment defaults on the main actor, so assuming main-actor isolation is safe.
    static var defaultValue: any AppleSignInHandling {
        MainActor.assumeIsolated { AppleSignInManager.shared }
    }
}

extension EnvironmentValues {
    /// Injected Apple sign-in handler; defaults to the shared singleton, override with `.environment(\.appleSignIn, fake)` in tests/previews.
    var appleSignIn: any AppleSignInHandling {
        get { self[AppleSignInHandlingKey.self] }
        set { self[AppleSignInHandlingKey.self] = newValue }
    }
}

@MainActor
@Observable
final class AppleSignInManager: NSObject, AppleSignInHandling {
    static let shared = AppleSignInManager()

    var isAuthenticated = false
    var userIdentifier: String?
    var userEmail: String?
    var fullName: String?
    var errorMessage: String?
    
    private override init() {
        super.init()
        checkAuthenticationState()
    }
    
    func checkAuthenticationState() {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserIdentifier") else {
            isAuthenticated = false
            UserScopedStorage.shared.currentUserId = nil
            return
        }
        
        UserScopedStorage.shared.currentUserId = userID
        
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userID) { credentialState, error in
            Task { @MainActor in
                switch credentialState {
                case .authorized:
                    self.isAuthenticated = true
                    self.userIdentifier = userID
                    self.loadUserData()
                    
                    ShoppingListManager.shared.reloadForCurrentUser()
                    KitchenInventoryManager.shared.reloadForCurrentUser()
                    MealPlanningManager.shared.reloadForCurrentUser()
                    BadgeManager.shared.reloadForCurrentUser()
                    CollectionManager.shared.reloadForCurrentUser()
                case .revoked, .notFound:
                    self.signOut()
                default:
                    self.isAuthenticated = false
                    UserScopedStorage.shared.currentUserId = nil
                }
            }
        }
    }
    
    func signIn() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "appleUserIdentifier")
        UserDefaults.standard.removeObject(forKey: "appleUserEmail")
        UserDefaults.standard.removeObject(forKey: "appleUserName")
        
        UserScopedStorage.shared.currentUserId = nil
        
        isAuthenticated = false
        userIdentifier = nil
        userEmail = nil
        fullName = nil
        
        Task { @MainActor in
            ShoppingListManager.shared.reloadForCurrentUser()
            KitchenInventoryManager.shared.reloadForCurrentUser()
            MealPlanningManager.shared.reloadForCurrentUser()
            BadgeManager.shared.reloadForCurrentUser()
            CollectionManager.shared.reloadForCurrentUser()
        }

        HapticManager.shared.success()
    }
    
    private func loadUserData() {
        userEmail = UserDefaults.standard.string(forKey: "appleUserEmail")
        fullName = UserDefaults.standard.string(forKey: "appleUserName")
    }
    
    private func saveUserData(identifier: String, email: String?, name: PersonNameComponents?) {
        UserDefaults.standard.set(identifier, forKey: "appleUserIdentifier")
        
        UserScopedStorage.shared.currentUserId = identifier
        
        let userKey = "user_\(identifier)_initialized"
        let isNewUser = !UserDefaults.standard.bool(forKey: userKey)
        
        if let email = email {
            UserDefaults.standard.set(email, forKey: "appleUserEmail")
        }
        
        if let name = name {
            let fullName = [name.givenName, name.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            if !fullName.isEmpty {
                UserDefaults.standard.set(fullName, forKey: "appleUserName")
            }
        }
        
        Task { @MainActor in
            ShoppingListManager.shared.reloadForCurrentUser()
            KitchenInventoryManager.shared.reloadForCurrentUser()
            MealPlanningManager.shared.reloadForCurrentUser()
            BadgeManager.shared.reloadForCurrentUser()
            CollectionManager.shared.reloadForCurrentUser()

            if isNewUser {
                logger.debug("🆕 New user detected - populating sample recipes")
                PersistenceController.shared.populateDatabase()
                UserDefaults.standard.set(true, forKey: userKey)
                
                BadgeManager.shared.unlockBadge(.welcomeAboard)
            }
        }
    }
}

extension AppleSignInManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Invalid credentials"
            return
        }
        
        let userID = credential.user
        let email = credential.email
        let name = credential.fullName
        
        saveUserData(identifier: userID, email: email, name: name)
        
        userIdentifier = userID
        userEmail = email ?? UserDefaults.standard.string(forKey: "appleUserEmail")
        
        if let name = name {
            fullName = [name.givenName, name.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
        } else {
            fullName = UserDefaults.standard.string(forKey: "appleUserName")
        }
        
        isAuthenticated = true
        errorMessage = nil
        
        HapticManager.shared.success()
        
        logger.debug("✅ [AppleSignIn] Successfully signed in: \(userID)")
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let authError = error as NSError
        
        if authError.code == 1001 {
            errorMessage = nil
            logger.debug("ℹ️ [AppleSignIn] User cancelled sign in")
            return
        }
        
        errorMessage = "Sign in failed: \(error.localizedDescription)"
        HapticManager.shared.error()
        
        logger.error("❌ [AppleSignIn] Error: \(error.localizedDescription)")
    }
}

extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first {
            return window
        }
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            logger.debug("Warning: Using fallback window for Apple Sign In presentation")
            return window
        }
        
        logger.debug("Critical: No existing window found for Apple Sign In, creating fallback")
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.windowLevel = .alert
        window.makeKeyAndVisible()
        return window
    }
}
