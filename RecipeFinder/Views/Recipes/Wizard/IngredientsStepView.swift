import SwiftUI

/// Step 3 of the Recipe Wizard: ingredient list with amount/unit and autocomplete suggestions.
struct IngredientsStepView: View {
    @Binding var ingredientItems: [RecipeWizardView.IngredientItem]
    @FocusState.Binding var focusedIngredientID: UUID?
    let cookingUnitGroups: [(group: String, units: [String])]
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            WizardStepHeader(
                title: "Ingredients",
                subtitle: "Add your ingredients with quantities",
                illustration: "cart.fill"
            )

            WizardCard {
                VStack(spacing: AppTheme.spacing12) {
                    ForEach($ingredientItems) { $item in
                        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                            HStack(spacing: AppTheme.spacing8) {
                                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                    Text("Ingredient")
                                        .font(.caption2)
                                        .adaptiveSecondaryForeground()
                                    TextField("e.g. Chicken breast", text: $item.name)
                                        .textFieldStyle(.plain)
                                        .appInputField()
                                        .focused($focusedIngredientID, equals: item.id)
                                }

                                if ingredientItems.count > 1 {
                                    Button(action: {
                                        HapticManager.shared.light()
                                        ingredientItems.removeAll { $0.id == item.id }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(AppTheme.error)
                                            .font(.system(size: AppTheme.fontSize22))
                                    }
                                    .padding(.top, AppTheme.spacing14)
                                }
                            }

                            if focusedIngredientID == item.id {
                                let suggestions = ingredientAutocompleteSuggestions(for: item.name, excluding: ingredientItems.map { $0.name })

                                if !suggestions.isEmpty {
                                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                                        Text("Suggestions")
                                            .font(.caption2)
                                            .adaptiveSecondaryForeground()

                                        VStack(spacing: AppTheme.spacing6) {
                                            ForEach(suggestions, id: \.id) { suggestion in
                                                Button(action: {
                                                    $item.wrappedValue.name = suggestion.name
                                                    HapticManager.shared.light()
                                                }) {
                                                    HStack(alignment: .center, spacing: AppTheme.spacing10) {
                                                        VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                                            Text(suggestion.name)
                                                                .font(.subheadline)
                                                                .foregroundStyle(.primary)
                                                                .lineLimit(1)

                                                            Text("\(suggestion.category) · \(suggestion.source)")
                                                                .font(.caption2)
                                                                .adaptiveSecondaryForeground()
                                                                .lineLimit(1)
                                                        }

                                                        Spacer(minLength: 0)

                                                        Image(systemName: "arrow.up.left.circle.fill")
                                                            .foregroundStyle(AppTheme.accentColor)
                                                    }
                                                    .padding(.vertical, AppTheme.spacing10)
                                                    .padding(.horizontal, AppTheme.spacing12)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius10)
                                                            .fill(AppTheme.secondaryBackground(for: colorScheme))
                                                    )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                    .padding(.top, AppTheme.spacing4)
                                }
                            }

                            HStack(alignment: .top, spacing: AppTheme.spacing8) {
                                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                    Text("Amount")
                                        .font(.caption2)
                                        .adaptiveSecondaryForeground()
                                    TextField("0", text: $item.quantity)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.plain)
                                        .frame(width: AppTheme.width70)
                                        .appInputField()
                                }

                                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                    Text("Unit")
                                        .font(.caption2)
                                        .adaptiveSecondaryForeground()
                                    Picker("", selection: $item.unit) {
                                        Text("none").tag("")
                                        ForEach(cookingUnitGroups, id: \.group) { group in
                                            Section(group.group) {
                                                ForEach(group.units, id: \.self) { unit in
                                                    Text(unit).tag(unit)
                                                }
                                            }
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity, minHeight: AppTheme.height34, alignment: .leading)
                                    .appInputField()
                                }
                            }
                        }
                        .padding(.vertical, AppTheme.spacing4)

                        if item.id != ingredientItems.last?.id {
                            Divider()
                        }
                    }

                    Button(action: {
                        HapticManager.shared.light()
                        let newItem = RecipeWizardView.IngredientItem()
                        ingredientItems.append(newItem)
                        focusedIngredientID = newItem.id
                    }) {
                        Label("Add Ingredient", systemImage: "plus.circle.fill")
                            .foregroundStyle(AppTheme.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .padding()
            }
        }
    }

    private func ingredientAutocompleteSuggestions(for query: String, excluding existingIngredients: [String]) -> [IngredientAutocompleteSuggestion] {
        let excludedNames = Set(existingIngredients.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty })

        return IngredientAutocompleteEngine
            .suggestions(for: query, limit: 4)
            .filter { !excludedNames.contains($0.name.lowercased()) }
    }
}
