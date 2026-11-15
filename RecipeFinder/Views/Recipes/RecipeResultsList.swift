import SwiftUI

/// Scrollable search results as a flat list — no section labels or sample/user distinctions. While browsing (nothing
/// typed or filtered) it opens with Recently cooked and a short library preview, then endless discovery chapters.
struct RecipeResultsList: View {
    /// What browsing adds around the library; nil while searching or filtering (results only).
    struct Browsing {
        let recentlyCooked: [RecipeModel]
        let feed: DiscoveryFeedModel
    }

    let filteredRecipes: [RecipeModel]
    var browsing: Browsing? = nil
    let onRequestDelete: (RecipeModel) -> Void
    let onRefresh: () async -> Void

    /// A full library of 300+ cards would bury the chapters, so browsing shows the first few and "See all".
    static let libraryPreviewLimit = 6
    @State private var showsWholeLibrary = false

    private var visibleRecipes: ArraySlice<RecipeModel> {
        guard browsing != nil, !showsWholeLibrary else { return filteredRecipes[...] }
        return filteredRecipes.prefix(Self.libraryPreviewLimit)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.cardVerticalSpacing) {
                if let recent = browsing?.recentlyCooked, !recent.isEmpty {
                    DiscoveryChapterView(chapter: DiscoveryChapter(
                        id: -1, kind: .recentlyCooked, layout: .row, recipes: recent
                    ))
                }
                ForEach(visibleRecipes) { recipe in
                    navigationLink(for: recipe)
                }
                if browsing != nil, !showsWholeLibrary, filteredRecipes.count > Self.libraryPreviewLimit {
                    seeAllButton
                }
                if let feed = browsing?.feed {
                    ForEach(feed.chapters) { chapter in
                        DiscoveryChapterView(chapter: chapter)
                            .padding(.top, AppTheme.spacing12)
                            .onAppear { feed.chapterAppeared(chapter) }
                    }
                }
            }
            .padding(.horizontal, AppTheme.cardHorizontalPadding)
            .padding(.bottom, AppTheme.cardHorizontalPadding)
        }
        .refreshable { await onRefresh() }
    }

    private var seeAllButton: some View {
        Button {
            withAnimation(.appGentle) { showsWholeLibrary = true }
        } label: {
            Label("See all \(filteredRecipes.count) recipes", systemImage: "square.grid.2x2")
                .font(.subheadline.weight(.semibold))
                .adaptiveForegroundColor()
                .padding(.horizontal, AppTheme.spacing16)
                .padding(.vertical, AppTheme.spacing10)
                .appCard(in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("recipes.seeAll")
    }

    private func navigationLink(for recipe: RecipeModel) -> some View {
        RecipeLink(recipe: recipe) {
            RecipeCard(recipe: recipe, viewMode: .list)
        }
        .contextMenu {
            Button(role: .destructive) {
                onRequestDelete(recipe)
            } label: {
                Label("Delete Recipe", systemImage: "trash.fill")
            }
        }
    }
}
