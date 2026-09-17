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

// MARK: - Open Recipe

struct OpenRecipeIntent: AppIntent {
    static let title: LocalizedStringResource = "Open a Recipe"
    static let description = IntentDescription(
        "Opens a specific recipe by name in RecipeFinder.",
        categoryName: "Recipes"
    )
    static let openAppWhenRun: Bool = true

    @Parameter(title: "Recipe Name", description: "The name of the recipe to open.")
    var recipeName: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let name = recipeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw $recipeName.needsValueError("Which recipe would you like to open?")
        }
        let recipes = await MainActor.run { PersistenceController.shared.fetchRecipes() }
        guard let recipe = recipes.first(where: { $0.name.localizedCaseInsensitiveContains(name) }) else {
            throw $recipeName.needsValueError("Couldn't find a recipe called \"\(name)\". Try a different name.")
        }
        await MainActor.run {
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenRecipe"),
                object: nil,
                userInfo: ["recipeId": recipe.id.uuidString]
            )
        }
        return .result(
            value: recipe.name,
            dialog: IntentDialog(stringLiteral: "Opening \(recipe.name).")
        )
    }
}

// MARK: - Start Cooking

struct StartCookingIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Cooking a Recipe"
    static let description = IntentDescription(
        "Opens a recipe in RecipeFinder so you can start cooking.",
        categoryName: "Recipes"
    )
    static let openAppWhenRun: Bool = true

    @Parameter(title: "Recipe Name", description: "The name of the recipe to cook.")
    var recipeName: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let name = recipeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw $recipeName.needsValueError("What would you like to cook?")
        }
        let recipes = await MainActor.run { PersistenceController.shared.fetchRecipes() }
        guard let recipe = recipes.first(where: { $0.name.localizedCaseInsensitiveContains(name) }) else {
            throw $recipeName.needsValueError("Couldn't find a recipe called \"\(name)\". Try a different name.")
        }
        await MainActor.run {
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenRecipe"),
                object: nil,
                userInfo: ["recipeId": recipe.id.uuidString]
            )
        }
        return .result(
            value: recipe.name,
            dialog: IntentDialog(stringLiteral: "Let's cook \(recipe.name). Opening the recipe now.")
        )
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
        AppShortcut(
            intent: OpenRecipeIntent(),
            phrases: [
                "Open recipe in \(.applicationName)",
                "Show me a recipe from \(.applicationName)"
            ],
            shortTitle: "Open Recipe",
            systemImageName: "book.fill"
        )
        AppShortcut(
            intent: StartCookingIntent(),
            phrases: [
                "Start cooking in \(.applicationName)",
                "Help me cook in \(.applicationName)"
            ],
            shortTitle: "Start Cooking",
            systemImageName: "fork.knife.circle.fill"
        )
    }
}
