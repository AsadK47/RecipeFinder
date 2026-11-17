import Testing
@testable import RecipeFinder

/// Kitchen you can find (owner 2026-11-17): Groceries opens on To buy, At home is one tap away and remembered.
@Suite("GroceriesMode")
struct GroceriesModeTests {

    @Test func opensOnTheShoppingList() {
        #expect(GroceriesMode.defaultMode == .toBuy)
    }

    @Test func sidesReadToBuyThenAtHome() {
        #expect(GroceriesMode.allCases.map(\.title) == ["To buy", "At home"])
    }

    /// The choice is stored under these strings; renaming one would drop a cook back on To buy.
    @Test func storedValuesStayStable() {
        #expect(GroceriesMode.modeKey == "groceries.mode")
        #expect(GroceriesMode.allCases.map(\.rawValue) == ["toBuy", "atHome"])
        #expect(GroceriesMode(rawValue: "atHome") == .atHome)
    }

    @Test func searchFieldSaysWhereItAdds() {
        #expect(GroceriesMode.toBuy.searchPlaceholder == "Add or search groceries…")
        #expect(GroceriesMode.atHome.searchPlaceholder == "Add to your kitchen…")
        #expect(GroceriesMode.toBuy.listName == "groceries")
        #expect(GroceriesMode.atHome.listName == "kitchen")
    }

    @Test(arguments: [
        (GroceriesMode.toBuy, true, false, true),
        (.toBuy, false, false, false),
        (.toBuy, true, true, false),
        (.atHome, true, false, false),
        (.atHome, false, false, false)
    ])
    func storeFilterBelongsToTheShoppingList(mode: GroceriesMode, hasStores: Bool, isSearching: Bool, shows: Bool) {
        #expect(GroceriesMode.showsStoreFilter(mode: mode, hasStores: hasStores, isSearching: isSearching) == shows)
    }

    @Test(arguments: [
        ("Milk", ["milk"], true),
        ("  Eggs ", ["Eggs"], true),
        ("Butter", ["Milk", "Eggs"], false),
        ("Milk", [], false)
    ])
    func knowsWhatIsAlreadyOnTheList(name: String, names: [String], expected: Bool) {
        #expect(GroceriesMode.contains(name, in: names) == expected)
    }

    // MARK: Adding from the header field

    @Test func toBuyAddsToTheShoppingList() {
        #expect(GroceriesMode.toBuy.add("  Milk ", kitchenNames: ["Milk"]) == .shopping("Milk"))
    }

    @Test func atHomeAddsToTheKitchen() {
        #expect(GroceriesMode.atHome.add(" Saffron ", kitchenNames: ["Eggs"]) == .kitchen("Saffron"))
    }

    /// The kitchen add toggles: re-adding a name it already holds must keep that item, not remove it.
    @Test func atHomeKeepsAnItemAlreadyInTheKitchen() {
        #expect(GroceriesMode.atHome.add("eggs", kitchenNames: ["Eggs"]) == .alreadyInKitchen)
    }

    @Test(arguments: GroceriesMode.allCases)
    func blankAddsNothing(mode: GroceriesMode) {
        #expect(mode.add("   ", kitchenNames: []) == .nothing)
    }

    // MARK: Arriving from elsewhere

    /// The expiry reminder is about the kitchen; the groceries reminder and the shopping badge are about the list.
    @Test(arguments: [
        ("expiry", GroceriesMode.atHome),
        ("groceries-reminder", .toBuy),
        (nil, .toBuy)
    ] as [(String?, GroceriesMode)])
    func opensTheSideTheReminderIsAbout(type: String?, side: GroceriesMode) {
        #expect(GroceriesMode.side(openedBy: type) == side)
    }
}
