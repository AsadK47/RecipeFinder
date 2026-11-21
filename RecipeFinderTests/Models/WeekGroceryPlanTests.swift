import Testing
import Foundation
@testable import RecipeFinder

@Suite("WeekGroceryPlan")
struct WeekGroceryPlanTests {

    private func item(_ name: String) -> WeekShoppingSummary.Item {
        WeekShoppingSummary.Item(name: name, quantity: 1, unit: "")
    }

    private func summary(_ names: [String], meals: Int = 2, missing: [String] = []) -> WeekShoppingSummary {
        WeekShoppingSummary(items: names.map(item), mealsCovered: meals, missingRecipeNames: missing)
    }

    @Test("Items already at home are skipped and counted")
    func skipsKitchenItems() {
        let plan = WeekGroceryPlan(summary: summary(["Onion", "Rice", "Chicken"]), kitchenNames: ["rice"])

        #expect(plan.candidates.map(\.name) == ["Onion", "Chicken"])
        #expect(plan.skippedInKitchen == 1)
        #expect(plan.mealsCovered == 2)
    }

    @Test("Kitchen names match after normalising, not exact text")
    func matchesNormalisedNames() {
        let plan = WeekGroceryPlan(summary: summary(["Rice", "Onion"]), kitchenNames: ["  RICE "])

        #expect(plan.candidates.map(\.name) == ["Onion"])
        #expect(plan.skippedInKitchen == 1)
    }

    @Test("Add button counts items, singular and plural")
    func addButtonCopy() {
        let one = WeekGroceryPlan(summary: summary(["Onion"], meals: 1), kitchenNames: [])
        #expect(one.addButtonTitle == "Add 1 item")

        let many = WeekGroceryPlan(summary: summary(["Onion", "Rice", "Egg"], meals: 3), kitchenNames: ["egg"])
        #expect(many.addButtonTitle == "Add 2 items")
    }

    // MARK: - What's already on the list (Groceries writes itself, slice 1)

    private func line(_ name: String, _ quantity: Int, _ unit: String = "") -> WeekShoppingSummary.Item {
        WeekShoppingSummary.Item(name: name, quantity: quantity, unit: unit)
    }

    private func listItem(_ name: String, _ quantity: Int, _ unit: String = "", checked: Bool = false) -> ShoppingListModel {
        ShoppingListModel(name: name, isChecked: checked, quantity: quantity, unit: unit)
    }

    @Test("A line the list already covers in full isn't added again")
    func skipsWhatsOnTheList() {
        let summary = WeekShoppingSummary(items: [line("onion", 2), line("rice", 1)], mealsCovered: 2, missingRecipeNames: [])
        let plan = WeekGroceryPlan(summary: summary, kitchenNames: [], listItems: [listItem("Onion", 2)])

        #expect(plan.candidates == [line("rice", 1)])
        #expect(plan.skippedOnList == 1)
    }

    @Test("A line the list covers in part adds only what's missing")
    func topsUpWhatsShort() {
        let summary = WeekShoppingSummary(items: [line("chicken", 500, "g")], mealsCovered: 1, missingRecipeNames: [])
        let plan = WeekGroceryPlan(summary: summary, kitchenNames: [], listItems: [listItem("Chicken", 200, "g")])

        #expect(plan.candidates == [line("chicken", 300, "g")])
        #expect(plan.skippedOnList == 0)
    }

    @Test("Ticked items count as bought, so they aren't asked for again")
    func tickedItemsCount() {
        let summary = WeekShoppingSummary(items: [line("onion", 1)], mealsCovered: 1, missingRecipeNames: [])
        let plan = WeekGroceryPlan(summary: summary, kitchenNames: [], listItems: [listItem("onion", 1, checked: true)])

        #expect(plan.candidates.isEmpty)
    }

    @Test("The same name in another unit is a different line, as on the list")
    func otherUnitIsAnotherLine() {
        let summary = WeekShoppingSummary(items: [line("milk", 500, "ml")], mealsCovered: 1, missingRecipeNames: [])
        let plan = WeekGroceryPlan(summary: summary, kitchenNames: [], listItems: [listItem("Milk", 2, "cups")])

        #expect(plan.candidates == [line("milk", 500, "ml")])
    }

    @Test("Several list lines with the same name and unit add up")
    func listLinesAddUp() {
        let summary = WeekShoppingSummary(items: [line("egg", 6)], mealsCovered: 2, missingRecipeNames: [])
        let plan = WeekGroceryPlan(summary: summary, kitchenNames: [], listItems: [listItem("Egg", 2), listItem("egg", 3)])

        #expect(plan.candidates == [line("egg", 1)])
    }

    @Test("Card detail counts items, meals and what's at home")
    func cardDetail() {
        let one = WeekGroceryPlan(summary: summary(["Onion"], meals: 1), kitchenNames: [])
        #expect(one.cardDetail == "1 item for 1 planned meal")

        let many = WeekGroceryPlan(summary: summary(["Onion", "Rice", "Egg"], meals: 3), kitchenNames: ["egg"])
        #expect(many.cardDetail == "2 items for 3 planned meals · 1 at home")
    }

    @Test("Unit spellings of one thing are one line, so the list's amount is counted once")
    func unitSynonymsAreOneLine() {
        let summary = WeekShoppingSummary(items: [line("flour", 200, "g"), line("flour", 100, "grams")],
                                          mealsCovered: 2, missingRecipeNames: [])
        let plan = WeekGroceryPlan(summary: summary, kitchenNames: [], listItems: [listItem("Flour", 200, "g")])

        #expect(plan.candidates == [line("flour", 100, "g")])
    }

