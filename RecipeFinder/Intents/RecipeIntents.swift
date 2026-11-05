import AppIntents
import Foundation

// MARK: - Add to Shopping List

struct AddToShoppingListIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Item to Groceries"
    static let description = IntentDescription(
        "Adds an ingredient or item to your RecipeFinder groceries.",
        categoryName: "Groceries"
    )

    @Parameter(title: "Item", description: "The ingredient or item to add.")
    var itemName: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let name = itemName.trimmed
        guard !name.isEmpty else {
            throw $itemName.needsValueError("What item would you like to add?")
        }
        await MainActor.run {
            ShoppingListManager.shared.addItem(name: name, quantity: 1, category: nil)
        }
        return .result(
            value: name,
            dialog: IntentDialog(stringLiteral: "\(name) added to your groceries.")
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
        let name = recipeName.trimmed
        guard !name.isEmpty else {
            throw $recipeName.needsValueError("Which recipe would you like to open?")
        }
        let recipes = await MainActor.run { PersistenceController.shared.fetchRecipes() }
        // Prefer an exact name match so "Chicken Soup" doesn't open "Chicken"; fall back to a substring match.
        let match = recipes.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
            ?? recipes.first { $0.name.localizedCaseInsensitiveContains(name) }
        guard let recipe = match else {
            throw $recipeName.needsValueError("Couldn't find a recipe called \"\(name)\". Try a different name.")
        }
        await MainActor.run {
            NotificationCenter.default.post(
                name: .openRecipe,
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
        let name = recipeName.trimmed
        guard !name.isEmpty else {
            throw $recipeName.needsValueError("What would you like to cook?")
        }
        let recipes = await MainActor.run { PersistenceController.shared.fetchRecipes() }
        // Prefer an exact name match so a substring doesn't open the wrong recipe; fall back to a substring match.
        let match = recipes.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
            ?? recipes.first { $0.name.localizedCaseInsensitiveContains(name) }
        guard let recipe = match else {
            throw $recipeName.needsValueError("Couldn't find a recipe called \"\(name)\". Try a different name.")
        }
        await MainActor.run {
            NotificationCenter.default.post(
                name: .openRecipe,
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

// MARK: - Next Cooking Step

struct NextCookingStepIntent: AppIntent {
    static let title: LocalizedStringResource = "Next Cooking Step"
    static let description = IntentDescription(
        "Advances to the next step in RecipeFinder cooking mode.",
        categoryName: "Cooking"
    )

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let isActive = await MainActor.run { CookingSession.shared.isActive }
        guard isActive else {
            return .result(dialog: "No recipe is currently open in RecipeFinder cooking mode.")
        }
        let text = await MainActor.run { () -> String in
            // advance() is a no-op at the last step, so detect "no change" and report completion instead of re-reading the final step.
            let before = CookingSession.shared.currentStepText
            CookingSession.shared.advance()
            let after = CookingSession.shared.currentStepText
            if before == after {
                return "That's the last step — you've finished the recipe."
            }
            return after ?? "You've finished the recipe."
        }
        return .result(dialog: IntentDialog(stringLiteral: text))
    }
}

// MARK: - Previous Cooking Step

struct PreviousCookingStepIntent: AppIntent {
    static let title: LocalizedStringResource = "Previous Cooking Step"
    static let description = IntentDescription(
        "Goes back to the previous step in RecipeFinder cooking mode.",
        categoryName: "Cooking"
    )

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let isActive = await MainActor.run { CookingSession.shared.isActive }
        guard isActive else {
            return .result(dialog: "No recipe is currently open in RecipeFinder cooking mode.")
        }
        let text = await MainActor.run {
            CookingSession.shared.retreat()
            return CookingSession.shared.currentStepText ?? "You're at the beginning."
        }
        return .result(dialog: IntentDialog(stringLiteral: text))
    }
}

// MARK: - Shortcuts provider

struct RecipeShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddToShoppingListIntent(),
            phrases: [
                "Add item to my \(.applicationName) list",
                "Add something to my \(.applicationName) groceries"
            ],
            shortTitle: "Add to Groceries",
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
        AppShortcut(
            intent: NextCookingStepIntent(),
            phrases: [
                "Next step in \(.applicationName)",
                "Next cooking step in \(.applicationName)"
            ],
            shortTitle: "Next Cooking Step",
            systemImageName: "chevron.right.circle.fill"
        )
        AppShortcut(
            intent: PreviousCookingStepIntent(),
            phrases: [
                "Previous step in \(.applicationName)",
                "Go back a step in \(.applicationName)"
            ],
            shortTitle: "Previous Step",
            systemImageName: "chevron.left.circle.fill"
        )
    }
}
