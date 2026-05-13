import Foundation

final class UserScopedStorage {
    nonisolated(unsafe) static let shared = UserScopedStorage()
    
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
            if let newValue = newValue {
                userDefaults.set(newValue, forKey: currentUserKey)
            } else {
                userDefaults.removeObject(forKey: currentUserKey)
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
