import SwiftUI

/// The Kitchen search results: a free-text "add" row plus matching foods to
/// toggle in/out of the kitchen. Extracted from `KitchenView`.
struct KitchenSearchResultsView: View {
    @Binding var searchText: String
    @FocusState.Binding var isSearchFocused: Bool
    let searchResults: [String]
    let selectedTheme: AppTheme.ThemeType
    let cardStyle: CardStyle
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Search Results")
                .font(.title3)
                .fontWeight(.bold)
                .adaptiveForegroundColor()
                .padding(.horizontal, AppTheme.spacing20)

            LazyVStack(spacing: AppTheme.spacing8) {
                // Always show a free-text "Add" row first
                let trimmed = searchText.trimmingCharacters(in: .whitespaces)
                let alreadyInKitchen = KitchenInventoryManager.shared.hasItem(trimmed)
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        KitchenInventoryManager.shared.toggleItem(trimmed)
                        HapticManager.shared.light()
                        searchText = ""
                    }
                } label: {
                    HStack(spacing: AppTheme.spacing12) {
                        Image(systemName: alreadyInKitchen ? "checkmark.circle.fill" : "plus.circle.fill")
                            .foregroundStyle(alreadyInKitchen ? .green : AppTheme.accentColor(for: selectedTheme))
                            .font(.title3)
                        Text(alreadyInKitchen ? "\"\(trimmed)\" is in your kitchen" : "Add \"\(trimmed)\"")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.textColor(for: colorScheme))
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.spacing16)
                    .padding(.vertical, AppTheme.spacing14)
                    .background {
                        if cardStyle == .solid {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                .fill(AppTheme.adaptiveCard(for: colorScheme))
                        } else {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                .fill(.ultraThinMaterial)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                ForEach(searchResults, id: \.self) { ingredient in
                    kitchenIngredientButton(ingredient)
                }
            }
            .padding(.horizontal, AppTheme.spacing20)
        }
    }

    private func kitchenIngredientButton(_ ingredient: String) -> some View {
        let isInKitchen = KitchenInventoryManager.shared.hasItem(ingredient)
        let category = CategoryClassifier.suggestCategory(for: ingredient)
        
        return Button {
            withAnimation(.spring(response: 0.3)) {
                KitchenInventoryManager.shared.toggleItem(ingredient)
                HapticManager.shared.light()
                searchText = ""
                isSearchFocused = false
            }
        } label: {
            HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: CategoryClassifier.categoryIcon(for: category))
                        .foregroundStyle(CategoryClassifier.categoryColor(for: category))
                        .font(.body)
                    
                    Text(ingredient)
                        .font(.body)
                        .foregroundStyle(AppTheme.textColor(for: colorScheme))
                    
                    Spacer()
                    
                    Image(systemName: isInKitchen ? "checkmark.circle.fill" : "plus.circle")
                        .foregroundStyle(isInKitchen ? .green : AppTheme.accentColor(for: selectedTheme))
                        .font(.title3)
                }
                .padding(.horizontal, AppTheme.spacing16)
                .padding(.vertical, AppTheme.spacing14)
                .background {
                    if cardStyle == .solid {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .fill(AppTheme.adaptiveCard(for: colorScheme))
                    } else {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .fill(.ultraThinMaterial)
                    }
                }
            }
        .buttonStyle(PlainButtonStyle())
    }
}
