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
        let aisles = ShoppingListGrouping.grouped(items).map { $0.key }

        #expect(trip.toGet.map { $0.name } == trip.rows.filter { !$0.isChecked }.map { $0.name })
        #expect(Set(trip.toGet.map { $0.name }) == ["Milk", "Apples"])
        #expect(trip.inBasket.map { $0.name } == ["Onion"])
        #expect(trip.rows.map { $0.category }.reduce(into: [String]()) { if $0.last != $1 { $0.append($1) } } == aisles)
    }

    @Test("Ticking a row leaves it where it was, so the next row doesn't slide under the thumb")
    func tickKeepsRowInPlace() {
        let before = [item("Onion", "Produce"), item("Apples", "Produce"), item("Carrots", "Produce")]
        var after = before
        after[0].isChecked = true

        #expect(ShopTrip(items: before, store: nil).rows.map { $0.name } == ["Apples", "Carrots", "Onion"])
        #expect(ShopTrip(items: after, store: nil).rows.map { $0.name } == ["Apples", "Carrots", "Onion"])
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

    @Test("More than one of a count unit reads as a plural; weights, volumes and spoons stay as they are",
          arguments: [
              (16, "clove", "16 cloves"), (2, "cup", "2 cups"), (4, "handful", "4 handfuls"), (3, "pinch", "3 pinches"),
              (2, "bunch", "2 bunches"), (2, "box", "2 boxes"), (2, "leaf", "2 leaves"), (2, "Can", "2 Cans"),
              (1, "clove", "1 clove"), (1, "cup", "1 cup"), (3, "cups", "3 cups"),
              (454, "g", "454 g"), (2, "tbsp", "2 tbsp"), (2, "lb", "2 lb"), (500, "ml", "500 ml"),
          ])
    func amountPluralisesCountUnits(quantity: Int, unit: String, expected: String) {
        #expect(ShopTrip.amount(item("Garlic", "Produce", quantity: quantity, unit: unit)) == expected)
    }

    @Test("Same-name items share one row whose amount joins their units; same units add up")
    func sameNameItemsMerge() {
        let items = [item("Carrots", "Produce", quantity: 454, unit: "g"), item("Onion", "Produce"),
                     item("carrots ", "Produce", quantity: 2, unit: "cups"), item("Milk", "Dairy & Eggs", quantity: 1, unit: "cup"),
                     item("Milk", "Dairy & Eggs", quantity: 2, unit: "cups")]
        let trip = ShopTrip(items: items, store: nil)
        let carrots = trip.rows.first { $0.name == "Carrots" }
        let milk = trip.rows.first { $0.name == "Milk" }

        #expect(trip.rows.count == 3)
        #expect(trip.total == 3)
        #expect(carrots?.amount == "454 g + 2 cups")
        #expect(carrots?.items.count == 2)
        #expect(milk?.amount == "3 cups")
        #expect(trip.rows.first { $0.name == "Onion" }?.amount == "1")
    }

    @Test("A merged row is in the basket only once every item in it is ticked; a tap flips what's left, then all")
    func mergedRowTicksTogether() {
        let grams = item("Carrots", "Produce", quantity: 454, unit: "g")
        let cups = item("Carrots", "Produce", checked: true, quantity: 2, unit: "cups")
        let partly = ShopTrip(items: [grams, cups], store: nil)

        #expect(partly.toGet.count == 1)
        #expect(partly.inBasket.isEmpty)
        #expect(partly.rows.first?.idsToToggle == [grams.id])
        #expect(partly.progressText == "0 of 1 in the basket")

        var both = grams
        both.isChecked = true
        let ticked = ShopTrip(items: [both, cups], store: nil)
        #expect(ticked.isDone)
        #expect(ticked.progressText == "1 of 1 in the basket")
        #expect(Set(ticked.rows.first?.idsToToggle ?? []) == [grams.id, cups.id])
        #expect(ticked.basketIDs == [grams.id, cups.id])
        #expect(ticked.doneTitle == "Done · put 1 away")
    }

    @Test("Ticking the rest of a partly ticked row keeps its id and amount, so it doesn't jump under the thumb")
    func mergedRowKeepsIdentityAsTicked() {
        let grams = item("Carrots", "Produce", checked: true, quantity: 454, unit: "g")
        let cups = item("Carrots", "Produce", quantity: 2, unit: "cups")
        var cupsTicked = cups
        cupsTicked.isChecked = true
        let before = ShopTrip(items: [grams, cups], store: nil).rows.first
        let after = ShopTrip(items: [grams, cupsTicked], store: nil).rows.first

        #expect(before?.id == grams.id)
        #expect(after?.id == grams.id)
        #expect(before?.amount == "454 g + 2 cups")
        #expect(after?.amount == "454 g + 2 cups")
    }

    @Test("Items with different names stay on their own rows")
    func differentNamesStayApart() {
        let trip = ShopTrip(items: [item("Lemon", "Produce"), item("Lemon Juice", "Produce")], store: nil)
        #expect(trip.rows.count == 2)
        #expect(Set(trip.rows.map { $0.name }) == ["Lemon", "Lemon Juice"])
    }

    @MainActor @Test("Done in one store puts away only that store's basket; other stores' ticks stay ticked")
    func finishInAStoreLeavesOtherStores() {
        let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
        let shopping = ShoppingListManager(storage: LocalStore(userDefaults: defaults), shoppingListStore: InMemoryShoppingListStore())
        let kitchen = KitchenInventoryManager(storage: LocalStore(userDefaults: defaults), kitchenStore: InMemoryKitchenStore())
        shopping.addItem(name: "Bread")
        shopping.addItem(name: "Rice")
        func index(_ name: String) -> Int { shopping.items.firstIndex { $0.name == name } ?? Int.max }
        let breadID = shopping.items[index("Bread")].id
        shopping.setStore("Corner shop", assigned: true, forItemIDs: [breadID])
        shopping.toggleItem(at: index("Bread"))
        shopping.toggleItem(at: index("Rice"))
        let trip = ShopTrip(items: shopping.items, store: "Market")

        shopping.putAway(trip.basketIDs, into: kitchen)

        #expect(trip.doneTitle == "Done · put 1 away")
        #expect(kitchen.hasItem("rice"))
        #expect(!kitchen.hasItem("bread"))
        #expect(shopping.items.map { $0.name } == ["Bread"])
        #expect(shopping.items.first?.isChecked == true)
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

        shopping.putAway(ShopTrip(items: shopping.items, store: nil).basketIDs, into: kitchen)

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

    @Test("Leaving the app restores the screen; coming back holds it awake again", arguments: [false, true])
    func sceneRoundTripReholds(before: Bool) {
        let screen = FakeScreen(before)
        let awake = hold(screen)
        awake.begin()

        awake.sceneChanged(isActive: false)
        #expect(screen.idleTimerDisabled == before)
        screen.idleTimerDisabled = false // iOS may reset it while the app is away
        awake.sceneChanged(isActive: true)
        #expect(screen.idleTimerDisabled)
        awake.end()
        #expect(screen.idleTimerDisabled == before)
    }

    @Test("Closing after the app went away and came back restores the value from before the screen opened")
    func sceneChangesKeepTheOriginal() {
        let screen = FakeScreen(true) // Settings' Keep Screen Awake is on
        let awake = hold(screen)
        awake.begin()

        awake.sceneChanged(isActive: false)
        screen.idleTimerDisabled = false
        awake.sceneChanged(isActive: false)
        awake.sceneChanged(isActive: true)
        awake.sceneChanged(isActive: false)
        awake.sceneChanged(isActive: true)
        awake.end()

        #expect(screen.idleTimerDisabled)
    }

    @Test("The app coming back while nothing holds the screen changes nothing", arguments: [false, true])
    func sceneChangeWithoutHoldDoesNothing(isActive: Bool) {
        let screen = FakeScreen(false)
        hold(screen).sceneChanged(isActive: isActive)
        #expect(!screen.idleTimerDisabled)
    }

    @Test("Letting go without holding changes nothing")
    func endWithoutBeginDoesNothing() {
        let screen = FakeScreen(true)
        hold(screen).end()
        #expect(screen.idleTimerDisabled)
    }
}

@MainActor
@Suite("KeepAwakeSetting")
struct KeepAwakeSettingTests {
    private final class FakeScreen {
        var idleTimerDisabled = false
    }

    private func setting(_ screen: FakeScreen) -> KeepAwakeSetting {
        KeepAwakeSetting(write: { screen.idleTimerDisabled = $0 })
    }

    @Test("Turning the switch on keeps the screen awake, turning it off lets it sleep")
    func switchWritesItsValue() {
        let screen = FakeScreen()
        let keepAwake = setting(screen)

        keepAwake.switched(on: true)
        #expect(screen.idleTimerDisabled)
        keepAwake.switched(on: false)
        #expect(!screen.idleTimerDisabled)
    }

    @Test("Opening the app with the switch on keeps the screen awake")
    func appActiveWithSwitchOn() {
        let screen = FakeScreen()
        setting(screen).appBecameActive(settingOn: true)
        #expect(screen.idleTimerDisabled)
    }

    @Test("Opening the app with the switch off never undoes cooking or the shop keeping it awake")
    func appActiveWithSwitchOffLeavesHoldsAlone() {
        let screen = FakeScreen()
        screen.idleTimerDisabled = true // cooking mode or the shop is holding it
        setting(screen).appBecameActive(settingOn: false)
        #expect(screen.idleTimerDisabled)
    }

    @Test("Leaving cooking or the shop keeps the screen awake when the switch is on")
    func leavingAHoldKeepsTheSetting() {
        let screen = FakeScreen()
        let keepAwake = setting(screen)
        let hold = ScreenAwakeHold(read: { screen.idleTimerDisabled }, write: { screen.idleTimerDisabled = $0 })

        keepAwake.appBecameActive(settingOn: true)
        hold.begin()
        hold.end()

        #expect(screen.idleTimerDisabled)
    }
}
