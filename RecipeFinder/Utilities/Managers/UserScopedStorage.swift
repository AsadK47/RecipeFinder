import Foundation

private let logger = AppLogger.logger(category: "UserScopedStorage")

extension Notification.Name {
    static let userScopeDidChange = Notification.Name("UserScopeDidChange")
}

/// Thread-safe by construction: both stored properties are immutable `let`s and
/// every read/write is delegated to `UserDefaults`, which Apple documents as
/// thread-safe. `@unchecked` is required only because `UserDefaults` isn't itself
/// annotated `Sendable` in the SDK — there is no unsynchronised mutable state here.
final class UserScopedStorage: @unchecked Sendable {
    static let shared = UserScopedStorage()
    
    private let userDefaults: UserDefaults
    private let currentUserKey = "currentUserId"

    private init() {
        self.userDefaults = .standard
    }

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    var currentUserId: String? {
        get {
            userDefaults.string(forKey: currentUserKey)
        }
        set {
            let oldValue = userDefaults.string(forKey: currentUserKey)

            if let newValue = newValue {
                userDefaults.set(newValue, forKey: currentUserKey)
            } else {
                userDefaults.removeObject(forKey: currentUserKey)
            }

            if oldValue != newValue {
                NotificationCenter.default.post(
                    name: .userScopeDidChange,
                    object: nil,
                    userInfo: ["oldUserId": oldValue as Any, "newUserId": newValue as Any]
                )
            }
        }
    }
    
    private func scopedKey(_ key: String) -> String {
        let userId = currentUserId ?? "no_user"
        return "\(userId)_\(key)"
    }
    
    func string(forKey key: String) -> String? {
        userDefaults.string(forKey: scopedKey(key))
    }
    
    func set(_ value: String?, forKey key: String) {
        if let value = value {
            userDefaults.set(value, forKey: scopedKey(key))
        } else {
            userDefaults.removeObject(forKey: scopedKey(key))
        }
    }
    
    func data(forKey key: String) -> Data? {
        userDefaults.data(forKey: scopedKey(key))
    }

    /// Encodes a `Codable` value to JSON and stores it. Unlike a bare `try?`, an
    /// encoding failure is logged at the failure site instead of silently
    /// dropping the write, so lost persistence is diagnosable.
    func setEncodable<T: Encodable>(_ value: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            set(data, forKey: key)
        } catch {
            logger.error("❌ Failed to encode \(String(describing: T.self)) for key \(key): \(error.localizedDescription)")
        }
    }
    
    func set(_ value: Data?, forKey key: String) {
        if let value = value {
            userDefaults.set(value, forKey: scopedKey(key))
        } else {
            userDefaults.removeObject(forKey: scopedKey(key))
        }
    }
    
    func bool(forKey key: String) -> Bool {
        userDefaults.bool(forKey: scopedKey(key))
    }
    
    func set(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: scopedKey(key))
    }
    
    func integer(forKey key: String) -> Int {
        userDefaults.integer(forKey: scopedKey(key))
    }
    
    func set(_ value: Int, forKey key: String) {
        userDefaults.set(value, forKey: scopedKey(key))
    }
    
    func double(forKey key: String) -> Double {
        userDefaults.double(forKey: scopedKey(key))
    }
    
    func set(_ value: Double, forKey key: String) {
        userDefaults.set(value, forKey: scopedKey(key))
    }
    
    func object(forKey key: String) -> Any? {
        userDefaults.object(forKey: scopedKey(key))
    }
    
    func set(_ value: Any?, forKey key: String) {
        if let value = value {
            userDefaults.set(value, forKey: scopedKey(key))
        } else {
            userDefaults.removeObject(forKey: scopedKey(key))
        }
    }
    
    func array(forKey key: String) -> [Any]? {
        userDefaults.array(forKey: scopedKey(key))
    }
    
    func removeObject(forKey key: String) {
        userDefaults.removeObject(forKey: scopedKey(key))
    }
    
    func clearCurrentUserData() {
        guard let userId = currentUserId else { return }
        
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let userKeys = allKeys.filter { $0.hasPrefix("\(userId)_") }
        
        for key in userKeys {
            userDefaults.removeObject(forKey: key)
        }
    }
}
