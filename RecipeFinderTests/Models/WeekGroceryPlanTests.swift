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

    @Test("Empty plan has nothing to add")
    func emptyPlan() {
        #expect(WeekGroceryPlan.empty.candidates.isEmpty)
        #expect(WeekGroceryPlan.empty.nothingToAddMessage == "No planned meals to shop for")
    }
}
