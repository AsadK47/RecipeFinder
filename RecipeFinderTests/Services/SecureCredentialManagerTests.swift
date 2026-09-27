import Testing
import Foundation
import Security
@testable import RecipeFinder

/// In-memory stand-in for the system Keychain so credential storage can be
/// exercised deterministically, without touching device-global state.
private final class InMemoryKeychainStore: KeychainStore, @unchecked Sendable {
    private struct Key: Hashable {
        let service: String
        let account: String
    }

    private let lock = NSLock()
    private var items: [Key: Data] = [:]

    private func service(_ query: [String: Any]) -> String {
        query[kSecAttrService as String] as? String ?? ""
    }

    private func account(_ query: [String: Any]) -> String? {
        query[kSecAttrAccount as String] as? String
    }

    func add(_ attributes: [String: Any]) -> OSStatus {
        guard let data = attributes[kSecValueData as String] as? Data,
              let account = account(attributes) else {
            return errSecParam
        }
        lock.lock()
        defer { lock.unlock() }
        items[Key(service: service(attributes), account: account)] = data
        return errSecSuccess
    }

    func copyMatching(_ query: [String: Any]) -> (status: OSStatus, data: Data?) {
        guard let account = account(query) else { return (errSecItemNotFound, nil) }
        lock.lock()
        defer { lock.unlock() }
        if let data = items[Key(service: service(query), account: account)] {
            return (errSecSuccess, data)
        }
        return (errSecItemNotFound, nil)
    }

    func delete(_ query: [String: Any]) -> OSStatus {
        lock.lock()
        defer { lock.unlock() }
        let svc = service(query)
        if let account = account(query) {
            return items.removeValue(forKey: Key(service: svc, account: account)) != nil
                ? errSecSuccess : errSecItemNotFound
        }
        // No account supplied → delete every item under the service, matching
        // `deleteAllCredentials`.
        let before = items.count
        items = items.filter { $0.key.service != svc }
        return items.count < before ? errSecSuccess : errSecItemNotFound
    }

    /// Decodes a stored credentials blob so tests can assert on its contents.
    func storedSalt(forHashedEmail hashedEmail: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let data = items[Key(service: "com.recipefinder.credentials", account: hashedEmail)],
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json["salt"] as? String
    }
}

private func makeSUT() -> (SecureCredentialManager, InMemoryKeychainStore) {
    let keychain = InMemoryKeychainStore()
    // Reduced rounds keep the suite fast; correctness is independent of count.
    let sut = SecureCredentialManager(keychain: keychain, hasher: PasswordHasher(rounds: 2_000))
    return (sut, keychain)
}

@Suite("SecureCredentialManager — credential lifecycle")
struct SecureCredentialManagerTests {

    @Test("Correct password verifies after saving")
    func saveThenVerify_correctPassword_succeeds() {
        let (sut, _) = makeSUT()
        #expect(sut.saveCredentials(email: "a@b.com", password: "Secret1!", fullName: "Ann Lee"))
        #expect(sut.verifyCredentials(email: "a@b.com", password: "Secret1!"))
    }

    @Test("Wrong password does not verify")
    func verify_wrongPassword_fails() {
        let (sut, _) = makeSUT()
        _ = sut.saveCredentials(email: "a@b.com", password: "Secret1!", fullName: "Ann")
        #expect(!sut.verifyCredentials(email: "a@b.com", password: "Wrong9!"))
    }

    @Test("Unknown email does not verify")
    func verify_unknownEmail_fails() {
        let (sut, _) = makeSUT()
        #expect(!sut.verifyCredentials(email: "nobody@b.com", password: "Secret1!"))
    }

    @Test("Stored name is retrievable, unknown email returns nil")
    func getUserInfo_returnsStoredName() {
        let (sut, _) = makeSUT()
        _ = sut.saveCredentials(email: "a@b.com", password: "Secret1!", fullName: "Ann Lee")
        let info = sut.getUserInfo(email: "a@b.com")
        #expect(info?.email == "a@b.com")
        #expect(info?.fullName == "Ann Lee")
        #expect(sut.getUserInfo(email: "nobody@b.com") == nil)
    }

    @Test("Re-saving keeps a stable user id and updates the password")
    func reSave_keepsStableUserId_andUpdatesPassword() {
        let (sut, _) = makeSUT()
        _ = sut.saveCredentials(email: "a@b.com", password: "First1!", fullName: "Ann")
        let firstId = sut.getUserId(email: "a@b.com")
        #expect(firstId != nil)

        _ = sut.saveCredentials(email: "a@b.com", password: "Second2!", fullName: "Ann")
        #expect(sut.getUserId(email: "a@b.com") == firstId)
        #expect(sut.verifyCredentials(email: "a@b.com", password: "Second2!"))
        #expect(!sut.verifyCredentials(email: "a@b.com", password: "First1!"))
    }

