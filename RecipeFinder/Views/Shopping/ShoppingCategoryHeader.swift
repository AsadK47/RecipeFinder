import SwiftUI

/// A collapsible category header in the shopping list, showing the category name,
/// remaining/total counts, and a chevron. Extracted from `ShoppingListView`.
struct ShoppingCategoryHeader: View {
    let category: String
    let items: [ShoppingListModel]
    let isCollapsed: Bool
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let onToggle: () -> Void

    var body: some View {
        Button(
            action: onToggle,
            label: {
                HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: CategoryClassifier.categoryIcon(for: category))
                        .font(.body)
                        .foregroundStyle(CategoryClassifier.categoryColor(for: category))
                        .frame(width: AppTheme.iconSize28)
                    
                    Text(category)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .adaptiveForegroundColor()
                    
                    Text("(\(items.filter { !$0.isChecked }.count)/\(items.count))")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                    
                    Spacer()
                    
                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.caption)
                        .foregroundStyle(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                        .rotationEffect(.degrees(isCollapsed ? 0 : 180))
                }
                .padding(.horizontal, AppTheme.spacing16)
                .padding(.vertical, AppTheme.spacing8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    if cardStyle == .solid {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .fill(AppTheme.adaptiveCard(for: colorScheme))
                    } else {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .fill(.ultraThinMaterial)
                    }
                }
                .padding(.horizontal, AppTheme.spacing16)
                .padding(.top, AppTheme.spacing2)
            }
        )
        .buttonStyle(.plain)
        .textCase(nil)
        .listRowInsets(EdgeInsets())
        .headerProminence(.standard)
    }
}
