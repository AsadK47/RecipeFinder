import SwiftUI

/// Kitchen inventory as bare `List` `Section`s (no own `List`/title) so Groceries can host it in one scroll below the shopping sections; collapse state driven by parent.
struct KitchenSectionsView: View {
    @Binding var collapsedCategories: Set<String>
    let onAddMore: () -> Void

    @Environment(\.kitchen) private var manager

    /// Plain items plus the use-by items shown as alerts above, so the number matches the rows.
    private var ingredientCount: Int {
        let alerts = manager.expiredItems() + manager.expiringSoonItems() + manager.lowStockItems()
        return GroceriesMode.atHomeCount(itemNames: manager.items.map(\.name), alertNames: alerts.map(\.name))
    }

    var body: some View {
        PantryAlertsSectionContent(manager: manager)

        Section {
            HStack(spacing: AppTheme.spacing12) {
                Text("\(ingredientCount) ingredient\(ingredientCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(AppTheme.adaptiveSubtitle)
                Spacer()
                PrimaryButton("Add More", systemImage: "plus.circle.fill", size: .compact, action: onAddMore)
            }
            .padding(.horizontal, AppTheme.spacing4)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)

        ForEach(manager.groupedItems(), id: \.category) { group in
            Section {
                if !collapsedCategories.contains(group.category) {
                    ForEach(group.items) { item in
                        KitchenItemRow(item: item)
                            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation(.appSnappy) {
                                        manager.removeItem(item)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(AppTheme.error)
                            }
                    }
                }
            } header: {
                GroceryCategoryHeader(
                    category: group.category, count: "(\(group.items.count))", collapsed: $collapsedCategories
                )
            }
        }
    }
}
