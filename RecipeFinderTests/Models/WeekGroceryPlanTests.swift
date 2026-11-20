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
        #expect(plan.nothingToAddMessage == nil)
    }

    @Test("Kitchen names match after normalising, not exact text")
    func matchesNormalisedNames() {
        let plan = WeekGroceryPlan(summary: summary(["Rice", "Onion"]), kitchenNames: ["  RICE "])

        #expect(plan.candidates.map(\.name) == ["Onion"])
        #expect(plan.skippedInKitchen == 1)
    }

    @Test("Nothing planned says so")
    func nothingPlanned() {
        #expect(WeekGroceryPlan(summary: summary([], meals: 0), kitchenNames: []).nothingToAddMessage
            == "No planned meals to shop for")
    }

    @Test("Planned recipes that were deleted say they couldn't be found")
    func missingRecipes() {
        let plan = WeekGroceryPlan(summary: summary([], meals: 0, missing: ["Gone"]), kitchenNames: [])
        #expect(plan.nothingToAddMessage == "Couldn't find this week's recipes")
    }

    @Test("Everything at home says so, even when recipes are missing")
    func everythingAtHome() {
        let plan = WeekGroceryPlan(summary: summary(["Rice"], missing: ["Gone"]), kitchenNames: ["Rice"])
        #expect(plan.nothingToAddMessage == "You already have everything in your kitchen")
    }

    @Test("Confirm button and message count items and meals, singular and plural")
    func confirmCopy() {
        let one = WeekGroceryPlan(summary: summary(["Onion"], meals: 1), kitchenNames: [])
        #expect(one.addButtonTitle == "Add 1 item")
        #expect(one.confirmMessage == "From 1 planned meal.")

        let many = WeekGroceryPlan(summary: summary(["Onion", "Rice", "Egg"], meals: 3), kitchenNames: ["egg"])
        #expect(many.addButtonTitle == "Add 2 items")
        #expect(many.confirmMessage == "From 3 planned meals. 1 already in your kitchen will be skipped.")
    }

    @Test("Added toast counts items, meals and skipped ones")
    func addedCopy() {
        let one = WeekGroceryPlan(summary: summary(["Onion"], meals: 1), kitchenNames: [])
        #expect(one.addedMessage == "Added 1 item from 1 meal")

        let many = WeekGroceryPlan(summary: summary(["Onion", "Rice", "Egg"], meals: 3), kitchenNames: ["egg"])
        #expect(many.addedMessage == "Added 2 items from 3 meals · 1 already in kitchen")
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

    @Test("Nothing left to add says where it all is", arguments: [
        (["onion"], ["rice"], "Everything for your plan is on your list or at home"),
        ([], ["onion", "rice"], "Everything for your plan is on your list"),
        (["onion", "rice"], [], "You already have everything in your kitchen"),
    ])
    func nothingLeftMessage(atHome: [String], onList: [String], message: String) {
        let summary = WeekShoppingSummary(items: [line("onion", 1), line("rice", 1)], mealsCovered: 2, missingRecipeNames: [])
        let plan = WeekGroceryPlan(summary: summary, kitchenNames: atHome, listItems: onList.map { listItem($0, 1) })

        #expect(plan.nothingToAddMessage == message)
    }

    @Test("Confirm message says what's already on the list")
    func confirmCountsListItems() {
        let summary = WeekShoppingSummary(items: [line("onion", 1), line("rice", 1), line("egg", 1)], mealsCovered: 2, missingRecipeNames: [])
        let plan = WeekGroceryPlan(summary: summary, kitchenNames: ["egg"], listItems: [listItem("rice", 1)])

        #expect(plan.confirmMessage == "From 2 planned meals. 1 already in your kitchen will be skipped. 1 already on your list.")
    }

    @Test("Card detail counts items, meals and what's at home")
    func cardDetail() {
        let one = WeekGroceryPlan(summary: summary(["Onion"], meals: 1), kitchenNames: [])
        #expect(one.cardDetail == "1 item for 1 planned meal")

        let many = WeekGroceryPlan(summary: summary(["Onion", "Rice", "Egg"], meals: 3), kitchenNames: ["egg"])
        #expect(many.cardDetail == "2 items for 3 planned meals · 1 at home")
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
        #expect(WeekGroceryPlan.empty.nothingToAddMessage == "No planned meals to shop for")
    }
}
