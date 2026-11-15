import SwiftUI

/// Scrollable search results as a flat list — no section labels or sample/user distinctions. While browsing (nothing
/// typed, filtered or re-sorted) it opens with Recently cooked and a short library preview, then endless discovery chapters.
struct RecipeResultsList: View {
    /// What browsing adds around the library; nil while searching or filtering (results only).
    struct Browsing {
        let recentlyCooked: [RecipeModel]
        /// `RecipeBrowse.preview` of the list — shown until "See all".
        let preview: [RecipeModel]
        let feed: DiscoveryFeedModel
    }

    let filteredRecipes: [RecipeModel]
    var browsing: Browsing? = nil
    let onRequestDelete: (RecipeModel) -> Void
    let onRefresh: () async -> Void

    @State private var showsWholeLibrary = false

    private var visibleRecipes: [RecipeModel] {
        guard let browsing, !showsWholeLibrary else { return filteredRecipes }
        return browsing.preview
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
                if let browsing, !showsWholeLibrary, filteredRecipes.count > browsing.preview.count {
                    seeAllButton
                }
                if let feed = browsing?.feed, RecipeBrowse.showsDiscovery(libraryCount: filteredRecipes.count) {
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
