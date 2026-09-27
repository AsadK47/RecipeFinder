import SwiftUI

/// Pantry-aware suggestion strip shown when inventory expires within three days; each card jumps to the meal-time picker for that recipe.
struct ExpiryRecipeSuggestionsSection: View {
    let suggestions: [PantryExpirySuggestions.Match]
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let selectedTheme: AppTheme.ThemeType
    let onPlan: (RecipeModel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            HStack(spacing: AppTheme.spacing6) {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .foregroundStyle(.orange)
                Text("Cook Before They Expire")
                    .font(.system(size: AppTheme.fontSize20, weight: .bold))
                    .adaptiveForegroundColor()
            }
            .padding(.horizontal, AppTheme.spacing4)

            VStack(spacing: AppTheme.spacing10) {
                ForEach(suggestions, id: \.recipe.id) { suggestion in
                    suggestionCard(suggestion)
                }
            }
        }
    }

    @ViewBuilder
    private func suggestionCard(_ suggestion: PantryExpirySuggestions.Match) -> some View {
        HStack(spacing: AppTheme.spacing12) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius10)
                    .fill(Color.orange.opacity(0.15))
                Image(systemName: "fork.knife")
                    .font(.system(size: AppTheme.fontSize18, weight: .medium))
                    .foregroundStyle(.orange)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(suggestion.recipe.name)
                    .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                    .lineLimit(1)
                    .adaptiveForegroundColor()

                if !suggestion.expiringItems.isEmpty {
                    Text("Uses: \(suggestion.expiringItems.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button("Plan") {
                onPlan(suggestion.recipe)
            }
            .font(.system(size: AppTheme.fontSize14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, AppTheme.spacing12)
            .padding(.vertical, AppTheme.spacing6)
            .background(AppTheme.warning)
            .cornerRadius(AppTheme.cornerRadius8)
        }
        .padding(AppTheme.spacing12)
        .appCard()
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                .stroke(Color.orange.opacity(0.25), lineWidth: 1)
        )
    }
}
