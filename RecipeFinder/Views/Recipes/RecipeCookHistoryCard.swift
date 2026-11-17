import SwiftUI

/// A recipe's cook history: the rating (once it's been cooked), how many times, and when last.
/// Logging a cook is the "Made it" button in the detail's action row.
struct RecipeCookHistoryCard: View {
    let cookCount: Int
    let lastCookedAt: Date?
    let rating: Int
    let onRate: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            if RecipeDetailCopy.showsRating(cookCount: cookCount) {
                HStack {
                    Label("Rating", systemImage: "star")
                        .font(.caption)
                        .adaptiveSecondaryForeground()
                    Spacer()
                    StarRatingView(rating: rating, onTap: onRate)
                        .accessibilityIdentifier("recipe.rating")
                }

                Divider()
            }

            HStack(alignment: .firstTextBaseline) {
                Label(RecipeDetailCopy.cookCount(cookCount), systemImage: "frying.pan")
                    .font(.caption)
                    .adaptiveSecondaryForeground()

                if let lastCookedAt {
                    Spacer()
                    // Named relative ("2 minutes ago"); `style: .relative` read like a duration ("44 secs").
                    Text(lastCookedAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .adaptiveSecondaryForeground()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(elevated: true)
    }
}
