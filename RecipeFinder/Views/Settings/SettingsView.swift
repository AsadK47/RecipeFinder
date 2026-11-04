import SwiftUI

/// Root of the Settings tab. Each sub-screen lives in Views/Settings/Screens/.
struct SettingsTabView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric
    @Environment(\.profile) private var profileManager
    @State private var profileImage: UIImage?
    @State private var debugResetMessage: String?
    
    /// Real version string from the bundle — can never drift from the build settings
    private var versionLabel: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "Version \(version) (Build \(build))"
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.spacing20) {
                    SettingsSectionHeader(title: "Profile")

                    SettingsCard {
                        NavigationLink(destination: ProfileView()) {
                            HStack(spacing: AppTheme.spacing16) {
                                profileAvatar

                                VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                    Text(profileManager.fullName.isEmpty ? "Profile" : profileManager.fullName)
                                        .font(.headline)
                                        .adaptiveForegroundColor()
                                    
                                    Text("Name, photo & badges")
                                        .font(.caption)
                                        .adaptiveSecondaryForeground()
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .adaptiveSecondaryForeground()
                                    .font(.caption)
                            }
                            .padding(AppTheme.spacing20)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    SettingsSection(title: "Preferences", items: [
                        .init(
                            row: SettingsRow(icon: "paintpalette.fill", iconColor: .pink, title: "Appearance & Theme", value: selectedTheme.rawValue),
                            destination: AppearanceAndThemeSettingsView()
                        ),
                        .init(
                            row: SettingsRow(icon: "bell.fill", iconColor: .red, title: "Notifications"),
                            destination: NotificationSettingsView()
                        ),
                        .init(
                            row: SettingsRow(icon: "ruler.fill", iconColor: .blue, title: "Units & Measurements", value: measurementSystem.rawValue),
                            destination: UnitsSettingsView()
                        ),
                        .init(
                            row: SettingsRow(icon: "display", iconColor: .cyan, title: "Display"),
                            destination: DisplaySettingsView()
                        )
                    ])

                    SettingsSection(title: "Privacy & Data", items: [
                        .init(
                            row: SettingsRow(icon: "hand.raised.fill", iconColor: .blue, title: "Privacy"),
                            destination: PrivacySettingsView()
                        ),
                        .init(
                            row: SettingsRow(icon: "externaldrive.fill", iconColor: .gray, title: "Data Management"),
                            destination: DataManagementSettingsView()
                        ),
                        .init(
                            row: SettingsRow(icon: "building.2.fill", iconColor: .indigo, title: "Legal Information"),
                            destination: LegalInformationView()
                        )
                    ])

                    SettingsSection(title: "Support", items: [
                        .init(
                            row: SettingsRow(icon: "questionmark.circle.fill", iconColor: .teal, title: "Help & Support"),
                            destination: HelpView()
                        ),
                        .init(
                            row: SettingsRow(icon: "book.circle.fill", iconColor: .gray, title: "About RecipeFinder"),
                            destination: AboutView()
                        )
                    ])

                    // Until the App Store listing is live, share the marketing site (swap to the apps.apple.com link at launch).
                    if let shareURL = URL(string: "https://recipefinder.uk") {
                        SettingsCard {
                            ShareLink(
                                item: shareURL,
                                subject: Text("RecipeFinder"),
                                message: Text("Check out RecipeFinder — a private, offline-first recipe app.")
                            ) {
                                SettingsRow(
                                    icon: "square.and.arrow.up",
                                    iconColor: .green,
                                    title: "Share with a Friend",
                                    accessory: .externalLink
                                )
                                .padding(AppTheme.spacing20)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

#if DEBUG
                    SettingsSection(title: "Developer (Debug)", items: [
                        .init(
                            row: SettingsRow(icon: "arrow.counterclockwise.circle.fill", iconColor: .orange, title: "Reset Onboarding", accessory: .none),
                            action: { resetOnboarding() }
                        )
                    ])

                    if let debugResetMessage {
                        Text(debugResetMessage)
                            .font(.caption)
                            .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AppTheme.spacing6)
                    }
#endif
                    
                    VStack(spacing: AppTheme.spacing4) {
                        Text("RecipeFinder")
                            .font(.caption)
                            .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                        Text(versionLabel)
                            .font(.caption2)
                            .adaptiveForegroundColor(opacity: AppTheme.glassLightOpacity)
                    }
                    .padding(.top, AppTheme.spacing16)
                    .padding(.bottom, AppTheme.spacing40)
                }
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.top, AppTheme.spacing20)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            profileImage = profileManager.loadProfileImage()
        }
    }

    @ViewBuilder
    private var profileAvatar: some View {
        if let profileImage {
            Image(uiImage: profileImage)
                .resizable()
                .scaledToFill()
                .frame(width: AppTheme.height54, height: AppTheme.height54)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(AppTheme.accentColor(for: selectedTheme))
                .frame(width: AppTheme.height54, height: AppTheme.height54)
                .overlay {
                    Text(profileManager.initials)
                        .font(.system(size: AppTheme.fontSize22, weight: .semibold))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                }
        }
    }

    private func resetOnboarding() {
        LocalStore.shared.set(false, forKey: "hasCompletedOnboarding")
        debugResetMessage = "Onboarding reset. Relaunch the app to run onboarding again."
        HapticManager.shared.success()
    }
}

#Preview {
    SettingsTabView()
        .environment(\.appTheme, AppTheme.ThemeType.teal)
}
