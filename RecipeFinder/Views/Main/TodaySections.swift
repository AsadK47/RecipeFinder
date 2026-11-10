import SwiftUI

/// Today's "Tonight" card: the hero recipe's photo, why it was picked, and a button into it.
struct TodayHeroCard: View {
    let hero: TodayFeed.Hero
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 0) {
                RecipeImageView(imageName: hero.recipe.heroImageName, height: 180, recipeName: hero.recipe.name)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipped()
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                    Label(hero.reason.caption, systemImage: icon)
                        .font(.caption.weight(.semibold))
                        .adaptiveSecondaryForeground()
                    Text(hero.recipe.name)
                        .font(.title3.weight(.bold))
                        .adaptiveForegroundColor()
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: AppTheme.spacing4) {
                        Text("Let's cook")
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppTheme.spacing16)
                    .padding(.vertical, AppTheme.spacing8)
                    .background(Capsule().fill(AppTheme.accentColor))
                    .padding(.top, AppTheme.spacing4)
                }
                .padding(AppTheme.spacing16)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius16))
            .appCard(elevated: true)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tonight: \(hero.recipe.name). \(hero.reason.caption)")
        .accessibilityHint("Opens the recipe")
        .accessibilityIdentifier("today.hero")
    }

    private var icon: String {
        switch hero.reason {
        case .planned(let time): time.icon
        case .kitchenMatch: "refrigerator.fill"
        }
    }
}

/// A titled horizontal row of recipe tiles; hidden by the caller when empty.
struct TodayShelf: View {
    let title: String
    let id: String
    let items: [(recipe: RecipeModel, caption: String?)]
    let onOpen: (RecipeModel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            Text(title)
                .font(.headline)
                .adaptiveForegroundColor()
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: AppTheme.spacing12) {
                    ForEach(items, id: \.recipe.id) { item in
                        tile(item.recipe, caption: item.caption)
                    }
                }
                .padding(.vertical, AppTheme.spacing2)
            }
            .scrollClipDisabled()
        }
        .accessibilityIdentifier("today.shelf.\(id)")
    }

    private func tile(_ recipe: RecipeModel, caption: String?) -> some View {
        Button { onOpen(recipe) } label: {
            VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                RecipeImageView(imageName: recipe.heroImageName, height: 100, recipeName: recipe.name)
                    .frame(width: 140, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
                    .accessibilityHidden(true)
                Text(recipe.name)
                    .font(.subheadline.weight(.semibold))
                    .adaptiveForegroundColor()
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                if let caption {
                    Text(caption)
                        .font(.caption)
                        .adaptiveSecondaryForeground()
                        .lineLimit(1)
                }
            }
            .frame(width: 140, alignment: .leading)
            .padding(AppTheme.spacing8)
            .appCard()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the recipe")
    }
}
