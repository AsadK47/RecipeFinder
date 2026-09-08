import SwiftUI

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
        }
        .padding(.horizontal, AppTheme.spacing20)
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
            InfoPairView(
                label1: "Difficulty", value1: recipe.difficulty, icon1: "chart.bar",
                label2: "Category", value2: recipe.category, icon2: "fork.knife"
            )
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
            onEditIngredient: { index in startEditingIngredient(at: index) }
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
            Text(RecipeNotesFormatter.attributedString(from: recipe.notes))
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
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
                imageURL: recipe.imageName
            ),
            editingRecipeId: recipe.id,
            onComplete: { updatedRecipe in
                recipe = updatedRecipe
                PersistenceController.shared.saveRecipeModel(updatedRecipe)
                HapticManager.shared.success()
            }
        )
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
