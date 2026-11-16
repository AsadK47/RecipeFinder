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

    /// Prep, cook, difficulty, category (and cuisine) in one slim card. These used to be two tall cards
    /// that, with servings, pushed the ingredients most of a screen down. One row when every value fits at full size;
    /// otherwise two rows — squeezing long values ("Intermediate", "Main course") into a row made them overlap.
    var factsCard: some View {
        let facts = recipeFacts
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(facts) { fact($0) }
            }
            Grid(horizontalSpacing: 0, verticalSpacing: AppTheme.spacing12) {
                ForEach(Self.factRows(count: facts.count), id: \.self) { row in
                    GridRow {
                        ForEach(row, id: \.self) { fact(facts[$0]) }
                    }
                }
            }
        }
        .padding(.vertical, AppTheme.spacing12)
        .padding(.horizontal, AppTheme.spacing8)
        .appCard(elevated: true)
        .editableCard(onEdit: { beginEdit(section: .details) }, hint: "Edit times, difficulty, category and cuisine")
        .accessibilityIdentifier("recipe.card.time")
    }

    struct RecipeFact: Identifiable {
        let icon: String, tint: Color, value: String, label: String
        var id: String { label }
    }

    private var recipeFacts: [RecipeFact] {
        var facts = [
            RecipeFact(icon: "clock", tint: .orange, value: shortTime(recipe.prepTimeDisplay), label: "Prep"),
            RecipeFact(icon: "flame", tint: .red, value: shortTime(recipe.cookTimeDisplay), label: "Cook"),
            RecipeFact(icon: "chart.bar", tint: .blue, value: recipe.difficulty, label: "Difficulty"),
            RecipeFact(icon: "fork.knife", tint: .green, value: recipe.category, label: "Category"),
        ]
        if let cuisine = recipe.cuisine, !cuisine.isEmpty {
            facts.append(RecipeFact(icon: "globe", tint: .teal, value: cuisine, label: "Cuisine"))
        }
        return facts
    }

    /// Indices for the two-row layout: 4 facts → 2 + 2, 5 → 3 + 2 (times stay together on the first row).
    static func factRows(count: Int) -> [[Int]] {
        guard count > 0 else { return [] }
        let firstRow = (count + 1) / 2
        return [Array(0..<firstRow), Array(firstRow..<count)].filter { !$0.isEmpty }
    }

    private func fact(_ fact: RecipeFact) -> some View {
        VStack(spacing: AppTheme.spacing4) {
            Image(systemName: fact.icon)
                .font(.subheadline)
                .foregroundStyle(fact.tint)
                .accessibilityHidden(true)
            Text(fact.value)
                .font(.subheadline.weight(.semibold))
                .adaptiveForegroundColor()
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(fact.label)
                .font(.caption2)
                .adaptiveSecondaryForeground()
                .lineLimit(1)
        }
        .padding(.horizontal, AppTheme.spacing4)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    /// "15 minutes" → "15 min" so four or five facts fit across one row.
    private func shortTime(_ display: String) -> String {
        display
            .replacingOccurrences(of: " minutes", with: " min")
            .replacingOccurrences(of: " minute", with: " min")
            .replacingOccurrences(of: " hours", with: " hr")
            .replacingOccurrences(of: " hour", with: " hr")
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
                timerControl

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

    // Cooking timer co-located with the steps: Start button when idle, live pill when active.
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
            Button(action: startCookTimer) {
                timerRowLabel(
                    icon: "timer",
                    text: cookTimerMinutes > 0 ? "Start \(cookTimerMinutes)-min timer" : "Start a timer",
                    monospaced: false
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint(cookTimerMinutes > 0
                ? "Starts a \(cookTimerMinutes) minute timer"
                : "Start a cooking timer")
        }
    }

    // Minutes from the recipe's cook time; 0 when unparseable.
    private var cookTimerMinutes: Int {
        TimeExtractor.extractMinutes(from: recipe.cookingTime)
    }

    // One-tap start from the recipe's cook time; falls back to the picker sheet when there's none.
    private func startCookTimer() {
        let minutes = cookTimerMinutes
        guard minutes > 0 else {
            showTimerSheet = true
            return
        }
        HapticManager.shared.light()
        recipeTimer.start(hours: minutes / 60, minutes: minutes % 60, seconds: 0)
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
                .fill(AppTheme.adaptive(light: Color.black.opacity(AppTheme.dividerOpacity), dark: Color.white.opacity(AppTheme.overlayLightOpacity)))
        )
    }

    var notesSection: some View {
        RecipeChecklistSection(
            title: "Notes",
            icon: "note.text",
            isExpanded: expandedSections.contains("Notes"),
            onToggle: { toggleSection("Notes") }
        ) {
            VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                if !recipe.notesForDisplay.isEmpty {
                    Text(RecipeNotesFormatter.attributedString(from: recipe.notesForDisplay))
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let url = recipe.importedFromURL {
                    HStack(spacing: AppTheme.spacing8) {
                        Link(destination: url) {
                            Label("View Original", systemImage: "link")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
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
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            // Rating only appears once the recipe has actually been cooked — you rate what you've made,
            // not a recipe you've never tried. Logging a cook is the "Made it" button in the action row.
            if recipe.cookCount > 0 {
                HStack {
                    Label("Rating", systemImage: "star")
                        .font(.caption)
                        .adaptiveSecondaryForeground()
                    Spacer()
                    StarRatingView(rating: recipe.rating, onTap: updateRating)
                        .accessibilityIdentifier("recipe.rating")
                }

                Divider()
            }

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
                    // Named relative ("2 minutes ago"); `style: .relative` read like a duration ("44 secs").
                    Text(lastCooked.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .adaptiveSecondaryForeground()
                }
            }

        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(elevated: true)
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
                          variant: .secondary, action: recordCook)
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
