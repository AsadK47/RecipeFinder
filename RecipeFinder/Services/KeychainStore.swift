import Foundation
import Security

/// Abstraction over the system Keychain so credential storage can use an in-memory fake in tests; queries mirror `SecItem*` attribute dictionaries so the real impl is a thin pass-through.
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
