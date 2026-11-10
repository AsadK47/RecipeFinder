import SwiftUI

/// Today tab. Starts as a friendly launch pad into the other tabs; Tabs 2/3 fills it with tonight's meal and shelves.
struct TodayView: View {
    /// Switches the main tab (Recipes, Plan, …).
    let onOpen: (AppTab) -> Void

    /// Morning before noon, afternoon until 6pm, evening after.
    nonisolated static func greeting(forHour hour: Int) -> String {
        switch hour {
        case 0..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    ScreenTitleHeader("Today")

                    ScrollView {
                        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                            Text(Self.greeting(forHour: Calendar.current.component(.hour, from: Date())))
                                .font(.title2.weight(.bold))
                                .adaptiveForegroundColor()
                            Text("What sounds good today?")
                                .font(.subheadline)
                                .adaptiveSecondaryForeground()
                                .padding(.bottom, AppTheme.spacing8)

                            shortcut(.recipes, title: "Find something to cook",
                                     subtitle: "Browse your recipes or search by what you fancy.", color: .orange)
                            shortcut(.plan, title: "Plan your week",
                                     subtitle: "Pick meals for the days ahead.", color: .blue)
                            shortcut(.groceries, title: "Check your groceries",
                                     subtitle: "See what to buy and what's at home.", color: .green)
                        }
                        .padding(.horizontal, AppTheme.spacing20)
                        .padding(.top, AppTheme.spacing16)
                        .padding(.bottom, AppTheme.spacing40)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func shortcut(_ tab: AppTab, title: String, subtitle: String, color: Color) -> some View {
        Button {
            HapticManager.shared.light()
            onOpen(tab)
        } label: {
            HStack(spacing: AppTheme.spacing16) {
                IconBadge(systemName: tab.icon, tint: color, diameter: 44, iconSize: AppTheme.fontSize18, style: .solid)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(AppTheme.spacing20)
            .appCard()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("today.open.\(tab.rawValue)")
    }
}

#Preview {
    TodayView(onOpen: { _ in })
}