    @Test("Each save generates a fresh salt")
    func saveCredentials_usesFreshSaltEachTime() {
        let (sut, keychain) = makeSUT()
        let hashedEmail = sut.hashEmail("a@b.com")

        _ = sut.saveCredentials(email: "a@b.com", password: "First1!", fullName: "Ann")
        let salt1 = keychain.storedSalt(forHashedEmail: hashedEmail)
        _ = sut.saveCredentials(email: "a@b.com", password: "First1!", fullName: "Ann")
        let salt2 = keychain.storedSalt(forHashedEmail: hashedEmail)

        #expect(salt1 != nil)
        #expect(salt1 != salt2)
    }

    @Test("Deleting credentials removes the account")
    func deleteCredentials_removesAccount() {
        let (sut, _) = makeSUT()
        _ = sut.saveCredentials(email: "a@b.com", password: "Secret1!", fullName: "Ann")
        #expect(sut.deleteCredentials(email: "a@b.com"))
        #expect(!sut.verifyCredentials(email: "a@b.com", password: "Secret1!"))
        #expect(sut.getUserInfo(email: "a@b.com") == nil)
        #expect(sut.getUserId(email: "a@b.com") == nil)
    }

    @Test("Deleting credentials that do not exist is tolerated")
    func deleteCredentials_missing_returnsTrue() {
        let (sut, _) = makeSUT()
        #expect(sut.deleteCredentials(email: "ghost@b.com"))
    }

    @Test("Delete-all clears every stored account")
    func deleteAllCredentials_removesEveryAccount() {
        let (sut, _) = makeSUT()
        _ = sut.saveCredentials(email: "a@b.com", password: "Secret1!", fullName: "Ann")
        _ = sut.saveCredentials(email: "c@d.com", password: "Secret2!", fullName: "Cal")
        #expect(sut.deleteAllCredentials())
        #expect(sut.getUserInfo(email: "a@b.com") == nil)
        #expect(sut.getUserInfo(email: "c@d.com") == nil)
    }

    // MARK: - Email hashing

    @Test("Email hash is case-insensitive and deterministic")
    func hashEmail_isCaseInsensitiveAndDeterministic() {
        let (sut, _) = makeSUT()
        #expect(sut.hashEmail("USER@X.com") == sut.hashEmail("user@x.com"))
        #expect(sut.hashEmail("a@x.com") != sut.hashEmail("b@x.com"))
        #expect(sut.hashEmail("a@x.com").count == 64)
    }

}

@Suite("PasswordHasher")
struct PasswordHasherTests {

    @Test("Valid input produces a 64-character hex hash")
    func hash_validInput_returns64HexChars() {
        let hasher = PasswordHasher(rounds: 2_000)
        let salt = hasher.generateSalt()
        let hash = hasher.hash(password: "Secret1!", salt: salt)
        #expect(hash?.count == 64)
    }

    @Test("Same password and salt hash deterministically")
    func hash_sameSalt_deterministic() {
        let hasher = PasswordHasher(rounds: 2_000)
        let salt = hasher.generateSalt()
        #expect(hasher.hash(password: "Secret1!", salt: salt) == hasher.hash(password: "Secret1!", salt: salt))
    }

    @Test("Different salts produce different hashes")
    func hash_differentSalt_differs() {
        let hasher = PasswordHasher(rounds: 2_000)
        let a = hasher.hash(password: "Secret1!", salt: hasher.generateSalt())
        let b = hasher.hash(password: "Secret1!", salt: hasher.generateSalt())
        #expect(a != b)
    }

    @Test("A valid password never hashes to empty")
    func hash_neverEmptyForValidPassword() {
        let hasher = PasswordHasher(rounds: 2_000)
        let hash = hasher.hash(password: "Secret1!", salt: hasher.generateSalt())
        #expect(hash?.isEmpty == false)
    }

    @Test("Invalid hex salt yields nil, not an empty hash", arguments: ["xyz", "zz", "abc", "12g4"])
    func hash_invalidHexSalt_returnsNil(salt: String) {
        let hasher = PasswordHasher(rounds: 2_000)
        #expect(hasher.hash(password: "Secret1!", salt: salt) == nil)
    }

    @Test("Generated salt is 64 hex chars and unique per call")
    func generateSalt_is64Hex_andUnique() {
        let hasher = PasswordHasher()
        let s1 = hasher.generateSalt()
        let s2 = hasher.generateSalt()
        #expect(s1.count == 64)
        #expect(s1 != s2)
    }
}

@Suite("Data(hexString:)")
struct DataHexStringTests {

    @Test("Round-trips a valid hex string")
    func roundTrip() throws {
        let data = try #require(Data(hexString: "48656c6c6f"))
        #expect(String(data: data, encoding: .utf8) == "Hello")
    }

    @Test("Odd-length input returns nil", arguments: ["abc", "1", "12345"])
    func oddLength_returnsNil(hex: String) {
        #expect(Data(hexString: hex) == nil)
    }

    @Test("Non-hex characters return nil", arguments: ["zz", "12g4", "!!"])
    func nonHex_returnsNil(hex: String) {
        #expect(Data(hexString: hex) == nil)
    }
}
