import Foundation
import AuthenticationServices
import SwiftUI
import LocalAuthentication
import Security

/// Owns the app's authentication state and orchestrates the sign-in flows. The
/// individual concerns live in focused extensions to keep this a manageable size:
/// - `AuthenticationManager+Models` — `User` / `AuthError`
/// - `AuthenticationManager+Session` — status checks, session expiry, sign out
/// - `AuthenticationManager+EmailAuth` — email/password sign in & sign up
/// - `AuthenticationManager+Biometrics` — Face ID / Touch ID
/// - `AuthenticationManager+UserStore` — Keychain user persistence
/// - `AuthenticationManager+AppleSignIn` — Sign in with Apple
@MainActor
final class AuthenticationManager: NSObject, ObservableObject {
    static let shared = AuthenticationManager()
    let logger = AppLogger.logger(category: "Authentication")
    let credentialManager = SecureCredentialManager.shared

    // Auth state stays `private(set)`; the concern-specific extensions mutate it
    // only via `setAuthState`/`setCurrentUser` below, preserving that invariant.
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: User?
    @Published var authError: AuthError?

    let isAuthenticatedKey = "isAuthenticated"
    let userDataKey = "userData"
    let biometricsEnabledKey = "biometricsEnabled"
    let currentEmailKey = "currentUserEmail"
    let lastActiveTimestampKey = "lastActiveTimestamp"
    let appleUserCacheKey = "appleUserCache"
    let sessionTimeoutSeconds: TimeInterval = 86400

    private override init() {
        super.init()
        checkAuthenticationStatus()
    }

    func updateLastActiveTimestamp() {
        UserDefaults.standard.set(Date(), forKey: lastActiveTimestampKey)
    }

    /// Sets the authentication state. Centralised so the `private(set)` invariant
    /// is preserved: extensions call this rather than assigning the flags directly.
    func setAuthState(isAuthenticated: Bool, user: User?) {
        self.isAuthenticated = isAuthenticated
        self.currentUser = user
    }

    /// Updates just the current user (e.g. after loading from the Keychain).
    func setCurrentUser(_ user: User?) {
        self.currentUser = user
    }

    func reloadAllManagers() {
        ShoppingListManager.shared.reloadForCurrentUser()
        NotesManager.shared.reloadForCurrentUser()
        KitchenInventoryManager.shared.reloadForCurrentUser()
        MealPlanningManager.shared.reloadForCurrentUser()
        CookingTipsManager.shared.reloadForCurrentUser()
        BadgeManager.shared.reloadForCurrentUser()
        AccountManager.shared.loadProfile()
    }
}
