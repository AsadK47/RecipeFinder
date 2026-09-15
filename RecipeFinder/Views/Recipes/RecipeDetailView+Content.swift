import SwiftUI

/// 1–5 star rating control. Tap the active star to clear back to 0 (unrated).
private struct StarRatingView: View {
    let rating: Int
    let onTap: (Int) -> Void

    var body: some View {
        HStack(spacing: AppTheme.spacing4) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    onTap(star == rating ? 0 : star)
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .foregroundStyle(star <= rating ? Color.yellow : Color.secondary)
                        .font(.system(size: AppTheme.fontSize18))
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rating == 0 ? "Unrated" : "\(rating) of 5 stars")
        .accessibilityHint("Tap a star to set your rating; tap again to clear")
    }
}

/// View-building content for `RecipeDetailView`, split out to keep the main file
/// focused on state, `body`, and actions. These are moved verbatim from the
/// orchestrator; `RecipeDetailView`'s state and helpers are `internal` so this
/// same-type extension (in a separate file) can read them.
extension RecipeDetailView {
    var backgroundView: some View {
        AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
            .ignoresSafeArea()
    }

    var recipeTitleView: some View {
        VStack(spacing: AppTheme.spacing12) {
            if let imageName = recipe.imageName, !imageName.isEmpty {
                RecipeImageView(imageName: imageName, height: 220)
                    .padding(.top, AppTheme.spacing8)
            }

            if !recipe.photoNames.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.spacing8) {
                        ForEach(Array(recipe.photoNames.enumerated()), id: \.offset) { _, name in
                            RecipeImageView(imageName: name, height: 90)
                                .frame(width: 90, height: 90)
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                }
            }

            Text(recipe.name)
                .font(.system(size: AppTheme.fontSize34, weight: .bold))
                .adaptiveForegroundColor()
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, recipe.imageName?.isEmpty == false ? 0 : AppTheme.spacing8)
                .padding(.bottom, AppTheme.spacing20)
        }
        .padding(.horizontal, AppTheme.spacing20)
    }

    var recipeInfoCardsView: some View {
        VStack(spacing: AppTheme.spacing16) {
            timeInfoCard
            detailsInfoCard
            RecipeServingsCard(recipe: $recipe)
            if !recipe.tags.isEmpty {
                tagsCard
            }
            cookHistoryCard
        }
        .padding(.horizontal, AppTheme.spacing20)
    }

    var nutritionSection: some View {
        RecipeChecklistSection(
            title: "Nutrition",
            icon: "chart.pie",
            isExpanded: expandedSections.contains("Nutrition"),
            colorScheme: colorScheme,
            onToggle: { toggleSection("Nutrition") }
        ) {
            if let n = recipe.nutritionInfo {
                VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                    Text("Per serving")
                        .font(.caption)
                        .adaptiveSecondaryForeground()

                    nutritionLabelRow(label: "Calories", value: "\(n.calories)", unit: "kcal", hero: true)

                    Divider()

                    nutritionLabelRow(label: "Fat", value: formatMacro(n.fat), unit: "g")
                    nutritionLabelSubrow(label: "of which saturates", value: formatMacro(n.saturates), unit: "g")

                    Divider()

                    nutritionLabelRow(label: "Carbohydrate", value: formatMacro(n.carbs), unit: "g")
                    nutritionLabelSubrow(label: "of which sugars", value: formatMacro(n.sugars), unit: "g")

                    Divider()

                    nutritionLabelRow(label: "Fibre", value: formatMacro(n.fibre), unit: "g")

                    Divider()

                    nutritionLabelRow(label: "Protein", value: formatMacro(n.protein), unit: "g")

                    Divider()

                    nutritionLabelRow(label: "Salt", value: formatSalt(n.salt), unit: "g")

                    if n.coverage < 0.8 {
                        Text("Estimated — \(Int(n.coverage * 100))% of ingredients matched")
                            .font(.caption2)
                            .adaptiveSecondaryForeground()
                            .padding(.top, AppTheme.spacing4)
                    }
                }
            }
        }
    }

    private func nutritionLabelRow(label: String, value: String, unit: String, hero: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.spacing4) {
            Text(label)
                .font(hero ? .headline : .subheadline)
                .adaptiveForegroundColor()
            Spacer()
            Text(value)
                .font(hero ? .headline.weight(.bold) : .subheadline.weight(.semibold))
                .adaptiveForegroundColor()
            Text(unit)
                .font(hero ? .subheadline : .caption)
                .adaptiveSecondaryForeground()
                .frame(minWidth: 28, alignment: .leading)
        }
    }

    private func nutritionLabelSubrow(label: String, value: String, unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.spacing4) {
            Text(label)
                .font(.caption)
                .adaptiveSecondaryForeground()
                .padding(.leading, AppTheme.spacing16)
            Spacer()
            Text(value)
                .font(.caption.weight(.medium))
                .adaptiveSecondaryForeground()
            Text(unit)
                .font(.caption)
                .adaptiveSecondaryForeground()
                .frame(minWidth: 28, alignment: .leading)
        }
    }

    private func formatMacro(_ value: Double) -> String {
        value >= 10 ? "\(Int(value.rounded()))" : String(format: "%.1f", value)
    }

    private func formatSalt(_ value: Double) -> String {
        value >= 1.0 ? String(format: "%.1f", value) : String(format: "%.2f", value)
    }

    var tagsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                Label("Tags", systemImage: "tag")
                    .font(.caption)
                    .adaptiveSecondaryForeground()
                TagRowView(tags: recipe.tags, font: .subheadline)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    var timeInfoCard: some View {
        GlassCard {
            InfoPairView(
                label1: "Prep time", value1: recipe.prepTime, icon1: "clock",
                label2: "Cook time", value2: recipe.cookingTime, icon2: "flame"
            )
            .padding()
        }
    }

    var detailsInfoCard: some View {
        GlassCard {
            VStack(spacing: 0) {
                InfoPairView(
                    label1: "Difficulty", value1: recipe.difficulty, icon1: "chart.bar",
                    label2: "Category", value2: recipe.category, icon2: "fork.knife"
                )
                if let cuisine = recipe.cuisine, !cuisine.isEmpty {
                    Divider()
                        .padding(.horizontal, AppTheme.spacing24)
                        .padding(.top, AppTheme.spacing12)
                    InfoItem(icon: "globe", label: "Cuisine", value: cuisine)
                        .padding(.top, AppTheme.spacing12)
                }
            }
            .padding()
        }
    }

    var ingredientsSection: some View {
        RecipeIngredientsSection(
            recipe: recipe,
            ingredientsState: ingredientsState,
            measurementSystem: measurementSystem,
            isExpanded: expandedSections.contains("Ingredients"),
            colorScheme: colorScheme,
            onToggleSection: { toggleSection("Ingredients") },
            onToggleMeasurement: toggleMeasurementSystem,
            onToggleIngredient: { index in
                HapticManager.shared.light()
                ingredientsState[index].toggle()
                checkForCompletion()
            },
            onAddToShopping: { index in
                addIngredientToShoppingList(recipe.ingredients[index])
            },
            onAddAllToShopping: addAllIngredientsToShoppingList,
            isInShoppingList: { isIngredientInShoppingList($0) },
            onEditIngredient: { index in startEditingIngredient(at: index) },
            onSubstitute: { index in substitutingIngredientIndex = index },
            isInPantry: { pantryManager.hasItem($0.mainIngredientName) },
            onTogglePantry: { index in
                let ingredient = recipe.ingredients[index]
                pantryManager.toggleItem(ingredient.mainIngredientName)
            }
        )
        .sheet(item: Binding(
            get: { editingIngredientIndex.map { EditingIngredient(index: $0) } },
            set: { editingIngredientIndex = $0?.index }
        )) { editingItem in
            IngredientEditSheet(
                ingredientName: recipe.ingredients[editingItem.index].name,
                editingQuantity: $editingQuantity,
                editingUnit: $editingUnit,
                onCancel: { editingIngredientIndex = nil },
                onSave: { saveIngredientEdit(at: editingItem.index) }
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
            colorScheme: colorScheme,
            onToggle: { toggleSection("Pre-Prep") }
        ) {
            VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                ForEach(recipe.prePrepInstructions.indices, id: \.self) { index in
                    RecipeInstructionRow(
                        text: recipe.prePrepInstructions[index],
                        isChecked: prePrepState[index],
                        toggle: {
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
            colorScheme: colorScheme,
            onToggle: { toggleSection("Instructions") }
        ) {
            VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                timerControl

                ForEach(recipe.instructions.indices, id: \.self) { index in
                    RecipeInstructionRow(
                        text: recipe.instructions[index],
                        isChecked: instructionsState[index],
                        toggle: {
                            HapticManager.shared.light()
                            instructionsState[index].toggle()
                            checkForCompletion()
                        }
                    )
                }
            }
        }
    }

    /// Cooking timer, co-located with the steps it's used alongside. Shows a
    /// "Start a timer" button when idle, and a live, controllable pill when active.
    @ViewBuilder
    var timerControl: some View {
        if recipeTimer.isActive {
            Menu {
                Button(action: { showTimerSheet = true }) {
                    Label("Set New Timer", systemImage: "clock")
                }
                Divider()
                Button(action: { recipeTimer.togglePause() }) {
                    Label(recipeTimer.isPaused ? "Resume" : "Pause",
                          systemImage: recipeTimer.isPaused ? "play.fill" : "pause.fill")
                }
                Button(role: .destructive, action: { recipeTimer.stop() }) {
                    Label("Stop", systemImage: "stop.fill")
                }
            } label: {
                timerRowLabel(
                    icon: recipeTimer.isPaused ? "play.fill" : "pause.fill",
                    text: recipeTimer.displayTime,
                    monospaced: true
                )
            }
            .accessibilityLabel("Recipe timer, \(recipeTimer.displayTime)")
            .accessibilityHint("Open timer actions")
        } else {
            Button(action: { showTimerSheet = true }) {
                timerRowLabel(icon: "timer", text: "Start a timer", monospaced: false)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Start a cooking timer")
        }
    }

    private func timerRowLabel(icon: String, text: String, monospaced: Bool) -> some View {
        HStack(spacing: AppTheme.spacing8) {
            Image(systemName: icon)
                .font(.subheadline)
            Text(text)
                .font(monospaced ? .system(.subheadline, design: .monospaced).weight(.semibold) : .subheadline.weight(.medium))
            Spacer(minLength: 0)
        }
        .adaptiveForegroundColor()
        .padding(.horizontal, AppTheme.spacing12)
        .padding(.vertical, AppTheme.spacing10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.overlayLightOpacity) : Color.black.opacity(AppTheme.dividerOpacity))
        )
    }

    var notesSection: some View {
        RecipeChecklistSection(
            title: "Notes",
            icon: "note.text",
            isExpanded: expandedSections.contains("Notes"),
            colorScheme: colorScheme,
            onToggle: { toggleSection("Notes") }
        ) {
            VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                if !recipe.notesForDisplay.isEmpty {
                    Text(RecipeNotesFormatter.attributedString(from: recipe.notesForDisplay))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let url = recipe.importedFromURL {
                    Link(destination: url) {
                        Label("View Original", systemImage: "link")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var editRecipeSheet: some View {
        RecipeWizardView(
            prefilledData: RecipeWizardView.PrefilledRecipeData(
                name: recipe.name,
                description: nil,
                ingredients: recipe.ingredients.map { "\(String(format: "%g", $0.baseQuantity)) \($0.unit) \($0.name)" },
                instructions: recipe.instructions,
                prePrepInstructions: recipe.prePrepInstructions,
                prepTime: TimeExtractor.extractMinutes(from: recipe.prepTime),
                cookTime: TimeExtractor.extractMinutes(from: recipe.cookingTime),
                servings: recipe.baseServings,
                difficulty: recipe.difficulty,
                notes: recipe.notes.isEmpty ? nil : recipe.notes,
                category: recipe.category,
                isFavorite: recipe.isFavorite,
                imageURL: recipe.imageName,
                tags: recipe.tags.isEmpty ? nil : recipe.tags,
                cuisine: recipe.cuisine,
                galleryImageURLs: recipe.photoNames.isEmpty ? nil : recipe.photoNames
            ),
            editingRecipeId: recipe.id,
            onComplete: { updatedRecipe in
                let previous = recipe
                recipe = updatedRecipe
                guard PersistenceController.shared.saveRecipeModel(updatedRecipe) else {
                    recipe = previous
                    showSaveError = true
                    return
                }
                HapticManager.shared.success()
            }
        )
    }

    var cookHistoryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                HStack {
                    Label("Rating", systemImage: "star")
                        .font(.caption)
                        .adaptiveSecondaryForeground()
                    Spacer()
                    StarRatingView(rating: recipe.rating, onTap: updateRating)
                }

                Divider()

                HStack(alignment: .firstTextBaseline) {
                    Label(
                        recipe.cookCount == 0
                            ? "Not cooked yet"
                            : "Cooked \(recipe.cookCount) \(recipe.cookCount == 1 ? "time" : "times")",
                        systemImage: "frying.pan"
                    )
                    .font(.caption)
                    .adaptiveSecondaryForeground()

                    if let lastCooked = recipe.lastCookedAt {
                        Spacer()
                        Text(lastCooked, style: .relative)
                            .font(.caption)
                            .adaptiveSecondaryForeground()
                    }
                }

                Button(action: recordCook) {
                    Label("Mark as Cooked", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .adaptiveForegroundColor()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.spacing10)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                                .fill(AppTheme.accentColor.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityHint("Increments the cook count and records today")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    var feedbackOverlay: some View {
        if let feedback = showAddedFeedback {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: "basket.fill")
                    .adaptiveForegroundColor()
                Text("\(feedback) added to shopping list")
                    .font(.subheadline)
                    .adaptiveForegroundColor()
            }
            .padding(.horizontal, AppTheme.spacing20)
            .padding(.vertical, AppTheme.spacing12)
            .background(
                Capsule()
                    .fill(AppTheme.accentColor)
                    .shadow(color: .black.opacity(AppTheme.overlayLightOpacity), radius: 8, y: 4)
            )
            .padding(.bottom, AppTheme.spacing20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .opacity(showAddedFeedback != nil ? 1 : 0)
        }
    }
}
