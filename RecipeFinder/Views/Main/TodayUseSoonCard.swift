import SwiftUI

/// Today's "Use it up": kitchen items going off soon, each with a recipe that uses them. Tapping a row opens the recipe.
/// One card with photo rows, so it sits calmly between the Tonight card and the shelves.
struct TodayUseSoonCard: View {
    let pairs: [UseSoonPair]
    let onOpen: (RecipeModel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            Text("Use it up")
                .font(.headline)
                .adaptiveForegroundColor()
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                ForEach(Array(pairs.enumerated()), id: \.element.recipe.id) { index, pair in
                    if index > 0 {
                        Divider().overlay(AppTheme.subtleStroke)
                    }
                    row(pair)
                }
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing4)
            .appCard()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today.useSoon")
    }

    private func row(_ pair: UseSoonPair) -> some View {
        Button { onOpen(pair.recipe) } label: {
            HStack(spacing: AppTheme.spacing12) {
                RecipeImageView(recipe: pair.recipe, imageName: pair.recipe.heroImageName, height: 56)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius10))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                    Text(pair.message)
                        .font(.caption.weight(.semibold))
                        .adaptiveSecondaryForeground()
                        .fixedSize(horizontal: false, vertical: true)
                    Text(pair.recipe.name)
                        .font(.body.weight(.semibold))
                        .adaptiveForegroundColor()
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, AppTheme.spacing12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pair.message). \(pair.recipe.name)")
        .accessibilityHint("Opens the recipe")
        .accessibilityIdentifier("today.useSoon.row")
    }
}
