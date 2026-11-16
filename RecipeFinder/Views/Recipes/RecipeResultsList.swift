import SwiftUI

/// The Recipes home's scroll: the library or search results as a flat list, or — on the Discover side of the toggle —
/// Recently cooked and endless discovery chapters.
struct RecipeResultsList: View {
    /// What Discover shows instead of the list; nil shows `filteredRecipes`.
    struct Discovery {
        let recentlyCooked: [RecipeModel]
        let feed: DiscoveryFeedModel
    }

    let filteredRecipes: [RecipeModel]
    var discovery: Discovery? = nil
    let onRequestDelete: (RecipeModel) -> Void
    let onRefresh: () async -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.cardVerticalSpacing) {
                if let discovery {
                    if !discovery.recentlyCooked.isEmpty {
                        DiscoveryChapterView(chapter: DiscoveryChapter(
                            id: -1, kind: .recentlyCooked, layout: .row, recipes: discovery.recentlyCooked
                        ))
                    }
                    ForEach(discovery.feed.chapters) { chapter in
                        DiscoveryChapterView(chapter: chapter)
                            .padding(.top, AppTheme.spacing12)
                            .onAppear { discovery.feed.chapterAppeared(chapter) }
                    }
                } else {
                    ForEach(filteredRecipes) { recipe in
                        navigationLink(for: recipe)
                    }
                }
            }
            .padding(.horizontal, AppTheme.cardHorizontalPadding)
            .padding(.bottom, AppTheme.cardHorizontalPadding)
        }
        .refreshable { await onRefresh() }
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
