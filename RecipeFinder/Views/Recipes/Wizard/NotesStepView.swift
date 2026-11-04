import SwiftUI

/// A snapshot of the recipe used to render the summary on the final wizard step.
struct WizardRecipeSummary {
    let name: String
    let category: String
    let difficulty: String
    let servings: Int
    let prepTime: Int
    let cookTime: Int
    let ingredientCount: Int
    let prePrepStepCount: Int
    let cookingStepCount: Int
}

private let tagSuggestions = [
    "Quick", "Comfort Food", "Spicy", "Budget Friendly", "Family Friendly",
    "Date Night", "Batch Cook", "Healthy", "Sunday Roast", "Meal Prep",
    "Vegetarian", "Vegan", "Gluten Free", "Freezer Friendly"
]

private let cuisineSuggestions = [
    "Italian", "Mexican", "Indian", "Chinese", "Japanese", "Thai",
    "French", "Greek", "American", "British", "Middle Eastern", "Mediterranean"
]

/// Step 6 of the Recipe Wizard: tags, free-form notes, and the recipe summary.
struct NotesStepView: View {
    @Binding var notes: String
    @Binding var tags: [String]
    @Binding var cuisine: String
    let hasPrefilledNotes: Bool
    let summary: WizardRecipeSummary
    let colorScheme: ColorScheme

    @State private var tagInput: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            WizardStepHeader(
                title: "Final Touches",
                subtitle: "Add tags or notes to help you find this recipe later",
                illustration: "note.text"
            )

