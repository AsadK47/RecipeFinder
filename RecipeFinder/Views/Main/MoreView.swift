import SwiftUI

/// Native iOS Settings view following Apple's design system
/// Clean, readable, and familiar - inspired by iOS Settings and DuoMobile
struct MoreView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @StateObject private var accountManager = AccountManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section {
                    NavigationLink(destination: AccountView()) {
                        HStack(spacing: 12) {
                            // Profile Avatar
                            Circle()
                                .fill(AppTheme.accentColor(for: selectedTheme))
                                .frame(width: 56, height: 56)
                                .overlay {
                                    Text(accountManager.initials)
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(accountManager.fullName)
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(.primary)
                                
                                Text("Apple ID, iCloud & More")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Appearance Section
                Section {
                    NavigationLink(destination: AppearanceSettingsView()) {
                        SettingsRow(
                            icon: "paintpalette.fill",
                            iconColor: .pink,
                            title: "Appearance"
                        )
                    }
                    
                    NavigationLink(destination: ThemeSettingsView()) {
                        SettingsRow(
                            icon: "sparkles",
                            iconColor: AppTheme.accentColor(for: selectedTheme),
                            title: "Theme"
                        )
                    }
                } header: {
                    Text("Personalization")
                }
                
                // App Settings Section
                Section {
                    NavigationLink(destination: NotificationSettingsView()) {
                        SettingsRow(
                            icon: "bell.fill",
                            iconColor: .red,
                            title: "Notifications"
                        )
                    }
                    
                    NavigationLink(destination: TimerSettingsView()) {
                        SettingsRow(
                            icon: "timer",
                            iconColor: .orange,
                            title: "Timers"
                        )
                    }
                    
                    NavigationLink(destination: UnitsSettingsView()) {
                        SettingsRow(
                            icon: "ruler.fill",
                            iconColor: .blue,
                            title: "Units & Measurements"
                        )
                    }
                } header: {
                    Text("Cooking")
                }
                
                // Privacy & Data Section
                Section {
                    NavigationLink(destination: PrivacySettingsView()) {
                        SettingsRow(
                            icon: "hand.raised.fill",
                            iconColor: .blue,
                            title: "Privacy"
                        )
                    }
                    
                    NavigationLink(destination: DataSettingsView()) {
                        SettingsRow(
                            icon: "externaldrive.fill",
                            iconColor: .gray,
                            title: "Data Management"
                        )
                    }
                } header: {
                    Text("Privacy & Data")
                }
                
                // Support & About Section
                Section {
                    NavigationLink(destination: HelpView()) {
                        SettingsRow(
                            icon: "questionmark.circle.fill",
                            iconColor: .teal,
                            title: "Help & Support"
                        )
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        SettingsRow(
                            icon: "info.circle.fill",
                            iconColor: .gray,
                            title: "About RecipeFinder"
                        )
                    }
                    
                    Link(destination: URL(string: "https://recipefinder.com/privacy")!) {
                        SettingsRow(
                            icon: "doc.text.fill",
                            iconColor: .green,
                            title: "Privacy Policy",
                            showChevron: false
                        )
                    }
                } header: {
                    Text("Support")
                } footer: {
                    VStack(spacing: 4) {
                        Text("RecipeFinder")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Text("Version 1.0.0 (Build 1)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
        }
    }
}

/// Clean iOS-style settings row with icon and title
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var showChevron: Bool = true
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon background
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(iconColor)
                    .frame(width: 29, height: 29)
                
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(.primary)
            
            if !showChevron {
                Spacer()
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Placeholder Settings Views

struct AppearanceSettingsView: View {
    var body: some View {
        List {
            Section {
                Text("Card Style")
                Text("Animation Speed")
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ThemeSettingsView: View {
    var body: some View {
        List {
            Section {
                Text("Color Theme")
                Text("Accent Colors")
            }
        }
        .navigationTitle("Theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        List {
            Section {
                Text("Timer Alerts")
                Text("Meal Reminders")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TimerSettingsView: View {
    var body: some View {
        List {
            Section {
                Text("Default Timer Sound")
                Text("Vibration Pattern")
            }
        }
        .navigationTitle("Timers")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct UnitsSettingsView: View {
    var body: some View {
        List {
            Section {
                Text("Temperature")
                Text("Volume")
                Text("Weight")
            }
        }
        .navigationTitle("Units & Measurements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        List {
            Section {
                Text("Data Collection")
                Text("Analytics")
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataSettingsView: View {
    var body: some View {
        List {
            Section {
                Text("Storage")
                Text("Cache")
                Text("Export Data")
            }
        }
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpView: View {
    var body: some View {
        List {
            Section {
                Text("FAQ")
                Text("Contact Support")
                Text("Report a Bug")
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                Text("Version 1.0.0")
                Text("Build 1")
                Text("© 2025 RecipeFinder")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MoreView()
        .environment(\.appTheme, .teal)
}

