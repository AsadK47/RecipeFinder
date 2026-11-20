import Testing
import Foundation
@testable import RecipeFinder

@Suite("ShopTrip")
struct ShopTripTests {
    private func item(_ name: String, _ category: String, checked: Bool = false, staple: Bool = false,
                      quantity: Int = 1, unit: String = "", stores: [String] = []) -> ShoppingListModel {
        ShoppingListModel(name: name, isChecked: checked, quantity: quantity, unit: unit, category: category,
                          stores: stores, isRecurring: staple)
    }

    @Test("Still to get is the unticked items in aisle order; ticked ones are in the basket")
    func splitsToGetAndBasket() {
        let items = [item("Milk", "Dairy & Eggs"), item("Onion", "Produce", checked: true), item("Apples", "Produce")]
        let trip = ShopTrip(items: items, store: nil)
        let expectedOrder = ShoppingListGrouping.grouped(items).flatMap { $0.value }.filter { !$0.isChecked }.map { $0.name }

        #expect(trip.toGet.map { $0.name } == expectedOrder)
        #expect(Set(trip.toGet.map { $0.name }) == ["Milk", "Apples"])
        #expect(trip.inBasket.map { $0.name } == ["Onion"])
    }

    @Test("In a store, items set to another store stay off the trip")
    func storeFilterHidesOtherStores() {
        let items = [item("Milk", "Dairy & Eggs", stores: ["Corner shop"]), item("Rice", "Pantry"),
                     item("Tofu", "Produce", stores: ["Market"])]
        let trip = ShopTrip(items: items, store: "Market")

        #expect(Set(trip.toGet.map { $0.name }) == ["Rice", "Tofu"])
        #expect(trip.total == 2)
    }

    @Test("The trip is done only once everything is in the basket")
    func doneWhenAllTicked() {
        #expect(!ShopTrip(items: [], store: nil).isDone)
        #expect(!ShopTrip(items: [item("Milk", "Dairy & Eggs"), item("Rice", "Pantry", checked: true)], store: nil).isDone)
        #expect(ShopTrip(items: [item("Rice", "Pantry", checked: true)], store: nil).isDone)
    }

    @Test("Progress says how much is in the basket")
    func progressText() {
        let trip = ShopTrip(items: [item("Milk", "Dairy & Eggs"), item("Rice", "Pantry", checked: true),
                                    item("Oats", "Pantry")], store: nil)
        #expect(trip.progressText == "1 of 3 in the basket")
    }

    @Test("Done says how many go At home; staples stay on the list so they aren't counted", arguments: [
        ([false, false], "Done"),
        ([true, false], "Done · put 1 away"),
        ([true, true], "Done · put 2 away"),
    ])
    func doneTitleCountsOneOffs(ticked: [Bool], expected: String) {
        let items = [item("Onion", "Produce", checked: ticked[0]), item("Rice", "Pantry", checked: ticked[1]),
                     item("Milk", "Dairy & Eggs", checked: true, staple: true)]
        #expect(ShopTrip(items: items, store: nil).doneTitle == expected)
    }

    @Test("A row shows the amount with its unit, so 200 g doesn't read as 200 items")
    func amountShowsUnit() {
        #expect(ShopTrip.amount(item("Flour", "Pantry", quantity: 200, unit: "g")) == "200 g")
        #expect(ShopTrip.amount(item("Lemon", "Produce", quantity: 2)) == "2")
    }

    @MainActor @Test("Done puts the basket At home and off the list; staples and what's still to get stay")
    func finishPutsTheBasketAway() {
        let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
        let shopping = ShoppingListManager(storage: LocalStore(userDefaults: defaults), shoppingListStore: InMemoryShoppingListStore())
        let kitchen = KitchenInventoryManager(storage: LocalStore(userDefaults: defaults), kitchenStore: InMemoryKitchenStore())
        shopping.addItem(name: "Onion")
        shopping.addItem(name: "Rice")
        shopping.addItem(name: "Milk")
        func index(_ name: String) -> Int { shopping.items.firstIndex { $0.name == name } ?? Int.max }
        shopping.toggleRecurring(at: index("Milk"))
        shopping.toggleItem(at: index("Onion"))
        shopping.toggleItem(at: index("Milk"))
        #expect(shopping.items.count == 3)

        ShopTrip.putAwayBasket(shopping: shopping, kitchen: kitchen)

        #expect(kitchen.hasItem("onion"))
        #expect(!kitchen.hasItem("milk"))
        #expect(!kitchen.hasItem("rice"))
        #expect(shopping.items.map { $0.name }.sorted() == ["Milk", "Rice"])
        #expect(shopping.items.allSatisfy { !$0.isChecked })
    }
}

@MainActor
@Suite("ScreenAwakeHold")
struct ScreenAwakeHoldTests {
    private final class FakeScreen {
        var idleTimerDisabled: Bool
        init(_ value: Bool) { idleTimerDisabled = value }
    }

    private func hold(_ screen: FakeScreen) -> ScreenAwakeHold {
        ScreenAwakeHold(read: { screen.idleTimerDisabled }, write: { screen.idleTimerDisabled = $0 })
    }

    @Test("Holding keeps the screen awake, and letting go restores what it was", arguments: [false, true])
    func restoresWhatItWas(before: Bool) {
        let screen = FakeScreen(before)
        let awake = hold(screen)

        awake.begin()
        #expect(screen.idleTimerDisabled)
        awake.end()
        #expect(screen.idleTimerDisabled == before)
    }

    @Test("Holding twice still restores the original, not the held value")
    func beginTwiceRestoresOriginal() {
        let screen = FakeScreen(false)
        let awake = hold(screen)

        awake.begin()
        awake.begin()
        awake.end()

        #expect(!screen.idleTimerDisabled)
    }

    @Test("Letting go without holding changes nothing")
    func endWithoutBeginDoesNothing() {
        let screen = FakeScreen(true)
        hold(screen).end()
        #expect(screen.idleTimerDisabled)
    }
}