    @Test("A week needing more than a line can hold asks for the most a line holds, once")
    func bigWeeksCapAtWhatALineHolds() {
        let summary = WeekShoppingSummary(items: [line("chicken", 1500, "g")], mealsCovered: 3, missingRecipeNames: [])

        let empty = WeekGroceryPlan(summary: summary, kitchenNames: [], listItems: [])
        #expect(empty.candidates == [line("chicken", WeekGroceryPlan.maxQuantity, "g")])

        let full = WeekGroceryPlan(summary: summary, kitchenNames: [], listItems: [listItem("chicken", 999, "g")])
        #expect(full.candidates.isEmpty)
    }

    @Test("After Not now, the card comes back only when the plan needs something new")
    func notNowHoldsUntilThePlanNeedsMore() {
        let twoThings = WeekShoppingSummary(items: [line("onion", 1), line("rice", 1)], mealsCovered: 2, missingRecipeNames: [])
        let dismissed = WeekGroceryPlan(summary: twoThings, kitchenNames: [], listItems: [])
        #expect(dismissed.needsMore(than: nil))
        #expect(!dismissed.needsMore(than: dismissed))

        // Fewer of the same things (e.g. rice added by hand) → still hidden.
        let fewer = WeekGroceryPlan(summary: twoThings, kitchenNames: [], listItems: [listItem("rice", 1)])
        #expect(!fewer.needsMore(than: dismissed))

        // A newly planned dinner needs something else → the card is back.
        let more = WeekShoppingSummary(items: [line("onion", 1), line("rice", 1), line("lime", 1)], mealsCovered: 3, missingRecipeNames: [])
        #expect(WeekGroceryPlan(summary: more, kitchenNames: [], listItems: []).needsMore(than: dismissed))
        #expect(!WeekGroceryPlan.empty.needsMore(than: nil))
    }

    @MainActor @Test("A top-up for a ticked line puts what's still missing back on To buy")
    func topUpOfATickedLineIsToBuy() {
        let shopping = makeShopping()
        shopping.addItem(name: "Onion", quantity: 1, unit: "", category: nil)
        shopping.toggleItem(at: 0)
        let summary = WeekShoppingSummary(items: [line("onion", 3)], mealsCovered: 1, missingRecipeNames: [])

        WeekGroceryPlan(summary: summary, kitchenNames: [], listItems: shopping.items).add(to: shopping)

        #expect(shopping.items.count == 1)
        #expect(shopping.items.first?.quantity == 2)
        #expect(shopping.items.first?.isChecked == false)
    }

    @Test("Put away moves ticked one-off items, not staples or what's still to buy")
    func putAwayPicksTickedOneOffs() {
        let items = [
            listItem("Onion", 1, checked: true),
            listItem("Rice", 1),
            ShoppingListModel(name: "Milk", isChecked: true, isRecurring: true),
        ]
        #expect(ShoppingListManager.boughtToPutAway(items) == ["Onion"])
    }

    @MainActor @Test("After a shop is put away, the plan doesn't ask for it again")
    func putAwayStopsThePlanAskingAgain() {
        let shopping = makeShopping()
        let kitchen = KitchenInventoryManager(storage: LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard),
                                              kitchenStore: InMemoryKitchenStore())
        let summary = WeekShoppingSummary(items: [line("onion", 2)], mealsCovered: 1, missingRecipeNames: [])
        WeekGroceryPlan(summary: summary, kitchenNames: [], listItems: shopping.items).add(to: shopping)
        shopping.toggleItem(at: 0)

        kitchen.putAway(ShoppingListManager.boughtToPutAway(shopping.items))
        shopping.clearCheckedItems()
        let after = WeekGroceryPlan(summary: summary, kitchenNames: kitchen.items.map(\.name), listItems: shopping.items)

        #expect(shopping.items.isEmpty)
        #expect(kitchen.hasItem("onion"))
        #expect(after.candidates.isEmpty)
    }

    @MainActor @Test("Put away skips what's already at home and blank names")
    func putAwaySkipsDuplicates() {
        let kitchen = KitchenInventoryManager(storage: LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard),
                                              kitchenStore: InMemoryKitchenStore())
        kitchen.putAway(["Onion"])
        kitchen.putAway(["onion ", "  ", "Rice"])

        #expect(kitchen.items.map { $0.name }.sorted() == ["Onion", "Rice"])
    }

    @MainActor
    private func makeShopping() -> ShoppingListManager {
        let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
        return ShoppingListManager(storage: LocalStore(userDefaults: defaults), shoppingListStore: InMemoryShoppingListStore())
    }

    @MainActor @Test("Adding tops the list up to what the plan needs, and adding again changes nothing")
    func addingTwiceNeverDoubles() {
        let shopping = makeShopping()
        shopping.addItem(name: "Onion", quantity: 1, unit: "", category: nil)
        let summary = WeekShoppingSummary(items: [line("onion", 3), line("rice", 1)], mealsCovered: 2, missingRecipeNames: [])

        WeekGroceryPlan(summary: summary, kitchenNames: [], listItems: shopping.items).add(to: shopping)
        let again = WeekGroceryPlan(summary: summary, kitchenNames: [], listItems: shopping.items)
        again.add(to: shopping)

        let quantities = Dictionary(uniqueKeysWithValues: shopping.items.map { ($0.name.lowercased(), $0.quantity) })
        #expect(quantities == ["onion": 3, "rice": 1])
        #expect(again.candidates.isEmpty)
    }

    @Test("Empty plan has nothing to add")
    func emptyPlan() {
        #expect(WeekGroceryPlan.empty.candidates.isEmpty)
    }
}
