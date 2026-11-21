import SwiftUI

/// Collapsible aisle header for both halves of Groceries (To buy and At home): icon, name, count, chevron. Tapping
/// adds or removes its category in `collapsed`.
struct GroceryCategoryHeader: View {
    let category: String
    /// Shown after the name, e.g. "(3)" at home or "(1/3)" left to buy.
    let count: String
    @Binding var collapsed: Set<String>

    private var isCollapsed: Bool { collapsed.contains(category) }

    /// An up chevron while open, turned to point down once collapsed.
    static func chevronDegrees(isCollapsed: Bool) -> Double { isCollapsed ? 180 : 0 }

    /// To buy's count: items still unticked over all items in the aisle.
    static func remainingCount(_ items: [ShoppingListModel]) -> String {
        "(\(items.filter { !$0.isChecked }.count)/\(items.count))"
    }

    var body: some View {
        Button(
            action: {
                withAnimation(.appSpring) {
                    if isCollapsed {
                        collapsed.remove(category)
                    } else {
                        collapsed.insert(category)
                    }
                }
            },
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

                    Text(count)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.adaptiveMediumEmphasis)

                    Spacer()

                    Image(systemName: "chevron.up")
                        .font(.caption)
                        .foregroundStyle(AppTheme.adaptiveMediumEmphasis)
                        .rotationEffect(.degrees(Self.chevronDegrees(isCollapsed: isCollapsed)))
                }
                .padding(.horizontal, AppTheme.spacing16)
                .padding(.vertical, AppTheme.spacing8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCard(cornerRadius: AppTheme.cornerRadius12)
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
