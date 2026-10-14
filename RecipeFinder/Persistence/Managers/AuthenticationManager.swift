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
    // SwiftUI reads environment defaults on the main actor, so assuming main-actor isolation is safe.
    static var defaultValue: any Authenticating {
        MainActor.assumeIsolated { AuthenticationManager.shared }
    }
}

extension EnvironmentValues {
    /// Injected authentication state; defaults to the shared singleton, override with `.environment(\.auth, fake)` in tests/previews.
    var auth: any Authenticating {
        get { self[AuthenticatingKey.self] }
        set { self[AuthenticatingKey.self] = newValue }
    }
}

/// Owns auth state and orchestrates sign-in flows; concerns split across `+Models`/`+Session`/`+EmailAuth`/`+Biometrics`/`+UserStore`/`+AppleSignIn` extensions.
@MainActor
@Observable
final class AuthenticationManager: NSObject, Authenticating {
    static let shared = AuthenticationManager()
    let logger = AppLogger.logger(category: "Authentication")
    /// Injectable so tests can back auth flows with an in-memory keychain instead of the device Keychain.
    let credentialManager: SecureCredentialManager
    /// Injectable session-state store; defaults to `.standard` in production so tests can run isolated from the device's global defaults.
    @ObservationIgnored let defaults: UserDefaults

    // Auth state stays `private(set)`; extensions mutate only via `setAuthState`/`setCurrentUser`.
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
        self.credentialManager = .shared
        self.defaults = .standard
        super.init()
        checkAuthenticationStatus()
    }

    /// Test seam: inject a credential manager (e.g. backed by an in-memory keychain) and an isolated defaults suite. Not used in production.
    init(credentialManager: SecureCredentialManager, defaults: UserDefaults = .standard) {
        self.credentialManager = credentialManager
        self.defaults = defaults
        super.init()
        checkAuthenticationStatus()
    }

    func updateLastActiveTimestamp() {
        defaults.set(Date(), forKey: lastActiveTimestampKey)
    }

    /// Sets auth state centrally so extensions don't assign the `private(set)` flags directly.
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
        CookingStreakManager.shared.reloadForCurrentUser()
        AccountManager.shared.loadProfile()

        // Backfill cooking badges from existing history so upgraders (who cooked before these badges existed)
        // see them immediately, not only after their next cook. Reads persistence directly — the in-memory
        // RecipeStore may still be loading at sign-in. Silent: past achievements don't deserve a launch parade.
        let metrics = BadgeMetrics.from(
            recipes: PersistenceController.shared.fetchRecipes(),
            streakWeeks: CookingStreakManager.shared.streak.currentWeeks
        )
        BadgeManager.shared.checkAndUnlockBadges(metrics: metrics, silent: true)
    }
}
