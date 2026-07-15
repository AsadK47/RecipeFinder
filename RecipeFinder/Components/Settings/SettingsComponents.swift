import SwiftUI

// MARK: - Settings Design System
//
// Shared building blocks for every settings screen. Rows, sections, and icon
// tiles are defined once here so alignment and spacing stay consistent by
// construction rather than by vigilance.

// MARK: - Icon Tile

/// Rounded-square leading icon, matching the iOS Settings app anatomy.
struct SettingsIconTile: View {
    let systemName: String
    let color: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: AppTheme.cornerRadius6, style: .continuous)
            .fill(color)
            .frame(width: AppTheme.width29, height: AppTheme.width29)
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: AppTheme.fontSize15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Row

/// A single settings row: icon tile, title, optional current value, accessory.
///
/// The row itself is layout-only; wrap it in a `NavigationLink` or `Button`,
/// or use the `SettingsSection` conveniences that do so for you.
struct SettingsRow: View {
    enum Accessory {
        case chevron
        case none
    }
    
    let icon: String
    let iconColor: Color
    let title: String
    var value: String?
    var accessory: Accessory = .chevron
    
    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            SettingsIconTile(systemName: icon, color: iconColor)
            
            Text(title)
                .font(.body)
                .adaptiveForegroundColor()
            
            Spacer(minLength: AppTheme.spacing8)
            
            if let value {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            if accessory == .chevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityValue(value ?? "")
    }
}

// MARK: - Section

/// Section header label used above each settings card.
struct SettingsSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.spacing4)
    }
}

/// Card container matching the app-wide frosted/solid card styles.
struct SettingsCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                        .fill(AppTheme.adaptiveCard(for: colorScheme))
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                        .fill(.ultraThinMaterial)
                }
            }
    }
}

/// A titled group of rows inside a card, with automatic dividers.
///
/// Rows are passed as an array of configurations so dividers and padding are
/// applied uniformly — the call site can never misalign them.
struct SettingsSection: View {
    struct Item: Identifiable {
        let id = UUID()
        let row: SettingsRow
        let destination: AnyView?
        let action: (() -> Void)?
        
        /// Navigation row: tapping pushes the destination.
        init<D: View>(row: SettingsRow, destination: D) {
            self.row = row
            self.destination = AnyView(destination)
            self.action = nil
        }
        
        /// Action row: tapping runs the closure.
        init(row: SettingsRow, action: @escaping () -> Void) {
            self.row = row
            self.destination = nil
            self.action = action
        }
    }
    
    let title: String
    let items: [Item]
    
    var body: some View {
        VStack(spacing: AppTheme.spacing8) {
            SettingsSectionHeader(title: title)
            
            SettingsCard {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        itemView(item)
                        
                        if index < items.count - 1 {
                            Divider()
                                .padding(.leading, AppTheme.spacing60)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func itemView(_ item: Item) -> some View {
        if let destination = item.destination {
            NavigationLink(destination: destination) {
                item.row
                    .padding(AppTheme.spacing20)
            }
            .buttonStyle(PlainButtonStyle())
        } else if let action = item.action {
            Button(action: action) {
                item.row
                    .padding(AppTheme.spacing20)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Previews

#Preview("Rows") {
    VStack(spacing: AppTheme.spacing16) {
        SettingsRow(icon: "paintpalette.fill", iconColor: .pink, title: "Appearance & Theme", value: "Teal")
        SettingsRow(icon: "ruler.fill", iconColor: .blue, title: "Units", value: "Metric")
        SettingsRow(icon: "bell.fill", iconColor: .red, title: "Notifications")
        SettingsRow(icon: "trash.fill", iconColor: .red, title: "Delete", accessory: .none)
    }
    .padding()
}

#Preview("Section") {
    NavigationStack {
        SettingsSection(title: "Preferences", items: [
            .init(
                row: SettingsRow(icon: "paintpalette.fill", iconColor: .pink, title: "Appearance & Theme", value: "Teal"),
                destination: Text("Appearance")
            ),
            .init(
                row: SettingsRow(icon: "ruler.fill", iconColor: .blue, title: "Units & Measurements", value: "Metric"),
                destination: Text("Units")
            )
        ])
        .padding()
    }
}
