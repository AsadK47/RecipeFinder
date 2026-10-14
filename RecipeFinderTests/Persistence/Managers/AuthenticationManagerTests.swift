import Testing
import Foundation
import Security
@testable import RecipeFinder

/// In-memory keychain so auth flows run deterministically without touching device-global state.
private final class MemoryKeychain: KeychainStore, @unchecked Sendable {
    private let lock = NSLock()
    private var items: [String: Data] = [:]  // keyed by account (hashed email)

    private func account(_ q: [String: Any]) -> String? { q[kSecAttrAccount as String] as? String }

    func add(_ attributes: [String: Any]) -> OSStatus {
        guard let data = attributes[kSecValueData as String] as? Data, let acc = account(attributes) else { return errSecParam }
        lock.lock(); defer { lock.unlock() }
        items[acc] = data
        return errSecSuccess
    }

    func copyMatching(_ query: [String: Any]) -> (status: OSStatus, data: Data?) {
        guard let acc = account(query) else { return (errSecItemNotFound, nil) }
        lock.lock(); defer { lock.unlock() }
        if let data = items[acc] { return (errSecSuccess, data) }
        return (errSecItemNotFound, nil)
    }

    func delete(_ query: [String: Any]) -> OSStatus {
        lock.lock(); defer { lock.unlock() }
        if let acc = account(query) {
            return items.removeValue(forKey: acc) != nil ? errSecSuccess : errSecItemNotFound
        }
        let before = items.count
        items.removeAll()
        return before > 0 ? errSecSuccess : errSecItemNotFound
    }
}

@MainActor
@Suite("AuthenticationManager — orchestration")
struct AuthenticationManagerTests {

    private func makeSUT() -> AuthenticationManager {
        let credentials = SecureCredentialManager(keychain: MemoryKeychain(), hasher: PasswordHasher(rounds: 2_000))
        // Isolated defaults suite per SUT so session state can't bleed in from the device's global
        // defaults (or another test's successful sign-in) and pre-authenticate the manager on init.
        let defaults = UserDefaults(suiteName: "test.auth.\(UUID().uuidString)") ?? .standard
        return AuthenticationManager(credentialManager: credentials, defaults: defaults)
    }

    /// Runs an async throwing op and returns the thrown error (or nil).
    private func error(_ op: () async throws -> Void) async -> Error? {
        do { try await op(); return nil } catch { return error }
    }

    // MARK: - signIn validation (throws before any state mutation)

    @Test func signIn_emptyEmail_throwsEmptyField() async {
        let sut = makeSUT()
        let err = await error { try await sut.signIn(email: "", password: "Secret1!") }
        guard let e = err as? AppError, case .emptyField = e else {
            Issue.record("expected emptyField, got \(String(describing: err))"); return
        }
    }

    @Test func signIn_emptyPassword_throwsEmptyField() async {
        let sut = makeSUT()
        let err = await error { try await sut.signIn(email: "a@b.com", password: "") }
        guard let e = err as? AppError, case .emptyField = e else {
            Issue.record("expected emptyField, got \(String(describing: err))"); return
        }
    }

    @Test func signIn_invalidEmail_throwsInvalidEmail() async {
        let sut = makeSUT()
        let err = await error { try await sut.signIn(email: "not-an-email", password: "Secret1!") }
        guard let e = err as? AppError, case .invalidEmail = e else {
            Issue.record("expected invalidEmail, got \(String(describing: err))"); return
        }
    }

    @Test func signIn_unknownAccount_throwsInvalidCredentials() async {
        let sut = makeSUT()
        let err = await error { try await sut.signIn(email: "nobody@b.com", password: "Secret1!") }
        guard let e = err as? AuthenticationManager.AuthError, case .invalidCredentials = e else {
            Issue.record("expected invalidCredentials, got \(String(describing: err))"); return
        }
        #expect(!sut.isAuthenticated)
    }

    @Test func signIn_wrongPassword_throwsInvalidCredentials() async {
        let sut = makeSUT()
        #expect(sut.credentialManager.saveCredentials(email: "a@b.com", password: "Right1!", fullName: "Ann"))
        let err = await error { try await sut.signIn(email: "a@b.com", password: "Wrong9!") }
        guard let e = err as? AuthenticationManager.AuthError, case .invalidCredentials = e else {
            Issue.record("expected invalidCredentials, got \(String(describing: err))"); return
        }
        #expect(!sut.isAuthenticated)
    }

    // MARK: - signUpWithoutLogin (no global state: validate → duplicate-guard → save, no login)

    @Test func signUpWithoutLogin_createsAccountWithoutLoggingIn() async throws {
        let sut = makeSUT()
        try await sut.signUpWithoutLogin(email: "new@b.com", password: "Secret1!", fullName: "New User")
        // Account persisted…
        #expect(sut.credentialManager.getUserInfo(email: "new@b.com")?.fullName == "New User")
        // …but the user is NOT signed in (that's the "without login" contract).
        #expect(!sut.isAuthenticated)
    }

    @Test func signUpWithoutLogin_invalidEmail_throwsAndSavesNothing() async {
        let sut = makeSUT()
        let err = await error { try await sut.signUpWithoutLogin(email: "bad", password: "Secret1!", fullName: "X") }
        guard let e = err as? AppError, case .invalidEmail = e else {
            Issue.record("expected invalidEmail, got \(String(describing: err))"); return
        }
        #expect(sut.credentialManager.getUserInfo(email: "bad") == nil)
    }

    @Test func signUpWithoutLogin_weakPassword_throwsAndSavesNothing() async {
        let sut = makeSUT()
        let err = await error { try await sut.signUpWithoutLogin(email: "weak@b.com", password: "123", fullName: "X") }
        #expect(err != nil, "a weak password must be rejected")
        #expect(sut.credentialManager.getUserInfo(email: "weak@b.com") == nil)
    }

    /// The security-critical guard: signing up with an existing email must NOT overwrite that account's credentials.
    @Test func signUpWithoutLogin_duplicateEmail_throwsAndKeepsOriginalCredentials() async {
        let sut = makeSUT()
        #expect(sut.credentialManager.saveCredentials(email: "a@b.com", password: "Original1!", fullName: "Ann"))

        let err = await error { try await sut.signUpWithoutLogin(email: "a@b.com", password: "Hijack9!", fullName: "Mallory") }
        guard let e = err as? AuthenticationManager.AuthError, case .accountAlreadyExists = e else {
            Issue.record("expected accountAlreadyExists, got \(String(describing: err))"); return
        }
        // Original credentials survive; the attacker's password does not take over.
        #expect(sut.credentialManager.verifyCredentials(email: "a@b.com", password: "Original1!"))
        #expect(!sut.credentialManager.verifyCredentials(email: "a@b.com", password: "Hijack9!"))
        #expect(sut.credentialManager.getUserInfo(email: "a@b.com")?.fullName == "Ann")
    }
}
