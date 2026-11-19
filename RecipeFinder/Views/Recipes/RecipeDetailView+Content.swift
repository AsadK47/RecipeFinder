import SwiftUI

// View-building content for RecipeDetailView, split out to keep the main file focused on state/body/actions.
extension RecipeDetailView {
    var backgroundView: some View {
        AppBackground()
    }

    var recipeTitleView: some View {
        VStack(spacing: AppTheme.spacing12) {
            if !galleryImageNames.isEmpty {
                imageGallery
                    .padding(.top, AppTheme.spacing8)
            }

            Text(recipe.name)
                .font(.system(size: AppTheme.fontSize34, weight: .bold))
                .adaptiveForegroundColor()
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, galleryImageNames.isEmpty ? AppTheme.spacing8 : 0)
                .padding(.bottom, cuisineRequest == nil ? AppTheme.spacing20 : 0)

            if let request = cuisineRequest {
                PrimaryButton("More \(request.cuisine) recipes", systemImage: "globe", size: .compact,
                              variant: .secondary) {
                    NotificationCenter.default.post(name: .openRecipes, object: nil, userInfo: request.userInfo)
                }
                .accessibilityIdentifier("recipe.cuisineChip")
                .padding(.bottom, AppTheme.spacing20)
            }
        }
        .padding(.horizontal, AppTheme.spacing20)
    }

    /// The cuisine chip under the title opens Recipes filtered to this cuisine.
    private var cuisineRequest: RecipeBrowseRequest? {
        RecipeBrowseRequest(cuisine: recipe.cuisine)
    }

    // Ordered displayable images (main first, then post-cook photos); filtered so stale refs don't gap. Cached in galleryImageNames to avoid FileManager checks every body pass.
    static func galleryNames(for recipe: RecipeModel) -> [String] {
        let own = ([recipe.imageName].compactMap { $0 } + recipe.photoNames)
            .filter { RecipeImageView.hasDisplayableImage($0) }
        // No picture of the cook's own at all: the built-in illustration — the same rule as `heroImageName`, so
        // lists and detail agree (a stale own file shows the placeholder in both, not art in one).
        if let hero = recipe.heroImageName, hero.hasPrefix(BundledRecipeArt.referencePrefix) { return [hero] }
        return own
    }

    // 220pt hero: single image renders directly, multiple become a paged gallery; tap opens full-screen at that index.
    private var imageGallery: some View {
        galleryContent
            .fullScreenCover(item: $photoViewer) { FullScreenPhotoViewer(source: $0) }
    }

    @ViewBuilder
    private var galleryContent: some View {
        let names = galleryImageNames
        if names.count == 1 {
            RecipeImageView(recipe: recipe, imageName: names[0], height: 220)
                .contentShape(Rectangle())
                .onTapGesture { openViewer(names, at: 0) }
        } else {
            TabView {
                ForEach(Array(names.enumerated()), id: \.offset) { index, name in
                    RecipeImageView(recipe: recipe, imageName: name, height: 220)
                        .contentShape(Rectangle())
                        .onTapGesture { openViewer(names, at: index) }
                }
            }
            .frame(height: 220)
            .tabViewStyle(.page)
        }
    }

    private func openViewer(_ names: [String], at index: Int) {
        photoViewer = PhotoViewerSource(imageNames: names, recipeName: recipe.name, startIndex: index)
    }

    var recipeInfoCardsView: some View {
        VStack(spacing: AppTheme.spacing16) {
            factsCard
            RecipeServingsCard(recipe: $recipe)
            if !recipe.tags.isEmpty {
                tagsCard
            }
        }
        .padding(.horizontal, AppTheme.spacing20)
    }

    var nutritionSection: some View {
        RecipeChecklistSection(
            title: "Nutrition",
            icon: "chart.pie",
            isExpanded: expandedSections.contains("Nutrition"),
            onToggle: { toggleSection("Nutrition") }
        ) {
            if let perServing = recipe.nutritionInfo {
                RecipeNutritionLabel(perServing: perServing, servings: recipe.currentServings,
                                     showsWholeRecipe: $nutritionShowsWholeRecipe)
            }
        }
    }

    var tagsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            Label("Tags", systemImage: "tag")
                .font(.caption)
                .adaptiveSecondaryForeground()
            TagRowView(tags: recipe.tags, font: .subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(elevated: true)
    }

    var factsCard: some View {
        RecipeFactsCard(recipe: recipe, onEdit: { beginEdit(section: .details) })
    }

    // Opens the pre-filled editor; `section` deep-links to those fields (else top).
    func beginEdit(section: RecipeWizardView.Section? = nil) {
        HapticManager.shared.light()
        editTarget = EditTarget(section: section)
    }

    /// "Estimate amounts" only where the on-device model can run; nil hides the button.
    var estimateAmountsAction: (() -> Void)? {
        guard amountEstimator.isAvailable else { return nil }
        return { beginAmountEstimate() }
    }

    var ingredientsSection: some View {
        RecipeIngredientsSection(
            recipe: recipe,
            ingredientsState: ingredientTicks.ticked,
            gotItState: ingredientTicks.inGotIt,
            measurementSystem: measurementSystem,
            isExpanded: expandedSections.contains("Ingredients"),
            onToggleSection: { toggleSection("Ingredients") },
            onToggleMeasurement: toggleMeasurementSystem,
            onToggleIngredient: toggleIngredient,
            onAddToShopping: { index in
                guard index < recipe.ingredients.count else { return }
                addIngredientToShoppingList(recipe.ingredients[index])
            },
            onAddAllToShopping: addAllIngredientsToShoppingList,
            isInShoppingList: { isIngredientInShoppingList($0) },
            onEditIngredient: { _ in beginEdit(section: .ingredients) },
            onSubstitute: { index in substitutingIngredientIndex = index },
            onEditIngredients: { beginEdit(section: .ingredients) },
            onEstimateAmounts: estimateAmountsAction,
            onStartCooking: { showCookingMode = true },
            pulsesFirstRow: pulsesFirstIngredient && !hasTickedIngredient
        )
        .sheet(item: $amountEstimateTarget) { target in
            AmountEstimateReviewSheet(
                target: target,
                estimator: amountEstimator,
                onSave: applyEstimatedAmounts,
                onEditManually: { beginEdit(section: .ingredients) }
            )
        }
        .sheet(item: Binding(
            get: { substitutingIngredientIndex.map { EditingIngredient(index: $0) } },
            set: { substitutingIngredientIndex = $0?.index }
        )) { subItem in
            let ingredient = recipe.ingredients[subItem.index]
            SubstituteSheetView(
                ingredientName: ingredient.mainIngredientName,
                substitutes: IngredientSubstituteProvider.substitutes(for: ingredient.name)
            )
        }
    }

    struct EditingIngredient: Identifiable {
        let index: Int
        var id: Int { index }
    }

    var prePrepSection: some View {
        RecipeChecklistSection(
            title: "Pre-Prep",
            icon: "list.clipboard",
            isExpanded: expandedSections.contains("Pre-Prep"),
            onToggle: { toggleSection("Pre-Prep") }
        ) {
            VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                ForEach(recipe.prePrepInstructions.indices, id: \.self) { index in
                    RecipeInstructionRow(
                        text: recipe.prePrepInstructions[index],
                        isChecked: prePrepState[safe: index] ?? false,
                        toggle: {
                            guard prePrepState.indices.contains(index) else { return }
                            HapticManager.shared.light()
                            prePrepState[index].toggle()
                            checkForCompletion()
                        }
                    )
                }
            }
        }
    }

    var instructionsSection: some View {
        RecipeChecklistSection(
            title: "Instructions",
            icon: "text.alignleft",
            isExpanded: expandedSections.contains("Instructions"),
            onToggle: { toggleSection("Instructions") }
        ) {
            VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                RecipeTimerControl(cookingTime: recipe.cookingTime, onPickTime: { showTimerSheet = true })

                ForEach(recipe.instructions.indices, id: \.self) { index in
                    RecipeInstructionRow(
                        text: recipe.instructions[index],
                        isChecked: instructionsState[safe: index] ?? false,
                        toggle: {
                            guard instructionsState.indices.contains(index) else { return }
                            HapticManager.shared.light()
                            instructionsState[index].toggle()
                            checkForCompletion()
                        }
                    )
                }
            }
        }
    }

    var notesSection: some View {
        RecipeChecklistSection(
            title: "Notes",
            icon: "note.text",
            isExpanded: expandedSections.contains("Notes"),
            onToggle: { toggleSection("Notes") }
        ) {
            RecipeNotesContent(notes: recipe.notesForDisplay, originalURL: recipe.importedFromURL)
        }
    }

    func editRecipeSheet(focus: RecipeWizardView.Section?) -> some View {
        RecipeWizardView(
            prefilledData: RecipeWizardView.PrefilledRecipeData(recipe: recipe),
            editingRecipeId: recipe.id,
            focus: focus,
            onComplete: { edited in
                let previous = recipe
                let updatedRecipe = RecipeWizardBuilder.mergeEdit(edited, onto: previous)
                recipe = updatedRecipe
                guard recipeStore.save(updatedRecipe) else {
                    recipe = previous
                    saveError = Self.saveErrorMessage
                    return
                }
                HapticManager.shared.success()
            }
        )
    }

    var cookHistoryCard: some View {
        RecipeCookHistoryCard(cookCount: recipe.cookCount, lastCookedAt: recipe.lastCookedAt,
                              rating: recipe.rating, onRate: updateRating)
    }

    /// The recipe's main actions in one row under the title, so nothing important is a scroll away:
    /// Cook (the one accent-filled primary), Shop, and Made it (logs a cook — was buried ~2 screens down).
    var primaryActionsRow: some View {
        let cookedToday = recipe.wasCookedToday()
        return HStack(spacing: AppTheme.spacing8) {
            PrimaryButton("Cook", systemImage: "frying.pan.fill", fillWidth: true) {
                showCookingMode = true
            }
            .accessibilityLabel("Start Cooking Mode")

            PrimaryButton("Shop", systemImage: "cart.badge.plus", fillWidth: true, variant: .secondary,
                          action: addAllIngredientsToShoppingList)
                .disabled(recipe.ingredients.isEmpty)
                .accessibilityLabel("Add all ingredients to groceries")

            PrimaryButton(cookedToday ? "Made" : "Made it", systemImage: "checkmark.circle", fillWidth: true,
                          variant: .secondary, action: { recordCook() })
                .disabled(cookedToday)
                .opacity(cookedToday ? AppTheme.glassLightOpacity : 1)
                .accessibilityIdentifier("recipe.markCooked")
                .accessibilityLabel(cookedToday ? "Cooked today" : "Mark as Cooked")
                .accessibilityHint(cookedToday ? "Already logged today" : "Increments the cook count and records today")
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, AppTheme.spacing20)
        .padding(.bottom, AppTheme.spacing16)
    }
}
