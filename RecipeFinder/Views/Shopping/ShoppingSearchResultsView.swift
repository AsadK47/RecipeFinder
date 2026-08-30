import SwiftUI

/// The Shopping List search suggestions: an "add free text" row plus matching
/// foods to add to the list. Extracted from `ShoppingListView`.
struct ShoppingSearchResultsView: View {
    let searchText: String
    let searchResults: [String]
    let isInList: (String) -> Bool
    let onAdd: (String) -> Void
    let selectedTheme: AppTheme.ThemeType
    let cardStyle: CardStyle
    let colorScheme: ColorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                Text("Suggested Ingredients")
                    .font(.title3)
                    .fontWeight(.bold)
                    .adaptiveForegroundColor()
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.top, AppTheme.spacing20)
                
                LazyVStack(spacing: AppTheme.spacing8) {
                    let trimmed = searchText.trimmingCharacters(in: .whitespaces)
                    if !searchResults.contains(where: { $0.lowercased() == trimmed.lowercased() }) {
                        Button(action: { onAdd(trimmed) }) {
                            HStack(spacing: AppTheme.spacing12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(AppTheme.accentColor)
                                Text("Add \"\(trimmed)\"")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .adaptiveForegroundColor()
                                Spacer()
                            }
                            .padding(.vertical, AppTheme.spacing12)
                        }
                        .buttonStyle(.plain)
                        
                        if !searchResults.isEmpty {
                            Divider()
                        }
                    }
                    
                    ForEach(searchResults, id: \.self) { ingredient in
                        ingredientButton(ingredient)
                    }
                }
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.bottom, AppTheme.spacing20)
            }
        }
    }

    private func ingredientButton(_ ingredient: String) -> some View {
        let category = CategoryClassifier.suggestCategory(for: ingredient)
        let isIn = isInList(ingredient)
        
        return Button(
            action: {
                onAdd(ingredient)
            },
            label: {
                HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: CategoryClassifier.categoryIcon(for: category))
                        .foregroundStyle(CategoryClassifier.categoryColor(for: category))
                        .font(.body)
                    
                    Text(ingredient)
                        .font(.body)
                        .foregroundStyle(AppTheme.textColor(for: colorScheme))
                    
                    Spacer()
                    
                    Image(systemName: isIn ? "checkmark.circle.fill" : "plus.circle")
                        .foregroundStyle(isIn ? .green : AppTheme.accentColor(for: selectedTheme))
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
        )
        .buttonStyle(PlainButtonStyle())
        .disabled(isIn)
    }
}
