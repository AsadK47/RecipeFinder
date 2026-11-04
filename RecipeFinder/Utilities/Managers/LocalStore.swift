import Foundation

private let logger = AppLogger.logger(category: "LocalStore")

/// The app's key-value store for managers' persisted state (shopping list, kitchen, badges, profile, seed flags…).
///
/// Every key is namespaced on disk as `"rf.<key>"`. The namespace is what makes `clearAll()` safe: Reset removes only
/// keys this store wrote, never unrelated defaults (global `@AppStorage` settings like `appTheme`, system or SDK keys).
/// Chosen over an explicit allow-list because a new manager key is covered automatically — an allow-list silently
/// misses keys someone forgets to register.
///
/// Thread-safe by construction (immutable `let`s delegating to the thread-safe `UserDefaults`); `@unchecked` only
/// because `UserDefaults` isn't SDK-`Sendable` — no unsynchronised mutable state here.
final class LocalStore: @unchecked Sendable {
    static let shared = LocalStore(userDefaults: .standard)

    /// On-disk namespace for every key this store owns.
    static let keyPrefix = "rf."

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    private func storedKey(_ key: String) -> String {
        Self.keyPrefix + key
    }

    func string(forKey key: String) -> String? {
        userDefaults.string(forKey: storedKey(key))
    }

    func set(_ value: String?, forKey key: String) {
        set(value as Any?, forKey: key)
    }

    func data(forKey key: String) -> Data? {
        userDefaults.data(forKey: storedKey(key))
    }

    func set(_ value: Data?, forKey key: String) {
        set(value as Any?, forKey: key)
    }

    /// Encodes a `Codable` to JSON and stores it, logging encode failures at the site (unlike a bare `try?`) so lost writes are diagnosable.
    func setEncodable<T: Encodable>(_ value: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            set(data, forKey: key)
        } catch {
            logger.error("❌ Failed to encode \(String(describing: T.self)) for key \(key): \(error.localizedDescription)")
        }
    }

    func bool(forKey key: String) -> Bool {
        userDefaults.bool(forKey: storedKey(key))
    }

    func set(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: storedKey(key))
    }

    func integer(forKey key: String) -> Int {
        userDefaults.integer(forKey: storedKey(key))
    }

    func set(_ value: Int, forKey key: String) {
        userDefaults.set(value, forKey: storedKey(key))
    }

    func double(forKey key: String) -> Double {
        userDefaults.double(forKey: storedKey(key))
    }

    func set(_ value: Double, forKey key: String) {
        userDefaults.set(value, forKey: storedKey(key))
    }

    func object(forKey key: String) -> Any? {
        userDefaults.object(forKey: storedKey(key))
    }

    /// nil removes the key, so optional setters never store an `NSNull`.
    func set(_ value: Any?, forKey key: String) {
        if let value {
            userDefaults.set(value, forKey: storedKey(key))
        } else {
            userDefaults.removeObject(forKey: storedKey(key))
        }
    }

    func array(forKey key: String) -> [Any]? {
        userDefaults.array(forKey: storedKey(key))
    }

    func removeObject(forKey key: String) {
        userDefaults.removeObject(forKey: storedKey(key))
    }

    /// Removes every key this store owns (the `rf.` namespace) and nothing else.
    func clearAll() {
        let ownedKeys = userDefaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(Self.keyPrefix) }
        for key in ownedKeys {
            userDefaults.removeObject(forKey: key)
        }
    }
}
