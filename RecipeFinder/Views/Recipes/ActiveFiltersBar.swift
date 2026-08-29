import SwiftUI

/// Horizontally-scrolling chips summarising the active filters, each removable,
/// plus a "Clear All". Extracted from `RecipeSearchView`.
struct ActiveFiltersBar: View {
    @Binding var showFavoritesOnly: Bool
    @Binding var availableIngredientsOnly: Bool
    @Binding var ingredientSearchText: String
    @Binding var selectedCategories: Set<String>
    @Binding var selectedDifficulties: Set<String>
    @Binding var selectedCookTimes: Set<Int>
    @Binding var selectedDietaryFilters: Set<String>
    @Binding var selectedTags: Set<String>
    let onClearAll: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacing8) {
                if showFavoritesOnly {
                    FilterChip(label: "Favorites", icon: "heart.fill") {
                        HapticManager.shared.light()
                        showFavoritesOnly = false
                    }
                }
                
                if availableIngredientsOnly {
                    FilterChip(label: "Can Make Now", icon: "checkmark.circle.fill") {
                        HapticManager.shared.light()
                        availableIngredientsOnly = false
                    }
                }
                
                if !ingredientSearchText.isEmpty {
                    FilterChip(label: "Has: \(ingredientSearchText)", icon: "leaf.fill") {
                        HapticManager.shared.light()
                        ingredientSearchText = ""
                    }
                }
                
                ForEach(Array(selectedCategories), id: \.self) { category in
                    FilterChip(label: category, icon: "fork.knife") {
                        HapticManager.shared.light()
                        selectedCategories.remove(category)
                    }
                }
                
                ForEach(Array(selectedDifficulties), id: \.self) { difficulty in
                    FilterChip(label: difficulty, icon: "chart.bar.fill") {
                        HapticManager.shared.light()
                        selectedDifficulties.remove(difficulty)
                    }
                }
                
                ForEach(Array(selectedCookTimes), id: \.self) { time in
                    FilterChip(label: time > 120 ? "> 120 min" : "≤ \(time) min", icon: "clock.fill") {
                        HapticManager.shared.light()
                        selectedCookTimes.remove(time)
                    }
                }
                
                ForEach(Array(selectedDietaryFilters), id: \.self) { diet in
                    FilterChip(label: diet, icon: "leaf.circle.fill") {
                        HapticManager.shared.light()
                        selectedDietaryFilters.remove(diet)
                    }
                }
                
                ForEach(Array(selectedTags), id: \.self) { tag in
                    FilterChip(label: tag, icon: "tag.fill") {
                        HapticManager.shared.light()
                        selectedTags.remove(tag)
                    }
                }
                
                Button(action: onClearAll, label: {
                    Text("Clear All")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .adaptiveForegroundColor()
                        .padding(.horizontal, AppTheme.spacing12)
                        .padding(.vertical, AppTheme.spacing6)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(AppTheme.highEmphasisOpacity))
                        )
                })
            }
            .padding(.horizontal, AppTheme.spacing20)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
