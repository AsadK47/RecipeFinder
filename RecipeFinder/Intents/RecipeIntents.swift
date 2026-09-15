import AppIntents
import Foundation

// MARK: - Add to Shopping List

struct AddToShoppingListIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Item to Shopping List"
    static let description = IntentDescription(
        "Adds an ingredient or item to your RecipeFinder shopping list.",
        categoryName: "Shopping"
    )

    @Parameter(title: "Item", description: "The ingredient or item to add.")
    var itemName: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let name = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw $itemName.needsValueError("What item would you like to add?")
        }
        await MainActor.run {
            ShoppingListManager.shared.addItem(name: name, quantity: 1, category: nil)
        }
        return .result(
            value: name,
            dialog: IntentDialog(stringLiteral: "\(name) added to your shopping list.")
        )
    }
}

// MARK: - What's for dinner?

struct WhatsForDinnerIntent: AppIntent {
    static let title: LocalizedStringResource = "What's for Dinner?"
    static let description = IntentDescription(
        "Tells you what's planned for dinner tonight in RecipeFinder.",
        categoryName: "Meal Planning"
    )

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let plan = await MainActor.run {
            MealPlanningManager.shared.mealPlan(for: Date(), mealTime: .dinner)
        }
        if let plan {
            return .result(
                value: plan.recipeName,
                dialog: IntentDialog(stringLiteral: "Tonight's dinner is \(plan.recipeName).")
            )
        } else {
            return .result(
                value: "",
                dialog: IntentDialog(stringLiteral: "Nothing is planned for dinner tonight. Open RecipeFinder to add something.")
            )
        }
    }
}

// MARK: - Shortcuts provider

struct RecipeShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddToShoppingListIntent(),
            phrases: [
                "Add item to my \(.applicationName) list",
                "Add something to my \(.applicationName) shopping list"
            ],
            shortTitle: "Add to Shopping List",
            systemImageName: "cart.badge.plus"
        )
        AppShortcut(
            intent: WhatsForDinnerIntent(),
            phrases: [
                "What's for dinner in \(.applicationName)",
                "What's on my \(.applicationName) dinner plan"
            ],
            shortTitle: "What's for Dinner?",
            systemImageName: "fork.knife"
        )
    }
}
