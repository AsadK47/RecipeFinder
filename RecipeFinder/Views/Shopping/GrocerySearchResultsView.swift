import SwiftUI

/// Groceries search suggestions: an "add free text" row plus catalog matches; "Add" appends to the list and dismisses search.
struct GrocerySearchResultsView: View {
    let searchText: String
    let searchResults: [String]
    let isInShopping: (String) -> Bool
    let onAddToShopping: (String) -> Void
    let selectedTheme: AppTheme.ThemeType

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
                    if !searchResults.contains(where: { $0.lowercased() == trimmed.lowercased() }) && !trimmed.isEmpty {
                        ingredientRow(name: trimmed, isFreeText: true)
                        if !searchResults.isEmpty {
                            Divider()
                        }
                    }

                    ForEach(searchResults, id: \.self) { ingredient in
                        ingredientRow(name: ingredient, isFreeText: false)
                    }
                }
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.bottom, AppTheme.spacing20)
            }
        }
    }

    private func ingredientRow(name: String, isFreeText: Bool) -> some View {
        let inList = isInShopping(name)
        let category = isFreeText ? nil : CategoryClassifier.suggestCategory(for: name)
        return HStack(spacing: AppTheme.spacing12) {
            HStack(alignment: .top, spacing: AppTheme.spacing12) {
                if isFreeText {
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                } else if let category {
                    Image(systemName: CategoryClassifier.categoryIcon(for: category))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                Text(isFreeText ? "Add \"\(name)\"" : name)
                    .font(.body)
                    .fontWeight(isFreeText ? .medium : .regular)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: { onAddToShopping(name) }) {
                Group {
                    if inList {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.green)
                            .frame(width: 52, height: 32)
                    } else {
                        Text("Add")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 32)
                            .background(Capsule().fill(AppTheme.accentColor(for: selectedTheme)))
                    }
                }
                // 32pt visual capsule but ≥44pt tap target (accessibility hit-region minimum).
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(inList)
            .accessibilityLabel(inList ? "Already in groceries" : "Add to groceries")
        }
        .padding(.horizontal, AppTheme.spacing16)
        .padding(.vertical, AppTheme.spacing10)
        .appCard(cornerRadius: AppTheme.cornerRadius12)
    }
}
