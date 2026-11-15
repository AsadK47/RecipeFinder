import SwiftUI

/// One discovery chapter: title, reason line and its recipes in the chapter's layout (feature, wall or swipe row).
struct DiscoveryChapterView: View {
    let chapter: DiscoveryChapter

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                Text(chapter.title)
                    .font(.title3.weight(.bold))
                    .adaptiveForegroundColor()
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(chapter.reason)
                    .font(.subheadline)
                    .adaptiveSecondaryForeground()
                    .fixedSize(horizontal: false, vertical: true)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("discovery.chapter.\(chapter.slug)")
    }

    @ViewBuilder
    private var content: some View {
        switch chapter.layout {
        case .feature: feature
        case .wall: wall
        case .row: row
        }
    }

    private var feature: some View {
        VStack(spacing: AppTheme.spacing12) {
            if let lead = chapter.recipes.first {
                DiscoveryTile(recipe: lead, imageHeight: 220)
            }
            HStack(alignment: .top, spacing: AppTheme.spacing12) {
                ForEach(chapter.recipes.dropFirst()) { recipe in
                    DiscoveryTile(recipe: recipe, imageHeight: 110)
                }
            }
        }
    }

    private var wall: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: AppTheme.spacing12), GridItem(.flexible())],
            alignment: .leading,
            spacing: AppTheme.spacing16
        ) {
            ForEach(chapter.recipes) { recipe in
                DiscoveryTile(recipe: recipe, imageHeight: 150)
            }
        }
    }

    private var row: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: AppTheme.spacing12) {
                ForEach(chapter.recipes) { recipe in
                    DiscoveryTile(recipe: recipe, imageHeight: 120)
                        .frame(width: 160)
                }
            }
            .padding(.vertical, AppTheme.spacing2)
        }
        .scrollClipDisabled()
    }
}

/// A big picture, the name and how long it takes; opens the recipe.
private struct DiscoveryTile: View {
    let recipe: RecipeModel
    let imageHeight: CGFloat

    var body: some View {
        RecipeLink(recipe: recipe, identifier: "discovery.tile") {
            VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                RecipeImageView(recipe: recipe, imageName: recipe.heroImageName, height: imageHeight)
                    .frame(maxWidth: .infinity)
                    .frame(height: imageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
                    .accessibilityHidden(true)
                Text(recipe.name)
                    .font(.subheadline.weight(.semibold))
                    .adaptiveForegroundColor()
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                if recipe.hasTotalTime {
                    Label(DurationFormatter.label(minutes: recipe.totalMinutes), systemImage: "clock")
                        .font(.caption)
                        .adaptiveSecondaryForeground()
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .accessibilityHint("Opens the recipe")
    }
}
