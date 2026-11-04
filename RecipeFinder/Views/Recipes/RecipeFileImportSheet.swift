import SwiftUI

/// Previews a shared `.recipefinderrecipe` file (AirDrop/Messages/Mail/Files) so the user confirms before saving.
struct RecipeFileImportSheet: View {
    let recipe: RecipeModel
    let onSave: (RecipeModel) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: AppTheme.spacing24) {
                        headerCard
                        statsRow
                        if !recipe.ingredients.isEmpty {
                            ingredientPreview
                        }
                        saveButton
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.top, AppTheme.spacing20)
                    .padding(.bottom, AppTheme.spacing100)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Shared Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .adaptiveForegroundColor()
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerCard: some View {
        VStack(spacing: AppTheme.spacing8) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(AppTheme.accentColor)

            Text(recipe.name)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .adaptiveForegroundColor()

            if let cuisine = recipe.cuisine, !cuisine.isEmpty {
                Text(cuisine)
                    .font(.subheadline)
                    .adaptiveSecondaryForeground()
            }

            if !recipe.dietaryInfo.activeTags.isEmpty {
                FlowLayout(spacing: AppTheme.spacing6) {
                    ForEach(recipe.dietaryInfo.activeTags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, AppTheme.spacing8)
                            .padding(.vertical, AppTheme.spacing4)
                            .background(AppTheme.success.opacity(0.15))
                            .foregroundStyle(AppTheme.success)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.spacing20)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                .fill(colorScheme == .dark
                    ? Color.white.opacity(AppTheme.glassSubtleOpacity)
                    : Color.white.opacity(AppTheme.cardDarkOpacity))
        }
    }

    private var statsRow: some View {
        HStack(spacing: AppTheme.spacing12) {
            statPill(icon: "person.2", value: "\(recipe.baseServings)", label: "Serves")
            if !recipe.prepTime.isEmpty {
                statPill(icon: "clock", value: recipe.prepTime, label: "Prep")
            }
            if !recipe.cookingTime.isEmpty {
                statPill(icon: "flame", value: recipe.cookingTime, label: "Cook")
            }
            statPill(icon: "checklist", value: "\(recipe.ingredients.count)", label: "Ingredients")
        }
    }

    private func statPill(icon: String, value: String, label: String) -> some View {
        VStack(spacing: AppTheme.spacing4) {
            Image(systemName: icon)
                .font(.system(size: AppTheme.fontSize14))
                .foregroundStyle(AppTheme.accentColor)
            Text(value)
                .font(.caption.weight(.semibold))
                .adaptiveForegroundColor()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .adaptiveSecondaryForeground()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacing12)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                .fill(colorScheme == .dark
                    ? Color.white.opacity(AppTheme.glassSubtleOpacity)
                    : Color.white.opacity(AppTheme.cardDarkOpacity))
        }
    }

    private var ingredientPreview: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            Text("Ingredients")
                .font(.headline)
                .adaptiveForegroundColor()

            ForEach(recipe.ingredients.prefix(5)) { ingredient in
                HStack(spacing: AppTheme.spacing8) {
                    Circle()
                        .fill(AppTheme.accentColor.opacity(0.4))
                        .frame(width: 5, height: 5)
                    Text(ingredient.name)
                        .font(.subheadline)
                        .adaptiveForegroundColor()
                    Spacer()
                    let qty = FractionFormatter.format(ingredient.baseQuantity)
                    let unit = ingredient.unit.isEmpty ? "" : " \(ingredient.unit)"
                    Text("\(qty)\(unit)")
                        .font(.subheadline)
                        .adaptiveSecondaryForeground()
                }
            }

            if recipe.ingredients.count > 5 {
                Text("+ \(recipe.ingredients.count - 5) more")
                    .font(.caption)
                    .adaptiveSecondaryForeground()
                    .padding(.top, AppTheme.spacing4)
            }
        }
        .padding(AppTheme.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                .fill(colorScheme == .dark
                    ? Color.white.opacity(AppTheme.glassSubtleOpacity)
                    : Color.white.opacity(AppTheme.cardDarkOpacity))
        }
    }

    private var saveButton: some View {
        PrimaryButton("Save to My Recipes", systemImage: "plus.circle.fill", fillWidth: true) {
            onSave(recipe)
            dismiss()
        }
    }
}
