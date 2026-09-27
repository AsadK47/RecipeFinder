import Testing
import Foundation
@testable import RecipeFinder

/// `UserScopedStorage` contract (per-user key-prefixing; a regression here leaks data between accounts): locks down scoping, typed accessors, scope-change notification, and targeted clear.
/// Each test uses a throwaway `UserDefaults(suiteName:)` and a UUID-unique account id so the shared `NotificationCenter` can't cross-talk with parallel tests.
@MainActor
@Suite struct UserScopedStorageTests {

    private func freshDefaults() -> UserDefaults {
        UserDefaults(suiteName: UUID().uuidString)!
    }

    // MARK: - currentUserId

    @Test func currentUserId_startsNil_roundTrips_andRemovesOnNil() {
        let defaults = freshDefaults()
        let storage = UserScopedStorage(userDefaults: defaults)

        #expect(storage.currentUserId == nil)

        storage.currentUserId = "userA"
        #expect(storage.currentUserId == "userA")
        #expect(defaults.string(forKey: "currentUserId") == "userA")

        storage.currentUserId = nil
        #expect(storage.currentUserId == nil)
        #expect(defaults.object(forKey: "currentUserId") == nil)
    }

    // MARK: - Key scoping

    @Test func value_isStoredUnderUserPrefixedKey() {
        let defaults = freshDefaults()
        let storage = UserScopedStorage(userDefaults: defaults)
        storage.currentUserId = "userA"

        storage.set("value", forKey: "greeting")

        #expect(defaults.string(forKey: "userA_greeting") == "value")
    }

    @Test func value_isScopedToNoUserSentinel_whenSignedOut() {
        let defaults = freshDefaults()
        let storage = UserScopedStorage(userDefaults: defaults)
        // currentUserId is nil.
        storage.set("anon", forKey: "greeting")

        #expect(defaults.string(forKey: "no_user_greeting") == "anon")
    }

    @Test func values_areIsolatedBetweenUsers() {
        let defaults = freshDefaults()
        let storage = UserScopedStorage(userDefaults: defaults)

        storage.currentUserId = "userA"
        storage.set("A's data", forKey: "note")

        // Switching accounts hides A's data entirely.
        storage.currentUserId = "userB"
        #expect(storage.string(forKey: "note") == nil)
        storage.set("B's data", forKey: "note")

        // Switching back restores A's data untouched.
        storage.currentUserId = "userA"
        #expect(storage.string(forKey: "note") == "A's data")
    }

    @Test func signedOutData_isInvisibleToSignedInUser() {
        let defaults = freshDefaults()
        let storage = UserScopedStorage(userDefaults: defaults)

        storage.set("anon", forKey: "note")          // stored under no_user
        storage.currentUserId = "userA"
        #expect(storage.string(forKey: "note") == nil)

        storage.currentUserId = nil
        #expect(storage.string(forKey: "note") == "anon")
    }

    // MARK: - Typed accessors round-trip

    @Test func string_roundTrips_andNilRemoves() {
        let storage = UserScopedStorage(userDefaults: freshDefaults())
        storage.currentUserId = "userA"

        storage.set("hello", forKey: "k")
        #expect(storage.string(forKey: "k") == "hello")

        storage.set(nil as String?, forKey: "k")
        #expect(storage.string(forKey: "k") == nil)
    }

    @Test func data_roundTrips_andNilRemoves() {
        let storage = UserScopedStorage(userDefaults: freshDefaults())
        storage.currentUserId = "userA"
        let bytes = Data([0x01, 0x02, 0x03])

        storage.set(bytes, forKey: "k")
        #expect(storage.data(forKey: "k") == bytes)

        storage.set(nil as Data?, forKey: "k")
        #expect(storage.data(forKey: "k") == nil)
    }

    @Test func setEncodable_encodesScopesAndRoundTrips() throws {
        struct Item: Codable, Equatable { let id: Int; let name: String }
        let defaults = freshDefaults()
        let storage = UserScopedStorage(userDefaults: defaults)
        storage.currentUserId = "userA"

        let items = [Item(id: 1, name: "a"), Item(id: 2, name: "b")]
        storage.setEncodable(items, forKey: "items")

        // Persisted as JSON under the user-scoped key.
        #expect(defaults.data(forKey: "userA_items") != nil)

        // Decodes back to the original value.
        let stored = try #require(storage.data(forKey: "items"))
        let decoded = try JSONDecoder().decode([Item].self, from: stored)
        #expect(decoded == items)
    }

