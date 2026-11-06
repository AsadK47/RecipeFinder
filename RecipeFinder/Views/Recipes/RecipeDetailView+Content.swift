import SwiftUI

// 1–5 star rating; tap the active star to clear to 0 (unrated).
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
                .padding(.bottom, AppTheme.spacing20)
        }
        .padding(.horizontal, AppTheme.spacing20)
    }

    // Ordered displayable images (main first, then post-cook photos); filtered so stale refs don't gap. Cached in galleryImageNames to avoid FileManager checks every body pass.
    static func galleryNames(for recipe: RecipeModel) -> [String] {
        ([recipe.imageName].compactMap { $0 } + recipe.photoNames)
            .filter { RecipeImageView.hasDisplayableImage($0) }
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
            RecipeImageView(imageName: names[0], height: 220, recipeName: recipe.name)
                .contentShape(Rectangle())
                .onTapGesture { openViewer(names, at: 0) }
        } else {
            TabView {
                ForEach(Array(names.enumerated()), id: \.offset) { index, name in
                    RecipeImageView(imageName: name, height: 220, recipeName: recipe.name)
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
            timeInfoCard
            detailsInfoCard
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
                // Whole-recipe multiplies per-serving by current servings; % RI is per-serving only.
                let isWhole = nutritionShowsWholeRecipe
                let n = isWhole ? perServing.scaled(by: recipe.currentServings) : perServing
                VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                    Picker("Nutrition amount", selection: $nutritionShowsWholeRecipe) {
                        Text("Per serving").tag(false)
                        Text("Whole recipe").tag(true)
                    }
                    .pickerStyle(.segmented)

                    // Present in both modes so the macro bar below doesn't jump vertically.
                    Text(isWhole
                         ? "Total for \(recipe.currentServings) serving\(recipe.currentServings == 1 ? "" : "s")"
                         : "Amount per serving")
                        .font(.caption2)
                        .adaptiveSecondaryForeground()

                    NutritionMacroBar(nutrition: n)

                    if !isWhole {
                        HStack {
                            Spacer()
                            Text("% RI*")
                                .font(.caption2)
                                .adaptiveSecondaryForeground()
                        }
                        .padding(.bottom, -AppTheme.spacing4)
                    }

                    nutritionLabelRow(label: "Calories", value: "\(n.calories)", unit: "kcal", hero: true,
                                      percent: isWhole ? nil : drvPercent(Double(n.calories), of: 2000))

                    Divider()

                    nutritionLabelRow(label: "Fat", value: formatMacro(n.fat), unit: "g",
                                      percent: isWhole ? nil : drvPercent(n.fat, of: 70))
                    nutritionLabelSubrow(label: "of which saturates", value: formatMacro(n.saturates), unit: "g",
                                         percent: isWhole ? nil : drvPercent(n.saturates, of: 20))

                    Divider()

                    nutritionLabelRow(label: "Carbohydrate", value: formatMacro(n.carbs), unit: "g",
                                      percent: isWhole ? nil : drvPercent(n.carbs, of: 260))
                    nutritionLabelSubrow(label: "of which sugars", value: formatMacro(n.sugars), unit: "g",
                                         percent: isWhole ? nil : drvPercent(n.sugars, of: 90))

                    Divider()

                    nutritionLabelRow(label: "Fibre", value: formatMacro(n.fibre), unit: "g")

                    Divider()

                    nutritionLabelRow(label: "Protein", value: formatMacro(n.protein), unit: "g",
                                      percent: isWhole ? nil : drvPercent(n.protein, of: 50))

                    Divider()

                    nutritionLabelRow(label: "Salt", value: formatSalt(n.salt), unit: "g",
                                      percent: isWhole ? nil : drvPercent(n.salt, of: 6))

                    if n.coverage < 0.8 {
                        Text("Estimated — \(Int(n.coverage * 100))% of ingredients matched")
                            .font(.caption2)
                            .adaptiveSecondaryForeground()
                            .padding(.top, AppTheme.spacing4)
                    }

                    if !isWhole {
                        Text("* Reference intakes for an average adult (8400 kJ / 2000 kcal)")
                            .font(.caption2)
                            .adaptiveSecondaryForeground()
                            .padding(.top, AppTheme.spacing4)
                    }
                }
            }
        }
    }

    private func nutritionLabelRow(label: String, value: String, unit: String, hero: Bool = false, percent: String? = nil) -> some View {
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
            Text(percent ?? "")
                .font(hero ? .caption : .caption2)
                .adaptiveSecondaryForeground()
                .frame(minWidth: 36, alignment: .trailing)
                .opacity(percent == nil ? 0 : 1)
        }
    }

    private func nutritionLabelSubrow(label: String, value: String, unit: String, percent: String? = nil) -> some View {
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
            Text(percent ?? "")
                .font(.caption2)
                .adaptiveSecondaryForeground()
                .frame(minWidth: 36, alignment: .trailing)
                .opacity(percent == nil ? 0 : 1)
        }
    }

    private func drvPercent(_ value: Double, of reference: Double) -> String {
        guard reference > 0 else { return "" }
        return "\(max(1, Int((value / reference * 100).rounded())))%"
    }

    private func formatMacro(_ value: Double) -> String {
        value >= 10 ? "\(Int(value.rounded()))" : String(format: "%.1f", value)
    }

    private func formatSalt(_ value: Double) -> String {
        value >= 1.0 ? String(format: "%.1f", value) : String(format: "%.2f", value)
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

    var timeInfoCard: some View {
        InfoPairView(
            label1: "Prep time", value1: recipe.prepTimeDisplay, icon1: "clock",
            label2: "Cook time", value2: recipe.cookTimeDisplay, icon2: "flame"
        )
        .padding()
        .appCard(elevated: true)
        .editableCard(onEdit: { beginEdit(section: .details) }, hint: "Edit prep and cook time")
        .accessibilityIdentifier("recipe.card.time")
    }

    var detailsInfoCard: some View {
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
        .appCard(elevated: true)
        .editableCard(onEdit: { beginEdit(section: .details) }, hint: "Edit difficulty, category and cuisine")
    }

    // Opens the pre-filled editor; `section` deep-links to those fields (else top).
    func beginEdit(section: RecipeWizardView.Section? = nil) {
        HapticManager.shared.light()
        editTarget = EditTarget(section: section)
    }

    var ingredientsSection: some View {
        RecipeIngredientsSection(
            recipe: recipe,
            ingredientsState: ingredientsState,
            measurementSystem: measurementSystem,
            isExpanded: expandedSections.contains("Ingredients"),
            onToggleSection: { toggleSection("Ingredients") },
            onToggleMeasurement: toggleMeasurementSystem,
            onToggleIngredient: { index in
                guard index < ingredientsState.count else { return }
                HapticManager.shared.light()
                ingredientsState[index].toggle()
                checkForCompletion()
            },
            onAddToShopping: { index in
                guard index < recipe.ingredients.count else { return }
                addIngredientToShoppingList(recipe.ingredients[index])
            },
            onAddAllToShopping: addAllIngredientsToShoppingList,
            isInShoppingList: { isIngredientInShoppingList($0) },
            onEditIngredient: { _ in beginEdit(section: .ingredients) },
            onSubstitute: { index in substitutingIngredientIndex = index },
            onEditIngredients: { beginEdit(section: .ingredients) }
        )
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
            // not a recipe you've never tried. Before the first cook the card leads with "Mark as Cooked".
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

            let cookedToday = recipe.wasCookedToday()
            Button(action: recordCook) {
                Label(cookedToday ? "Cooked today" : "Mark as Cooked", systemImage: "checkmark.circle.fill")
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
            .disabled(cookedToday)
            .accessibilityIdentifier("recipe.markCooked")
            .opacity(cookedToday ? AppTheme.glassLightOpacity : 1)
            .accessibilityHint(cookedToday ? "Already logged today" : "Increments the cook count and records today")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(elevated: true)
    }

}

// MARK: - Nutrition macro bar

// Proportional calorie-split bar (fat/carbs/protein) using 4/4/9 kcal-per-gram, so segments reflect energy not mass.
private struct NutritionMacroBar: View {
    let nutrition: NutritionInfo

    private var fatKcal:    Double { nutrition.fat     * 9 }
    private var carbsKcal:  Double { nutrition.carbs   * 4 }
    private var proteinKcal: Double { nutrition.protein * 4 }
    private var total: Double { max(fatKcal + carbsKcal + proteinKcal, 1) }

    private var fatFraction:    Double { fatKcal    / total }
    private var carbsFraction:  Double { carbsKcal  / total }
    private var proteinFraction: Double { proteinKcal / total }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            GeometryReader { geo in
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange)
                        .frame(width: max(geo.size.width * fatFraction - 2, 4))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.teal)
                        .frame(width: max(geo.size.width * carbsFraction - 2, 4))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(maxWidth: .infinity)
                }
                .clipShape(Capsule())
            }
            .frame(height: 10)

            HStack(spacing: 0) {
                macroLabel(name: "Fat", value: nutrition.fat, color: .orange)
                Spacer()
                macroLabel(name: "Carbs", value: nutrition.carbs, color: .teal)
                Spacer()
                macroLabel(name: "Protein", value: nutrition.protein, color: .blue)
            }
        }
    }

    private func macroLabel(name: String, value: Double, color: Color) -> some View {
        HStack(spacing: AppTheme.spacing4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text("\(name) \(Int(value.rounded()))g")
                .font(.caption2)
                .adaptiveSecondaryForeground()
        }
    }
}
