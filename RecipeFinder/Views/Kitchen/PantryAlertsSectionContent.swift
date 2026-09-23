import SwiftUI

/// Renders `Section` rows for expired, expiring-soon, and low-stock inventory
/// items. Designed to be embedded at the top of a `List` inside
/// `KitchenSectionsView`. Hidden entirely when there are no alerts.
struct PantryAlertsSectionContent: View {
    let manager: any KitchenInventoryManaging
    @Environment(\.colorScheme) private var colorScheme

    private enum AlertType {
        case expired, expiringSoon, lowStock

        var icon: String {
            switch self {
            case .expired:     return "exclamationmark.circle.fill"
            case .expiringSoon: return "clock.badge.exclamationmark.fill"
            case .lowStock:    return "cart.badge.minus"
            }
        }

        var color: Color {
            switch self {
            case .expired:      return .red
            case .expiringSoon: return .orange
            case .lowStock:     return .yellow
            }
        }
    }

    // Computed once per re-render; de-duplicated so each item appears at most once.
    private var expired: [KitchenInventoryModel] { manager.expiredItems() }
    private var expiringSoon: [KitchenInventoryModel] { manager.expiringSoonItems() }
    private var lowStockOnly: [KitchenInventoryModel] {
        manager.lowStockItems().filter { !$0.isExpired && !$0.isExpiringSoon }
    }
    private var hasAlerts: Bool { !expired.isEmpty || !expiringSoon.isEmpty || !lowStockOnly.isEmpty }

    var body: some View {
        if hasAlerts {
            Section {
                ForEach(expired) { item in
                    alertRow(item, type: .expired)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            deleteButton(item)
                        }
                }
                ForEach(expiringSoon) { item in
                    alertRow(item, type: .expiringSoon)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            deleteButton(item)
                        }
                }
                ForEach(lowStockOnly) { item in
                    alertRow(item, type: .lowStock)
                }
            } header: {
                alertHeader
            }
            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }

    private var alertHeader: some View {
        HStack(spacing: AppTheme.spacing8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
            Text("Pantry Alerts")
                .font(.subheadline)
                .fontWeight(.semibold)
                .adaptiveForegroundColor()
            Spacer()
            Text("\(expired.count + expiringSoon.count + lowStockOnly.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
        }
        .padding(.horizontal, AppTheme.spacing16)
        .padding(.vertical, AppTheme.spacing8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(cornerRadius: AppTheme.cornerRadius12)
        .padding(.horizontal, AppTheme.spacing16)
        .padding(.top, AppTheme.spacing2)
        .textCase(nil)
        .listRowInsets(EdgeInsets())
        .headerProminence(.standard)
    }

    private func alertRow(_ item: KitchenInventoryModel, type: AlertType) -> some View {
        GlassCard {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: type.icon)
                    .font(.body)
                    .foregroundStyle(type.color)
                    .frame(width: AppTheme.iconSize24)

                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .adaptiveForegroundColor()
                        .lineLimit(1)
                    Text(item.expiryStatusText)
                        .font(.caption)
                        .foregroundStyle(type.color)
                }

                Spacer(minLength: 0)

                if type == .lowStock {
                    Text("Low stock")
                        .font(.caption)
                        .foregroundStyle(type.color)
                }
            }
            .padding(.horizontal, AppTheme.spacing12)
            .padding(.vertical, AppTheme.spacing10)
        }
    }

    private func deleteButton(_ item: KitchenInventoryModel) -> some View {
        Button(role: .destructive) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                manager.removeInventoryItem(item)
            }
        } label: {
            Label("Remove", systemImage: "trash")
        }
        .tint(AppTheme.error)
    }
}
