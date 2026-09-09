import Foundation
import Security

/// Abstraction over the system Keychain so credential storage can be exercised
/// against an in-memory fake in tests instead of the real, device-global
/// Keychain (which is shared process state and unavailable in some CI hosts).
///
/// Queries use the same `[String: Any]` attribute dictionaries that `SecItem*`
/// expects, so the real implementation is a thin pass-through.
protocol KeychainStore: Sendable {
    func add(_ attributes: [String: Any]) -> OSStatus
    func copyMatching(_ query: [String: Any]) -> (status: OSStatus, data: Data?)
    func delete(_ query: [String: Any]) -> OSStatus
}

/// Real Keychain backed by `SecItem*`.
struct SystemKeychainStore: KeychainStore {
    func add(_ attributes: [String: Any]) -> OSStatus {
        SecItemAdd(attributes as CFDictionary, nil)
    }

    func copyMatching(_ query: [String: Any]) -> (status: OSStatus, data: Data?) {
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return (status, result as? Data)
    }

    func delete(_ query: [String: Any]) -> OSStatus {
        SecItemDelete(query as CFDictionary)
    }
}
