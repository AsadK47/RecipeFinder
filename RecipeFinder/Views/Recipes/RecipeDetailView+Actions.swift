import StoreKit
import SwiftUI

// Recipe detail's actions — groceries, cook recording (Made it, photo, rating, badges) and refresh/re-import —
// split from RecipeDetailView (Smell Batch A). Copy and the cook-count rule are pure and tested
// (`RecipeDetailCopy`, `RecipeModel.recordingCook`).
extension RecipeDetailView {
    func addIngredientToShoppingList(_ ingredient: Ingredient) {
        HapticManager.shared.light()

        guard let item = RecipeShoppingList.item(from: ingredient, scaleFactor: recipe.scaleFactor) else { return }

        ShoppingListManager.shared.addItem(name: item.name, quantity: item.quantity, unit: item.unit, category: nil)

        addedIngredients.insert(ingredient.name)

        showAddedFeedback = RecipeDetailCopy.addedToGroceries(name: item.name)

        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayFeedback) {
            withAnimation {
                _ = addedIngredients.remove(ingredient.name)
            }
        }
    }

    /// Opens the pre-ticked "Add to Groceries" sheet (Shop button and the ingredients header's cart button).
    func addAllIngredientsToShoppingList() {
        guard !recipe.ingredients.isEmpty else { return }
        shopSheetRecipe = recipe
    }

    /// Adds the ingredients confirmed in the shop sheet.
    func addIngredientsToShoppingList(_ ingredients: [Ingredient]) {
        guard !ingredients.isEmpty else { return }

        HapticManager.shared.success()

        var addedCount = 0
        for ingredient in ingredients {
            guard let item = RecipeShoppingList.item(from: ingredient, scaleFactor: recipe.scaleFactor) else { continue }

            ShoppingListManager.shared.addItem(name: item.name, quantity: item.quantity, unit: item.unit, category: nil)
            addedIngredients.insert(ingredient.name)
            addedCount += 1
        }

        guard addedCount > 0 else { return }

        showAddedFeedback = RecipeDetailCopy.addedToGroceries(count: addedCount)

        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayFeedback) {
            withAnimation {
                ingredients.forEach { ingredient in
                    _ = addedIngredients.remove(ingredient.name)
                }
            }
        }
    }

    func isIngredientInShoppingList(_ ingredient: Ingredient) -> Bool {
        addedIngredients.contains(ingredient.name)
    }

    /// Logs a cook and queues the Made it sheet; false when this recipe was already cooked today.
    @discardableResult
    func recordCook() -> Bool {
        // One cook a day: Made it is disabled once cooked today, and finishing cooking mode again mustn't add another.
        guard let cooked = recipe.recordingCook() else { return false }
        recipe = cooked
        Task { await PersistenceController.shared.recordCook(withId: recipe.id) }
        recipeStore.sync(recipe)
        mealPlanning.markCooked(recipeID: recipe.id, on: Date())

        // Cooking is the rewarded action: the Made it sheet plays the haptic and confetti for every cook, once it's
        // on screen — fired here, they landed behind cooking mode's closing cover.

        // Feed the weekly cooking-streak habit loop; the Made it sheet shows the resulting streak.
        _ = cookingStreak.recordCookToday()

        // Cooking is now the main path to badges: volume (10/25/50/100), streak, cuisines, and mastery all
        // key off this choke point.
        let totalCooks = refreshCookingBadges().recipesCooked
        // Third cook = genuine fan; ask for a review exactly once.
        if ReviewPrompt.shouldRequestReview(afterCookCount: recipe.cookCount) { requestReview() }

        // One celebratory sheet replaces the scattered toast / photo prompt / scroll-down rating.
        let summary = MadeItSummary(
            recipe: recipe,
            cookNumber: totalCooks,
            streakWeeks: cookingStreak.streak.currentWeeks,
            cooksThisWeek: cookingStreak.streak.cooksThisWeek,
            milestone: BadgeType.nextCookingMilestone(totalCooks: totalCooks)
        )
        let request = MadeItPresenter.Request(
            recipeId: recipe.id, summary: summary, onRate: updateRating, onPhotoSelected: addCookPhoto
        )
        if showCookingMode {
            madeItPresenter.hold(request)
        } else {
            madeItPresenter.present(request)
        }
        return true
    }

    private func addCookPhoto(_ image: UIImage) {
        let store = RecipeImageStore()
        let newPaths = store.persistGallery([image], recipeId: recipe.id)
        // Surface the failure (e.g. disk full) instead of dropping the photo.
        guard !newPaths.isEmpty else {
            saveError = Self.saveErrorMessage
            return
        }
        recipe.photoNames.append(contentsOf: newPaths)
        guard recipeStore.save(recipe) else {
            recipe.photoNames.removeLast(newPaths.count)
            saveError = Self.saveErrorMessage
            return
        }
        HapticManager.shared.success()
        refreshCookingBadges()   // first cook photo → "Food Stylist"
    }

    func updateRating(_ newRating: Int) {
        HapticManager.shared.selection()
        recipe.rating = newRating
        Task { await PersistenceController.shared.updateRating(withId: recipe.id, rating: newRating) }
        recipeStore.sync(recipe)
        refreshCookingBadges()   // rating 10 recipes → "Critic"
    }

    /// Re-evaluate cooking/collection badges from the current library + streak. Safe after any action that
    /// changes a metric (cook, cook photo, rating); unlocking is idempotent.
    @discardableResult
    private func refreshCookingBadges() -> BadgeMetrics {
        let metrics = BadgeMetrics.from(recipes: recipeStore.recipes, streakWeeks: cookingStreak.streak.currentWeeks)
        BadgeManager.shared.checkAndUnlockBadges(metrics: metrics)
        return metrics
    }

    // Auto-runs on open; discards network errors silently, shows diff sheet only on real changes.
    func silentRefreshFromSource() async {
        guard recipe.shouldAutoRefreshFromSource, let url = recipe.importedFromURL else { return }
        let importer = RecipeImporter()
        await importer.importRecipe(from: url)
        guard let data = importer.extractedData else { return }
        let upstream = RecipeImportBuilder().build(from: data)
        let diff = RecipeDiff.compute(stored: recipe, upstream: upstream)
        if diff.hasChanges {
            pendingRefreshDiff = diff
        }
    }

    /// Re-parses the saved original import text with today's parser and offers the per-field accept sheet.
    func reimportFromOriginal() {
        guard let text = recipe.sourceText else { return }
        Task {
            guard let prefill = await RecipeTextImportRouter().prefill(for: text) else {
                showAddedFeedback = RecipeDetailCopy.reimportUnreadable
                return
            }
            let diff = RecipeDiff.reimport(stored: recipe, prefill: prefill)
            if diff.hasChanges {
                pendingRefreshDiff = diff
            } else {
                showAddedFeedback = RecipeDetailCopy.reimportUnchanged
            }
        }
    }

    func beginAmountEstimate() {
        guard let request = AmountEstimateRequest(
            recipeName: recipe.name, servings: recipe.baseServings,
            ingredients: recipe.ingredients, steps: recipe.instructions
        ) else { return }
        HapticManager.shared.light()
        amountEstimateTarget = AmountEstimateTarget(request: request, ingredients: recipe.ingredients)
    }

    func applyEstimatedAmounts(_ ingredients: [Ingredient]) {
        var updated = recipe
        updated.ingredients = ingredients
        applyRefresh(updated)
    }

    func applyRefresh(_ updated: RecipeModel) {
        let previous = recipe
        recipe = updated
        guard recipeStore.save(updated) else {
            recipe = previous
            saveError = Self.saveErrorMessage
            return
        }
        HapticManager.shared.success()
    }
}