            WizardCard {
                VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                    cuisineSection
                    Divider()
                    tagsSection
                }
                .padding()
            }

            WizardCard {
                VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                    if hasPrefilledNotes && !notes.isEmpty {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Pre-filled notes from recipe")
                                .font(.caption)
                                .adaptiveSecondaryForeground()
                            Spacer()
                        }
                        .padding(.bottom, AppTheme.spacing8)
                    }

                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                Text("Add your notes here...")
                                    .foregroundStyle(.secondary.opacity(AppTheme.glassLightOpacity))
                                    .padding(.horizontal, AppTheme.spacing4)
                                    .padding(.vertical, AppTheme.spacing8)

                                Text("Try adding:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary.opacity(AppTheme.lowEmphasisOpacity))
                                    .padding(.horizontal, AppTheme.spacing4)

                                Text("• Substitution ideas")
                                    .font(.caption)
                                    .foregroundStyle(.secondary.opacity(AppTheme.lowEmphasisOpacity))
                                    .padding(.horizontal, AppTheme.spacing4)
                                Text("• Storage tips")
                                    .font(.caption)
                                    .foregroundStyle(.secondary.opacity(AppTheme.lowEmphasisOpacity))
                                    .padding(.horizontal, AppTheme.spacing4)
                                Text("• Serving suggestions")
                                    .font(.caption)
                                    .foregroundStyle(.secondary.opacity(AppTheme.lowEmphasisOpacity))
                                    .padding(.horizontal, AppTheme.spacing4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .allowsHitTesting(false)
                        }

                        TextField("", text: $notes, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(8...15)
                            .padding(AppTheme.spacing4)
                    }
                    .appInputField()

                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("Quick Add:")
                            .font(.caption)
                            .adaptiveSecondaryForeground()

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.spacing8) {
                                quickNoteButton(icon: "leaf.fill", text: "Make it healthier", template: "💚 Healthier Option:\n• ")
                                quickNoteButton(icon: "carrot.fill", text: "Make it vegan", template: "🌱 Vegan Version:\n• ")
                                quickNoteButton(icon: "clock.fill", text: "Save time", template: "⏰ Time-Saving Tip:\n• ")
                                quickNoteButton(icon: "arrow.triangle.swap", text: "Substitutions", template: "🔄 Substitutions:\n• ")
                                quickNoteButton(icon: "snowflake", text: "Storage", template: "❄️ Storage:\n• ")
                                quickNoteButton(icon: "star.fill", text: "Pro tip", template: "✨ Pro Tip:\n• ")
                            }
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                        Text("Recipe Summary")
                            .font(.headline)

                        WizardSummaryRow(icon: "fork.knife", label: "Name", value: summary.name.isEmpty ? "—" : summary.name)
                        WizardSummaryRow(icon: "tag", label: "Category", value: summary.category)
                        WizardSummaryRow(icon: "chart.bar", label: "Difficulty", value: summary.difficulty)
                        WizardSummaryRow(icon: "person.2", label: "Servings", value: "\(summary.servings)")
                        WizardSummaryRow(icon: "clock", label: "Prep Time", value: "\(summary.prepTime) min")
                        WizardSummaryRow(icon: "flame", label: "Cook Time", value: "\(summary.cookTime) min")
                        WizardSummaryRow(icon: "list.bullet", label: "Ingredients", value: "\(summary.ingredientCount)")
                        WizardSummaryRow(icon: "list.number", label: "Pre-prep Steps", value: "\(summary.prePrepStepCount)")
                        WizardSummaryRow(icon: "list.number", label: "Cooking Steps", value: "\(summary.cookingStepCount)")
                    }
                }
                .padding()
            }
        }
    }

    private func quickNoteButton(icon: String, text: String, template: String) -> some View {
        Button(action: {
            HapticManager.shared.light()
            if !notes.isEmpty {
                notes += "\n\n"
            }
            notes += template
        }) {
            HStack(spacing: AppTheme.spacing4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(text)
                    .font(.caption)
            }
            .padding(.horizontal, AppTheme.spacing12)
            .padding(.vertical, AppTheme.spacing6)
            .background(AppTheme.secondaryBackground(for: colorScheme))
            .cornerRadius(AppTheme.cornerRadius16)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var cuisineSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Cuisine")
                .font(.headline)

            Text("Helps filter recipes by origin. (Optional)")
                .font(.caption)
                .adaptiveSecondaryForeground()

            TextField("e.g. Italian, Mexican, Indian…", text: $cuisine)
                .textFieldStyle(.plain)
                .appInputField()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spacing8) {
                    ForEach(cuisineSuggestions.filter { $0 != cuisine }, id: \.self) { suggestion in
                        Button(action: {
                            HapticManager.shared.light()
                            cuisine = suggestion
                        }) {
                            Text(suggestion)
                                .font(.caption)
                                .padding(.horizontal, AppTheme.spacing12)
                                .padding(.vertical, AppTheme.spacing6)
                                .background(AppTheme.secondaryBackground(for: colorScheme))
                                .cornerRadius(AppTheme.cornerRadius16)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Tags")
                .font(.headline)

            Text("Add searchable tags to organise and filter this recipe. (Optional)")
                .font(.caption)
                .adaptiveSecondaryForeground()

            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.spacing8) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: AppTheme.spacing4) {
                                Text(tag)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Button(action: {
                                    HapticManager.shared.light()
                                    tags.removeAll { $0 == tag }
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .accessibilityLabel("Remove \(tag) tag")
                            }
                            .padding(.horizontal, AppTheme.spacing10)
                            .padding(.vertical, AppTheme.spacing6)
                            .background(Color.accentColor.opacity(0.15))
                            .cornerRadius(AppTheme.cornerRadius16)
                        }
                    }
                }
            }

            HStack(spacing: AppTheme.spacing8) {
                TextField("Add a tag…", text: $tagInput)
                    .textFieldStyle(.plain)
                    .appInputField()
                    .onSubmit { addTag() }

                Button("Add", action: addTag)
                    .disabled(tagInput.isBlank)
            }

            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                Text("Suggestions:")
                    .font(.caption)
                    .adaptiveSecondaryForeground()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.spacing8) {
                        ForEach(tagSuggestions.filter { !tags.contains($0) }, id: \.self) { suggestion in
                            Button(action: {
                                HapticManager.shared.light()
                                tags.append(suggestion)
                            }) {
                                Text(suggestion)
                                    .font(.caption)
                                    .padding(.horizontal, AppTheme.spacing12)
                                    .padding(.vertical, AppTheme.spacing6)
                                    .background(AppTheme.secondaryBackground(for: colorScheme))
                                    .cornerRadius(AppTheme.cornerRadius16)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }

    private func addTag() {
        let trimmed = tagInput.trimmed
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        HapticManager.shared.light()
        tags.append(trimmed)
        tagInput = ""
    }
}
