import SwiftUI

/// Kitchen inventory as bare `List` `Section`s (no own `List`/title) so Groceries can host it in one scroll below the shopping sections; collapse state driven by parent.
struct KitchenSectionsView: View {
    @Binding var collapsedCategories: Set<String>
    let onAddMore: () -> Void

    @Environment(\.kitchen) private var manager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        PantryAlertsSectionContent(manager: manager)

        Section {
            HStack(spacing: AppTheme.spacing12) {
                Text("\(manager.items.count) ingredient\(manager.items.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(AppTheme.adaptiveSubtitle(for: colorScheme))
                Spacer()
                Button(action: {
                    onAddMore()
                    HapticManager.shared.light()
                }) {
                    HStack(spacing: AppTheme.spacing6) {
                        Image(systemName: "plus.circle.fill").font(.caption)
                        Text("Add More").font(.caption).fontWeight(.semibold)
                    }
                    .adaptiveForegroundColor()
                    .padding(.horizontal, AppTheme.spacing12)
                    .padding(.vertical, AppTheme.spacing6)
                    .background(Capsule().fill(AppTheme.accentColor))
                }
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
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
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
                categoryHeader(category: group.category, items: group.items)
            }
        }
    }

    @ViewBuilder
    private func categoryHeader(category: String, items: [KitchenItem]) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                if collapsedCategories.contains(category) {
                    collapsedCategories.remove(category)
                } else {
                    collapsedCategories.insert(category)
                }
            }
        }) {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: CategoryClassifier.categoryIcon(for: category))
                    .font(.body)
                    .foregroundStyle(CategoryClassifier.categoryColor(for: category))
                    .frame(width: AppTheme.iconSize28)
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()
                Text("(\(items.count))")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.caption)
                    .foregroundStyle(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                    .rotationEffect(.degrees(collapsedCategories.contains(category) ? 180 : 0))
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard(cornerRadius: AppTheme.cornerRadius12)
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.top, AppTheme.spacing2)
        }
        .buttonStyle(.plain)
        .textCase(nil)
        .listRowInsets(EdgeInsets())
        .headerProminence(.standard)
    }
}
