import SwiftUI

/// Accent color picker, appearance mode override, and extras.
struct AppearanceAndThemeSettingsView: View {
    @AppStorage("preferredColorScheme") private var colorSchemePreference: Int = 0

    private let appearanceModes = ["System", "Light", "Dark"]

    var body: some View {
        SettingsScreen("Appearance & Theme") {
            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Appearance")

                SettingsCard {
                    VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                        Text("Override the system dark/light mode setting.")
                            .font(.subheadline)
                            .adaptiveSecondaryForeground()

                        Picker("Appearance", selection: $colorSchemePreference) {
                            ForEach(Array(appearanceModes.enumerated()), id: \.offset) { index, label in
                                Text(label).tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: colorSchemePreference) { _, _ in
                            HapticManager.shared.selection()
                        }
                    }
                    .padding(AppTheme.spacing16)
                }
            }

            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Color Theme")

                SettingsCard {
                    VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                        Text("Choose your favorite accent color for the app.")
                            .font(.subheadline)
                            .adaptiveSecondaryForeground()
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
            ThemeStore.shared.theme = theme
            HapticManager.shared.selection()
        }) {
            HStack(spacing: AppTheme.spacing12) {
                Circle()
                    .fill(AppTheme.accentColor(for: theme))
                    .frame(width: AppTheme.iconSize32, height: 32)
                    .overlay(
                        Circle()
                            .strokeBorder(ThemeStore.shared.theme == theme ? Color.white : Color.clear, lineWidth: 2)
                    )

                Text(theme.rawValue)
                    .font(.subheadline)
                    .adaptiveForegroundColor()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)   // the selected checkmark used to squeeze "Purple" into "Purpl/e"

                Spacer(minLength: AppTheme.spacing4)

                if ThemeStore.shared.theme == theme {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accentColor(for: theme))
                }
            }
            .padding(AppTheme.spacing12)
            .background(ThemeStore.shared.theme == theme ? AppTheme.accentColor(for: theme).opacity(0.15) : AppTheme.secondaryText.opacity(0.05))
            .cornerRadius(AppTheme.cornerRadius12)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityAddTraits(ThemeStore.shared.theme == theme ? .isSelected : [])
    }
}

#Preview {
    NavigationStack {
        AppearanceAndThemeSettingsView()
    }
}
