import SwiftUI

/// Search suggestions for the merged Groceries tab: an "add free text" row plus
/// matching foods, each addable to **either** destination via two buttons — a cart
/// (shopping list) and a fridge (kitchen). This is how you add to the kitchen from
/// the shared search field.
struct GrocerySearchResultsView: View {
    let searchText: String
    let searchResults: [String]
    let isInShopping: (String) -> Bool
    let isInKitchen: (String) -> Bool
    let onAddToShopping: (String) -> Void
    let onAddToKitchen: (String) -> Void
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

                legend

                LazyVStack(spacing: AppTheme.spacing8) {
                    let trimmed = searchText.trimmingCharacters(in: .whitespaces)
                    if !searchResults.contains(where: { $0.lowercased() == trimmed.lowercased() }) && !trimmed.isEmpty {
                        freeTextRow(trimmed)
                        if !searchResults.isEmpty {
                            Divider()
                        }
                    }

                    ForEach(searchResults, id: \.self) { ingredient in
                        ingredientRow(ingredient)
                    }
                }
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.bottom, AppTheme.spacing20)
            }
        }
    }

    /// Tells the user which button does what, since each row has two.
    private var legend: some View {
        HStack(spacing: AppTheme.spacing16) {
            Label("Shopping list", systemImage: "cart.badge.plus")
            Label("Kitchen", systemImage: "refrigerator")
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.primary.opacity(0.75))
        .padding(.horizontal, AppTheme.spacing20)
    }

    private func freeTextRow(_ trimmed: String) -> some View {
        rowShell(
            leading: {
                HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.title3)
                        .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    Text("Add \"\(trimmed)\"")
                        .font(.body).fontWeight(.medium)
                        .adaptiveForegroundColor()
                }
            },
            inShopping: isInShopping(trimmed),
            inKitchen: isInKitchen(trimmed),
            onShopping: { onAddToShopping(trimmed) },
            onKitchen: { onAddToKitchen(trimmed) }
        )
    }

    private func ingredientRow(_ ingredient: String) -> some View {
        let category = CategoryClassifier.suggestCategory(for: ingredient)
        return rowShell(
            leading: {
                HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: CategoryClassifier.categoryIcon(for: category))
                        .foregroundStyle(CategoryClassifier.categoryColor(for: category))
                        .font(.body)
                    Text(ingredient)
                        .font(.body)
                        .foregroundStyle(AppTheme.textColor(for: colorScheme))
                }
            },
            inShopping: isInShopping(ingredient),
            inKitchen: isInKitchen(ingredient),
            onShopping: { onAddToShopping(ingredient) },
            onKitchen: { onAddToKitchen(ingredient) }
        )
    }

    @ViewBuilder
    private func rowShell<Leading: View>(
        @ViewBuilder leading: () -> Leading,
        inShopping: Bool,
        inKitchen: Bool,
        onShopping: @escaping () -> Void,
        onKitchen: @escaping () -> Void
    ) -> some View {
        HStack(spacing: AppTheme.spacing12) {
            leading()
            Spacer()
            destinationButton(system: "cart.badge.plus", isAdded: inShopping, action: onShopping)
            destinationButton(system: "refrigerator", isAdded: inKitchen, action: onKitchen)
        }
        .padding(.horizontal, AppTheme.spacing16)
        .padding(.vertical, AppTheme.spacing10)
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

    private func destinationButton(system: String, isAdded: Bool, action: @escaping () -> Void) -> some View {
        let tint: Color = isAdded ? .green : AppTheme.accentColor(for: selectedTheme)
        let label = system.contains("cart") ? "Add to shopping list" : "Add to kitchen"
        return Button(action: action) {
            Image(systemName: isAdded ? "checkmark.circle.fill" : system)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(tint.opacity(0.15))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isAdded)
        .accessibilityLabel(isAdded ? "Already added" : label)
    }
}
