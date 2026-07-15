import SwiftUI

/// Accent color picker plus appearance extras.
struct AppearanceAndThemeSettingsView: View {
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    var body: some View {
        SettingsScreen("Appearance & Theme") {
            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Color Theme")

                SettingsCard {
                    VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                        Text("Choose your favorite accent color for the app.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacing12) {
                            ForEach(AppTheme.ThemeType.allCases) { theme in
                                themeSwatch(theme)
                            }
                        }
                    }
                    .padding(AppTheme.spacing20)
                }
            }

            SettingsSection(title: "Extras", items: [
                .init(
                    row: SettingsRow(icon: "party.popper.fill", iconColor: .purple, title: "Party Time"),
                    destination: PartyTimeView()
                )
            ])
        }
    }

    private func themeSwatch(_ theme: AppTheme.ThemeType) -> some View {
        Button(action: {
            selectedTheme = theme
            HapticManager.shared.selection()
        }) {
            HStack(spacing: AppTheme.spacing12) {
                Circle()
                    .fill(AppTheme.accentColor(for: theme))
                    .frame(width: AppTheme.iconSize32, height: 32)
                    .overlay(
                        Circle()
                            .strokeBorder(selectedTheme == theme ? Color.white : Color.clear, lineWidth: 2)
                    )

                Text(theme.rawValue)
                    .font(.subheadline)
                    .adaptiveForegroundColor()

                Spacer(minLength: AppTheme.spacing4)

                if selectedTheme == theme {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppTheme.accentColor(for: theme))
                }
            }
            .padding(AppTheme.spacing12)
            .background(selectedTheme == theme ? AppTheme.accentColor(for: theme).opacity(0.15) : AppTheme.secondaryText.opacity(0.05))
            .cornerRadius(AppTheme.cornerRadius12)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityAddTraits(selectedTheme == theme ? .isSelected : [])
    }
}

#Preview {
    NavigationStack {
        AppearanceAndThemeSettingsView()
    }
}
