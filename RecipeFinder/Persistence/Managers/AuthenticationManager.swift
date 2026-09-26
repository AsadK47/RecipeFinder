import Foundation
import AuthenticationServices
import SwiftUI
import LocalAuthentication
import Security

/// Behavioural seam so views/tests depend on this protocol, not the singleton.
@MainActor
protocol Authenticating: AnyObject, Observable {
    var isAuthenticated: Bool { get }
    var currentUser: AuthenticationManager.User? { get }
    var authError: AuthenticationManager.AuthError? { get set }
    var biometricsAvailable: Bool { get }
    var biometricType: String { get }
    func signIn(email: String, password: String) async throws
    func signUpWithoutLogin(email: String, password: String, fullName: String) async throws
    func signOut()
    func deleteAccount() async throws
    func updateCurrentUser(_ user: AuthenticationManager.User)
    func authenticateWithBiometrics() async throws
    func checkSessionExpiration()
    func updateLastActiveTimestamp()
}

private struct AuthenticatingKey: EnvironmentKey {
    // SwiftUI reads environment defaults on the main actor during view updates,
    // so assuming main-actor isolation here is safe; the real app injects the
    // shared instance at the composition root regardless.
    static var defaultValue: any Authenticating {
        MainActor.assumeIsolated { AuthenticationManager.shared }
    }
}

extension EnvironmentValues {
    /// Injected authentication state. Defaults to the shared singleton; override
    /// with `.environment(\.auth, fake)` in tests/previews.
    var auth: any Authenticating {
        get { self[AuthenticatingKey.self] }
        set { self[AuthenticatingKey.self] = newValue }
    }
}

/// Owns the app's authentication state and orchestrates the sign-in flows. The
/// individual concerns live in focused extensions to keep this a manageable size:
/// - `AuthenticationManager+Models` — `User` / `AuthError`
/// - `AuthenticationManager+Session` — status checks, session expiry, sign out
/// - `AuthenticationManager+EmailAuth` — email/password sign in & sign up
/// - `AuthenticationManager+Biometrics` — Face ID / Touch ID
/// - `AuthenticationManager+UserStore` — Keychain user persistence
/// - `AuthenticationManager+AppleSignIn` — Sign in with Apple
@MainActor
@Observable
final class AuthenticationManager: NSObject, Authenticating {
    static let shared = AuthenticationManager()
    let logger = AppLogger.logger(category: "Authentication")
    let credentialManager = SecureCredentialManager.shared

    // Auth state stays `private(set)`; the concern-specific extensions mutate it
    // only via `setAuthState`/`setCurrentUser` below, preserving that invariant.
    private(set) var isAuthenticated: Bool = false
    private(set) var currentUser: User?
    var authError: AuthError?

    @ObservationIgnored let isAuthenticatedKey = "isAuthenticated"
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
        KitchenInventoryManager.shared.reloadForCurrentUser()
        MealPlanningManager.shared.reloadForCurrentUser()
        BadgeManager.shared.reloadForCurrentUser()
        CollectionManager.shared.reloadForCurrentUser()
        AccountManager.shared.loadProfile()
    }
}
