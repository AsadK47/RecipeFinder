import Testing
import Foundation
@testable import RecipeFinder

/// `LocalStore` contract: typed accessors round-trip, every key lives in the `rf.` namespace, and `clearAll()` removes
/// only that namespace (Reset must never wipe unrelated defaults such as global `@AppStorage` settings).
/// Each test uses a throwaway `UserDefaults(suiteName:)` so parallel tests can't cross-talk.
@Suite struct LocalStoreTests {

    private func freshDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: UUID().uuidString))
    }

    // MARK: - Typed accessors round-trip

    @Test func decodable_roundTripsWhatSetEncodableWrote() throws {
        let store = LocalStore(userDefaults: try freshDefaults())
        store.setEncodable(["a", "b"], forKey: "list")
        #expect(store.decodable([String].self, forKey: "list") == ["a", "b"])
        #expect(store.decodable([String].self, forKey: "missing") == nil)
    }

    @Test func decodable_keepsCorruptBlobAside_soTheNextSaveCantDestroyIt() throws {
        let store = LocalStore(userDefaults: try freshDefaults())
        let garbage = Data("not json".utf8)
        store.set(garbage, forKey: "list")

        #expect(store.decodable([String].self, forKey: "list") == nil)
        store.setEncodable([String](), forKey: "list")   // what a manager does next

        #expect(store.data(forKey: "list.corrupt") == garbage)
    }

    @Test func string_roundTrips_andNilRemoves() throws {
        let store = LocalStore(userDefaults: try freshDefaults())

        store.set("hello", forKey: "k")
        #expect(store.string(forKey: "k") == "hello")

        store.set(nil as String?, forKey: "k")
        #expect(store.string(forKey: "k") == nil)
    }

    @Test func data_roundTrips_andNilRemoves() throws {
        let store = LocalStore(userDefaults: try freshDefaults())
        let bytes = Data([0x01, 0x02, 0x03])

        store.set(bytes, forKey: "k")
        #expect(store.data(forKey: "k") == bytes)

        store.set(nil as Data?, forKey: "k")
        #expect(store.data(forKey: "k") == nil)
    }

    @Test func setEncodable_storesJSONUnderNamespacedKey() throws {
        struct Item: Codable, Equatable { let id: Int; let name: String }
        let defaults = try freshDefaults()
        let store = LocalStore(userDefaults: defaults)
        let items = [Item(id: 1, name: "a"), Item(id: 2, name: "b")]

        store.setEncodable(items, forKey: "items")

        #expect(defaults.data(forKey: "rf.items") != nil)
        let stored = try #require(store.data(forKey: "items"))
        #expect(try JSONDecoder().decode([Item].self, from: stored) == items)
    }

    @Test func bool_defaultsFalse_andRoundTrips() throws {
        let store = LocalStore(userDefaults: try freshDefaults())

        #expect(store.bool(forKey: "flag") == false)
        store.set(true, forKey: "flag")
        #expect(store.bool(forKey: "flag") == true)
    }

    @Test func integer_defaultsZero_andRoundTrips() throws {
        let store = LocalStore(userDefaults: try freshDefaults())

        #expect(store.integer(forKey: "count") == 0)
        store.set(42, forKey: "count")
        #expect(store.integer(forKey: "count") == 42)
    }

    @Test func double_defaultsZero_andRoundTrips() throws {
        let store = LocalStore(userDefaults: try freshDefaults())

        #expect(store.double(forKey: "ratio") == 0)
        store.set(3.5, forKey: "ratio")
        #expect(store.double(forKey: "ratio") == 3.5)
    }

    @Test func object_roundTrips_andNilRemoves() throws {
        let store = LocalStore(userDefaults: try freshDefaults())
        let date = Date(timeIntervalSince1970: 1_000_000)

        store.set(date, forKey: "createdAt")
        #expect(store.object(forKey: "createdAt") as? Date == date)

        store.set(nil as Any?, forKey: "createdAt")
        #expect(store.object(forKey: "createdAt") == nil)
    }

    @Test func array_roundTrips() throws {
        let store = LocalStore(userDefaults: try freshDefaults())

        store.set(["a", "b"] as Any?, forKey: "list")
        #expect(store.array(forKey: "list") as? [String] == ["a", "b"])
    }

    @Test func removeObject_deletesTheValue() throws {
        let store = LocalStore(userDefaults: try freshDefaults())
        store.set("hello", forKey: "k")

        store.removeObject(forKey: "k")

        #expect(store.string(forKey: "k") == nil)
    }

    // MARK: - Namespace

    @Test func keysAreStoredUnderTheAppNamespace() throws {
        let defaults = try freshDefaults()
        let store = LocalStore(userDefaults: defaults)

        store.set("v", forKey: "note")

        #expect(defaults.string(forKey: "rf.note") == "v")
        #expect(defaults.object(forKey: "note") == nil)
    }

    // MARK: - clearAll

    @Test func clearAll_removesOwnedKeys_andLeavesUnrelatedDefaults() throws {
        let defaults = try freshDefaults()
        let store = LocalStore(userDefaults: defaults)
        store.set("x", forKey: "a")
        store.set(true, forKey: "b")
        defaults.set("Teal", forKey: "appTheme")   // global @AppStorage-style setting, not owned by the store

        store.clearAll()

        #expect(store.string(forKey: "a") == nil)
        #expect(store.bool(forKey: "b") == false)
        #expect(defaults.string(forKey: "appTheme") == "Teal")
    }
}
