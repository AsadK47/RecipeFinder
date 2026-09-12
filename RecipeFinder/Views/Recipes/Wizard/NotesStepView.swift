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

/// Step 6 of the Recipe Wizard: free-form notes plus the recipe summary.
struct NotesStepView: View {
    @Binding var notes: String
    let hasPrefilledNotes: Bool
    let summary: WizardRecipeSummary
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let totalSteps: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            WizardStepHeader(
                title: "Final Notes",
                subtitle: hasPrefilledNotes && !notes.isEmpty ? "Review notes or add your own" : "Any tips, variations, or additional notes? (Optional)",
                stepNumber: 6,
                totalSteps: totalSteps,
                illustration: "note.text"
            )

            WizardCard(cardStyle: cardStyle, colorScheme: colorScheme) {
                VStack(spacing: AppTheme.spacing24) {
                    if hasPrefilledNotes && !notes.isEmpty {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
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
                                    .foregroundColor(.secondary.opacity(AppTheme.glassLightOpacity))
                                    .padding(.horizontal, AppTheme.spacing4)
                                    .padding(.vertical, AppTheme.spacing8)

                                Text("Try adding:")
                                    .font(.caption)
                                    .foregroundColor(.secondary.opacity(AppTheme.lowEmphasisOpacity))
                                    .padding(.horizontal, AppTheme.spacing4)

                                Text("• Substitution ideas")
                                    .font(.caption)
                                    .foregroundColor(.secondary.opacity(AppTheme.lowEmphasisOpacity))
                                    .padding(.horizontal, AppTheme.spacing4)
                                Text("• Storage tips")
                                    .font(.caption)
                                    .foregroundColor(.secondary.opacity(AppTheme.lowEmphasisOpacity))
                                    .padding(.horizontal, AppTheme.spacing4)
                                Text("• Serving suggestions")
                                    .font(.caption)
                                    .foregroundColor(.secondary.opacity(AppTheme.lowEmphasisOpacity))
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
                    .padding(AppTheme.spacing8)
                    .background(Color(.systemGray6))
                    .cornerRadius(AppTheme.cornerRadius8)

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
            .background(Color(.systemGray5))
            .cornerRadius(AppTheme.cornerRadius16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