    @Test func bool_defaultsFalse_andRoundTrips() {
        let storage = UserScopedStorage(userDefaults: freshDefaults())
        storage.currentUserId = "userA"

        #expect(storage.bool(forKey: "flag") == false)
        storage.set(true, forKey: "flag")
        #expect(storage.bool(forKey: "flag") == true)
    }

    @Test func integer_defaultsZero_andRoundTrips() {
        let storage = UserScopedStorage(userDefaults: freshDefaults())
        storage.currentUserId = "userA"

        #expect(storage.integer(forKey: "count") == 0)
        storage.set(42, forKey: "count")
        #expect(storage.integer(forKey: "count") == 42)
    }

    @Test func double_defaultsZero_andRoundTrips() {
        let storage = UserScopedStorage(userDefaults: freshDefaults())
        storage.currentUserId = "userA"

        #expect(storage.double(forKey: "ratio") == 0)
        storage.set(3.5, forKey: "ratio")
        #expect(storage.double(forKey: "ratio") == 3.5)
    }

    @Test func object_roundTrips_andNilRemoves() {
        let storage = UserScopedStorage(userDefaults: freshDefaults())
        storage.currentUserId = "userA"
        let date = Date(timeIntervalSince1970: 1_000_000)

        storage.set(date, forKey: "createdAt")
        #expect(storage.object(forKey: "createdAt") as? Date == date)

        storage.set(nil as Any?, forKey: "createdAt")
        #expect(storage.object(forKey: "createdAt") == nil)
    }

    @Test func array_roundTrips() {
        let storage = UserScopedStorage(userDefaults: freshDefaults())
        storage.currentUserId = "userA"

        storage.set(["a", "b"] as Any?, forKey: "list")
        #expect(storage.array(forKey: "list") as? [String] == ["a", "b"])
    }

    @Test func removeObject_deletesTheValue() {
        let storage = UserScopedStorage(userDefaults: freshDefaults())
        storage.currentUserId = "userA"
        storage.set("hello", forKey: "k")

        storage.removeObject(forKey: "k")

        #expect(storage.string(forKey: "k") == nil)
    }

    // MARK: - clearCurrentUserData

    @Test func clearCurrentUserData_removesOnlyCurrentUsersKeys() {
        let defaults = freshDefaults()
        let storage = UserScopedStorage(userDefaults: defaults)

        storage.currentUserId = "userA"
        storage.set("a1", forKey: "x")
        storage.set("a2", forKey: "y")

        storage.currentUserId = "userB"
        storage.set("b1", forKey: "x")

        // A raw, non-scoped key that must survive.
        defaults.set("keep", forKey: "unscopedKey")

        storage.currentUserId = "userA"
        storage.clearCurrentUserData()

        // A's keys are gone.
        #expect(storage.string(forKey: "x") == nil)
        #expect(storage.string(forKey: "y") == nil)

        // B's keys and the unscoped key are untouched.
        storage.currentUserId = "userB"
        #expect(storage.string(forKey: "x") == "b1")
        #expect(defaults.string(forKey: "unscopedKey") == "keep")
    }

    @Test func clearCurrentUserData_isNoOp_whenSignedOut() {
        let storage = UserScopedStorage(userDefaults: freshDefaults())
        // currentUserId is nil.
        storage.set("anon", forKey: "k")

        storage.clearCurrentUserData()

        #expect(storage.string(forKey: "k") == "anon")
    }

    // MARK: - Scope-change notification

    @Test func changingScope_postsNotification_withOldAndNewIds() async {
        let storage = UserScopedStorage(userDefaults: freshDefaults())
        let a = "A-\(UUID().uuidString)"
        let b = "B-\(UUID().uuidString)"
        storage.currentUserId = a

        await confirmation("posts once carrying both ids") { confirmed in
            let token = NotificationCenter.default.addObserver(
                forName: .userScopeDidChange, object: nil, queue: nil
            ) { note in
                if note.userInfo?["oldUserId"] as? String == a,
                   note.userInfo?["newUserId"] as? String == b {
                    confirmed()
                }
            }
            defer { NotificationCenter.default.removeObserver(token) }

            storage.currentUserId = b
        }
    }

    @Test func settingSameScope_doesNotPost() async {
        let storage = UserScopedStorage(userDefaults: freshDefaults())
        let a = "A-\(UUID().uuidString)"
        storage.currentUserId = a

        await confirmation("no post when unchanged", expectedCount: 0) { confirmed in
            let token = NotificationCenter.default.addObserver(
                forName: .userScopeDidChange, object: nil, queue: nil
            ) { note in
                if note.userInfo?["newUserId"] as? String == a {
                    confirmed()
                }
            }
            defer { NotificationCenter.default.removeObserver(token) }

            storage.currentUserId = a
        }
    }
}
