import SwiftUI

/// Accent color theme picker presented as a single-selection list.
struct ThemeSettingsView: View {
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    var body: some View {
        SettingsScreen("Theme") {
            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Select Theme")

                SettingsCard {
                    VStack(spacing: 0) {
                        ForEach(Array(AppTheme.ThemeType.allCases.enumerated()), id: \.element) { index, theme in
                            themeRow(theme)

                            if index < AppTheme.ThemeType.allCases.count - 1 {
                                SettingsRowDivider()
                            }
                        }
                    }
                }
            }
        }
    }

    private func themeRow(_ theme: AppTheme.ThemeType) -> some View {
        Button(action: {
            selectedTheme = theme
            HapticManager.shared.selection()
        }) {
            HStack(spacing: AppTheme.spacing12) {
                Circle()
                    .fill(AppTheme.accentColor(for: theme))
                    .frame(width: AppTheme.width29, height: AppTheme.width29)
                    .overlay(
                        Circle()
                            .strokeBorder(selectedTheme == theme ? Color.white : Color.clear, lineWidth: 2)
                    )

                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                    Text(theme.rawValue)
                        .font(.body)
                        .adaptiveForegroundColor()

                    Text(themeDescription(for: theme))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: AppTheme.spacing8)

                if selectedTheme == theme {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundColor(AppTheme.accentColor(for: theme))
                }
            }
            .contentShape(Rectangle())
            .padding(AppTheme.spacing20)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityAddTraits(selectedTheme == theme ? .isSelected : [])
    }

    private func themeDescription(for theme: AppTheme.ThemeType) -> String {
        switch theme {
        case .teal:
            return "Cool ocean vibes"
        case .purple:
            return "Rich royal purple"
        case .red:
            return "Bold crimson"
        case .orange:
            return "Warm tangerine"
        case .yellow:
            return "Bright sunshine"
        case .green:
            return "Fresh emerald"
        case .pink:
            return "Vibrant magenta"
        case .gold:
            return "Luxury gold & black"
        }
    }
}

#Preview {
    NavigationStack {
        ThemeSettingsView()
    }
}
