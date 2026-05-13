import XCTest
@testable import RecipeFinder

final class UserScopedStorageTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!
    private var storage: UserScopedStorage!

    override func setUp() {
        super.setUp()
        suiteName = UUID().uuidString
        defaults = UserDefaults(suiteName: suiteName)!
        storage = UserScopedStorage(userDefaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        storage = nil
        defaults = nil
        super.tearDown()
    }

    // MARK: - currentUserId

    func testCurrentUserId_defaultsToNil() {
        XCTAssertNil(storage.currentUserId)
    }

    func testCurrentUserId_setAndGet() {
        storage.currentUserId = "user123"
        XCTAssertEqual(storage.currentUserId, "user123")
    }

    func testCurrentUserId_setToNil_removesValue() {
        storage.currentUserId = "user123"
        storage.currentUserId = nil
        XCTAssertNil(storage.currentUserId)
    }

    // MARK: - String round-trip

    func testString_roundTrip() {
        storage.currentUserId = "u"
        storage.set("hello", forKey: "greeting")
        XCTAssertEqual(storage.string(forKey: "greeting"), "hello")
    }

    func testString_setNilString_removesValue() {
        storage.currentUserId = "u"
        storage.set("hello", forKey: "greeting")
        storage.set(nil as String?, forKey: "greeting")
        XCTAssertNil(storage.string(forKey: "greeting"))
    }

    func testString_missingKey_returnsNil() {
        storage.currentUserId = "u"
        XCTAssertNil(storage.string(forKey: "no_such_key"))
    }

    // MARK: - User scoping

    func testScoping_differentUsers_haveDifferentValues() {
        storage.currentUserId = "alice"
        storage.set("alice_value", forKey: "name")

        storage.currentUserId = "bob"
        storage.set("bob_value", forKey: "name")

        storage.currentUserId = "alice"
        XCTAssertEqual(storage.string(forKey: "name"), "alice_value")

        storage.currentUserId = "bob"
        XCTAssertEqual(storage.string(forKey: "name"), "bob_value")
    }

    func testScoping_nilUser_usesNoUserPrefix() {
        storage.currentUserId = nil
        storage.set("anon", forKey: "k")
        XCTAssertEqual(storage.string(forKey: "k"), "anon")
    }

    func testScoping_nilAndNamedUser_doNotCollide() {
        storage.currentUserId = nil
        storage.set("anon_value", forKey: "k")

        storage.currentUserId = "u"
        storage.set("user_value", forKey: "k")

        storage.currentUserId = nil
        XCTAssertEqual(storage.string(forKey: "k"), "anon_value")
    }

    // MARK: - Bool

    func testBool_defaultIsFalse() {
        storage.currentUserId = "u"
        XCTAssertFalse(storage.bool(forKey: "flag"))
    }

    func testBool_roundTrip() {
        storage.currentUserId = "u"
        storage.set(true, forKey: "flag")
        XCTAssertTrue(storage.bool(forKey: "flag"))
    }

    // MARK: - Int

    func testInteger_defaultIsZero() {
        storage.currentUserId = "u"
        XCTAssertEqual(storage.integer(forKey: "count"), 0)
    }

    func testInteger_roundTrip() {
        storage.currentUserId = "u"
        storage.set(42, forKey: "count")
        XCTAssertEqual(storage.integer(forKey: "count"), 42)
    }

    // MARK: - Data

    func testData_roundTrip() {
        storage.currentUserId = "u"
        let data = Data([0x01, 0x02, 0x03])
        storage.set(data, forKey: "blob")
        XCTAssertEqual(storage.data(forKey: "blob"), data)
    }

    func testData_setNilData_removesValue() {
        storage.currentUserId = "u"
        storage.set(Data([0x01]), forKey: "blob")
        storage.set(nil as Data?, forKey: "blob")
        XCTAssertNil(storage.data(forKey: "blob"))
    }

    // MARK: - removeObject

    func testRemoveObject_removesStoredString() {
        storage.currentUserId = "u"
        storage.set("value", forKey: "k")
        storage.removeObject(forKey: "k")
        XCTAssertNil(storage.string(forKey: "k"))
    }

    // MARK: - clearCurrentUserData

    func testClearCurrentUserData_removesAllKeysForUser() {
        storage.currentUserId = "user1"
        storage.set("a", forKey: "key1")
        storage.set("b", forKey: "key2")

        storage.clearCurrentUserData()

        XCTAssertNil(storage.string(forKey: "key1"))
        XCTAssertNil(storage.string(forKey: "key2"))
    }

    func testClearCurrentUserData_doesNotAffectOtherUser() {
        storage.currentUserId = "user2"
        storage.set("stays", forKey: "data")

        storage.currentUserId = "user1"
        storage.set("goes", forKey: "data")
        storage.clearCurrentUserData()

        storage.currentUserId = "user2"
        XCTAssertEqual(storage.string(forKey: "data"), "stays")
    }

    func testClearCurrentUserData_withNilUser_doesNotThrow() {
        storage.currentUserId = nil
        XCTAssertNoThrow(storage.clearCurrentUserData())
    }
}
