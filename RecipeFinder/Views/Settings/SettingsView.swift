import SwiftUI
import AudioToolbox
import CoreData

struct SettingsTabView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @State private var notificationsEnabled: Bool = false
    @State private var cookModeEnabled: Bool = true
    @StateObject private var accountManager = AccountManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var profileImage: UIImage?
    @State private var refreshID = UUID()
    @State private var debugResetMessage: String?
    
    var body: some View {
        ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                    ScrollView {
                        VStack(spacing: AppTheme.spacing20) {
                            SettingsSectionHeader(title: "Account")

                            SettingsCard {
                                NavigationLink(destination: AccountView()) {
                                    HStack(spacing: AppTheme.spacing16) {
                                        ZStack {
                                            if let profileImage = profileImage {
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
                                                        Text(accountManager.initials)
                                                            .font(.system(size: AppTheme.fontSize22, weight: .semibold))
                                                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                                                    }
                                            }
                                        }
                                        .id(refreshID)
                                        
                                        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                            Text(accountManager.fullName.isEmpty ? "Account" : accountManager.fullName)
                                                .font(.headline)
                                                .adaptiveForegroundColor()
                                            
                                            Text("Profile & Settings")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                    }
                                    .padding(AppTheme.spacing20)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            SettingsSectionHeader(title: "Appearance")

                            SettingsCard {
                                NavigationLink(destination: AppearanceAndThemeSettingsView()) {
                                    SettingsRow(icon: "paintpalette.fill", iconColor: .pink, title: "Appearance & Theme")
                                        .padding(AppTheme.spacing20)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            SettingsSectionHeader(title: "Cooking & Preferences")

                            SettingsCard {
                                VStack(spacing: 0) {
                                    NavigationLink(destination: NotificationSettingsView()) {
                                        SettingsRow(icon: "bell.fill", iconColor: .red, title: "Notifications")
                                            .padding(AppTheme.spacing20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Divider()
                                        .padding(.leading, AppTheme.spacing60)
                                    
                                    NavigationLink(destination: TimerSettingsView()) {
                                        SettingsRow(icon: "timer", iconColor: .orange, title: "Timers")
                                            .padding(AppTheme.spacing20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Divider()
                                        .padding(.leading, AppTheme.spacing60)
                                    
                                    NavigationLink(destination: UnitsSettingsView()) {
                                        SettingsRow(icon: "ruler.fill", iconColor: .blue, title: "Units & Measurements")
                                            .padding(AppTheme.spacing20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Divider()
                                        .padding(.leading, AppTheme.spacing60)
                                    
                                    NavigationLink(destination: DisplaySettingsView()) {
                                        SettingsRow(icon: "display", iconColor: .cyan, title: "Display")
                                            .padding(AppTheme.spacing20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Divider()
                                        .padding(.leading, AppTheme.spacing60)
                                    
                                    NavigationLink(destination: PartyTimeView()) {
                                        SettingsRow(icon: "party.popper.fill", iconColor: .purple, title: "Party Time")
                                            .padding(AppTheme.spacing20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }

                            SettingsSectionHeader(title: "Privacy & Data")

                            SettingsCard {
                                VStack(spacing: 0) {
                                    NavigationLink(destination: PrivacySettingsView()) {
                                        SettingsRow(icon: "hand.raised.fill", iconColor: .blue, title: "Privacy")
                                            .padding(AppTheme.spacing20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Divider()
                                        .padding(.leading, AppTheme.spacing60)
                                    
                                    NavigationLink(destination: DataManagementSettingsView()) {
                                        SettingsRow(icon: "externaldrive.fill", iconColor: .gray, title: "Data Management")
                                            .padding(AppTheme.spacing20)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    Divider()
                                        .padding(.leading, AppTheme.spacing60)

                                    NavigationLink(destination: LegalInformationView()) {
                                        SettingsRow(icon: "building.2.fill", iconColor: .indigo, title: "Legal Information")
                                            .padding(AppTheme.spacing20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }

                            SettingsSectionHeader(title: "Support")

                            SettingsCard {
                                VStack(spacing: 0) {
                                    NavigationLink(destination: HelpView()) {
                                        SettingsRow(icon: "questionmark.circle.fill", iconColor: .teal, title: "Help & Support")
                                            .padding(AppTheme.spacing20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Divider()
                                        .padding(.leading, AppTheme.spacing60)
                                    
                                    NavigationLink(destination: AboutView()) {
                                        SettingsRow(icon: "info.circle.fill", iconColor: .gray, title: "About RecipeFinder")
                                            .padding(AppTheme.spacing20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }

#if DEBUG
                            SettingsSectionHeader(title: "Developer (Debug)")

                            SettingsCard {
                                VStack(spacing: 0) {
                                    Button(action: {
                                        resetOnboardingFlags(resetMainOnboarding: true, resetBiometricOnboarding: false)
                                    }) {
                                        SettingsRow(icon: "arrow.counterclockwise.circle.fill", iconColor: .orange, title: "Reset Main Onboarding")
                                            .padding(AppTheme.spacing20)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    Divider()
                                        .padding(.leading, AppTheme.spacing60)

                                    Button(action: {
                                        resetOnboardingFlags(resetMainOnboarding: false, resetBiometricOnboarding: true)
                                    }) {
                                        SettingsRow(icon: "faceid", iconColor: .blue, title: "Reset Biometric Onboarding")
                                            .padding(AppTheme.spacing20)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    Divider()
                                        .padding(.leading, AppTheme.spacing60)

                                    Button(action: {
                                        resetOnboardingFlags(resetMainOnboarding: true, resetBiometricOnboarding: true)
                                    }) {
                                        SettingsRow(icon: "arrow.counterclockwise.icloud.fill", iconColor: .purple, title: "Reset All Onboarding")
                                            .padding(AppTheme.spacing20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }

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
                                Text("Version 1.0.0 (Build 1)")
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
                profileImage = accountManager.loadProfileImage()
                refreshID = UUID()
            }
        }

    private func resetOnboardingFlags(resetMainOnboarding: Bool, resetBiometricOnboarding: Bool) {
        if resetMainOnboarding {
            UserScopedStorage.shared.set(false, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        }

        if resetBiometricOnboarding {
            UserScopedStorage.shared.set(false, forKey: "hasSeenBiometricOnboarding")
            UserDefaults.standard.set(false, forKey: "hasSeenBiometricOnboarding")
        }

        debugResetMessage = "Onboarding flags reset for this account. Sign out and back in, or relaunch the app, to run onboarding again."
        HapticManager.shared.success()
    }
    }

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

struct SettingsSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.spacing4)
            .padding(.top, 0)
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius6, style: .continuous)
                    .fill(iconColor)
                    .frame(width: AppTheme.width29, height: AppTheme.width29)
                
                Image(systemName: icon)
                    .font(.system(size: AppTheme.fontSize15, weight: .semibold))
                    .adaptiveForegroundColor()
            }
            
            Text(title)
                .font(.body)
                .adaptiveForegroundColor()
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .contentShape(Rectangle())
    }
}

struct AppearanceAndThemeSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
                ScrollView {
                    VStack(spacing: AppTheme.spacing32) {
                        SettingsCard {
                            VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.title2)
                                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                
                                Text("Color Theme")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .adaptiveForegroundColor()
                            }
                            
                            Text("Choose your favorite accent color for the app.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Divider()
                                .padding(.vertical, AppTheme.spacing4)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacing12) {
                                ForEach(AppTheme.ThemeType.allCases) { theme in
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
                                            
                                            VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                                Text(theme.rawValue)
                                                    .font(.subheadline)
                                                    .adaptiveForegroundColor()
                                                
                                                if selectedTheme == theme {
                                                    Image(systemName: "checkmark")
                                                        .font(.caption2)
                                                        .foregroundColor(AppTheme.accentColor(for: theme))
                                                }
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(AppTheme.spacing12)
                                        .background(selectedTheme == theme ? AppTheme.accentColor(for: theme).opacity(0.15) : AppTheme.secondaryText.opacity(0.05))
                                        .cornerRadius(AppTheme.cornerRadius12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(AppTheme.spacing24)
                    }
                }
                .padding(AppTheme.spacing24)
        }
        .navigationTitle("Appearance & Theme")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
}

struct AppearanceSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    private var effectiveCardStyle: CardStyle {
        switch appearanceMode {
        case .system:
            return colorScheme == .dark ? .solid : .frosted
        case .light:
            return .frosted
        case .dark:
            return .solid
        }
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.spacing32) {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            HStack {
                                Image(systemName: "paintpalette.fill")
                                    .font(.title2)
                                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                
                                Text("Appearance")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .adaptiveForegroundColor()
                            }
                            
                            Text("Choose your preferred appearance mode. Each mode automatically applies the best card style.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(AppTheme.spacing24)
                    }
                    
                    SettingsCard {
                        VStack(spacing: 0) {
                            Button(action: {
                                appearanceMode = .system
                                cardStyle = colorScheme == .dark ? .solid : .frosted
                                HapticManager.shared.selection()
                            }) {
                                VStack(spacing: 0) {
                                    HStack(spacing: AppTheme.spacing16) {
                                        ZStack {
                                            Circle()
                                                .fill(AppTheme.accentColor(for: selectedTheme).opacity(0.2))
                                                .frame(width: 50, height: AppTheme.height50)
                                            
                                            Image(systemName: "circle.lefthalf.filled")
                                                .font(.title3)
                                                .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                            Text("System")
                                                .font(.headline)
                                                .adaptiveForegroundColor()
                                            
                                            Text("Follows device settings")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Text(colorScheme == .dark ? "Currently: Ember Dark" : "Currently: Frost Light")
                                                .font(.caption2)
                                                .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                        }
                                        
                                        Spacer()
                                        
                                        if appearanceMode == .system {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                        }
                                    }
                                    .padding(AppTheme.spacing24)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading, AppTheme.spacing86)
                            
                            Button(action: {
                                appearanceMode = .light
                                cardStyle = .frosted
                                HapticManager.shared.selection()
                            }) {
                                VStack(spacing: 0) {
                                    HStack(spacing: AppTheme.spacing16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.cyan.opacity(AppTheme.overlayLightOpacity))
                                                .frame(width: 50, height: AppTheme.height50)
                                            
                                            Image(systemName: "sparkles")
                                                .font(.title3)
                                                .foregroundColor(.cyan)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                            Text("Frost Light")
                                                .font(.headline)
                                                .adaptiveForegroundColor()
                                            
                                            Text("Translucent frosted glass cards")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if appearanceMode == .light {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.cyan)
                                        }
                                    }
                                    .padding(AppTheme.spacing24)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading, AppTheme.spacing86)
                            
                            Button(action: {
                                appearanceMode = .dark
                                cardStyle = .solid
                                HapticManager.shared.selection()
                            }) {
                                VStack(spacing: 0) {
                                    HStack(spacing: AppTheme.spacing16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.orange.opacity(AppTheme.overlayLightOpacity))
                                                .frame(width: 50, height: AppTheme.height50)
                                            
                                            Image(systemName: "flame.fill")
                                                .font(.title3)
                                                .foregroundColor(.orange)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                            Text("Ember Dark")
                                                .font(.headline)
                                                .adaptiveForegroundColor()
                                            
                                            Text("Solid dark cards")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if appearanceMode == .dark {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    .padding(AppTheme.spacing24)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(AppTheme.spacing24)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onChange(of: appearanceMode) { _, newMode in
            switch newMode {
            case .system:
                cardStyle = colorScheme == .dark ? .solid : .frosted
            case .light:
                cardStyle = .frosted
            case .dark:
                cardStyle = .solid
            }
        }
    }
}

struct ThemeSettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.spacing32) {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                            Text("Select Theme")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            ForEach(AppTheme.ThemeType.allCases) { theme in
                                Button(action: {
                                    selectedTheme = theme
                                    HapticManager.shared.selection()
                                }) {
                                    HStack(spacing: AppTheme.spacing16) {
                                        Circle()
                                            .fill(AppTheme.accentColor(for: theme))
                                            .frame(width: 40, height: AppTheme.height40)
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedTheme == theme ? Color.white : Color.clear, lineWidth: 3)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                            Text(theme.rawValue)
                                                .adaptiveForegroundColor()
                                                .font(.body)
                                            
                                            Text(themeDescription(for: theme))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedTheme == theme {
                                            Image(systemName: "checkmark.circle.fill")
                                                .adaptiveForegroundColor()
                                                .font(.title3)
                                        }
                                    }
                                    .padding(AppTheme.spacing16)
                                    .background(selectedTheme == theme ? Color.white.opacity(AppTheme.overlayLightOpacity) : Color.clear)
                                    .cornerRadius(AppTheme.cornerRadius12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(AppTheme.spacing24)
                    }
                }
                .padding(AppTheme.spacing24)
            }
        }
        .navigationTitle("Theme")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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

struct NotificationSettingsView: View {
    @AppStorage("timerNotifications") private var timerNotifications = true
    @AppStorage("mealPlanReminders") private var mealPlanReminders = true
    @AppStorage("shoppingListReminders") private var shoppingListReminders = false
    @AppStorage("reminderTime") private var reminderTimeString = "10:00"
    
    @State private var showingTimePicker = false
    @State private var notificationPermission: UNAuthorizationStatus = .notDetermined
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var reminderTime: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: reminderTimeString) ?? Date()
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
                ScrollView {
                VStack(spacing: AppTheme.spacing32) {
                    if notificationPermission != .authorized {
                        SettingsCard {
                            VStack(alignment: .center, spacing: AppTheme.spacing24) {
                                Image(systemName: "bell.slash.fill")
                                    .font(.system(size: AppTheme.fontSize60))
                                    .foregroundColor(.orange)
                                    .padding(.top, AppTheme.spacing10)
                                
                                VStack(spacing: AppTheme.spacing8) {
                                    Text("Notifications Disabled")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .adaptiveForegroundColor()
                                    
                                    Text("Enable notifications in Settings to receive reminders and alerts for timers, meal plans, and shopping lists.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Button(action: {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "gear")
                                        Text("Open Settings")
                                    }
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppTheme.spacing14)
                                    .background(AppTheme.accentColor)
                                    .cornerRadius(AppTheme.cornerRadius12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.bottom, AppTheme.spacing10)
                            }
                            .padding(.horizontal, AppTheme.spacing24)
                            .padding(.vertical, AppTheme.spacing20)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                            Text("Notification Types")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            Toggle(isOn: $timerNotifications) {
                                HStack(spacing: AppTheme.spacing12) {
                                    Image(systemName: "timer")
                                        .adaptiveForegroundColor()
                                        .frame(width: AppTheme.width30)
                                    
                                    VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                        Text("Timer Alerts")
                                            .adaptiveForegroundColor()
                                        Text("Get notified when timers complete")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .tint(AppTheme.accentColor)
                            
                            Divider()
                                .padding(.horizontal, AppTheme.spacing60)
                            
                            Toggle(isOn: $mealPlanReminders) {
                                HStack(spacing: AppTheme.spacing12) {
                                    Image(systemName: "calendar")
                                        .adaptiveForegroundColor()
                                        .frame(width: AppTheme.width30)
                                    
                                    VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                        Text("Meal Plan Reminders")
                                            .adaptiveForegroundColor()
                                        Text("Daily reminders for planned meals")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .tint(AppTheme.accentColor)
                            
                            Divider()
                                .padding(.horizontal, AppTheme.spacing60)
                            
                            Toggle(isOn: $shoppingListReminders) {
                                HStack(spacing: AppTheme.spacing12) {
                                    Image(systemName: "cart")
                                        .adaptiveForegroundColor()
                                        .frame(width: AppTheme.width30)
                                    
                                    VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                        Text("Shopping List Reminders")
                                            .adaptiveForegroundColor()
                                        Text("Remind me about shopping list items")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .tint(AppTheme.accentColor)
                        }
                        .padding(AppTheme.spacing24)
                    }
                    
                    if mealPlanReminders || shoppingListReminders {
                        SettingsCard {
                            VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                                Text("Reminder Time")
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                                
                                Button(action: {
                                    showingTimePicker = true
                                }) {
                                    HStack {
                                        Image(systemName: "clock")
                                            .adaptiveForegroundColor()
                                            .frame(width: AppTheme.width30)
                                        
                                        Text("Daily reminder at")
                                            .adaptiveForegroundColor()
                                        
                                        Spacer()
                                        
                                        Text(reminderTimeString)
                                            .foregroundColor(AppTheme.accentColor)
                                            .fontWeight(.semibold)
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    .padding(AppTheme.spacing16)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(AppTheme.spacing24)
                        }
                    }
                }
                .padding(AppTheme.spacing24)
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingTimePicker) {
            TimePickerSheet(selectedTime: reminderTime) { newTime in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                reminderTimeString = formatter.string(from: newTime)
            }
        }
        .onAppear {
            checkNotificationPermission()
        }
    }
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let status = settings.authorizationStatus
            DispatchQueue.main.async {
                self.notificationPermission = status
            }
        }
    }
}

struct TimePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var selectedTime: Date
    let onSave: (Date) -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Select Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
            }
            .navigationTitle("Reminder Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(selectedTime)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TimerSettingsView: View {
    @AppStorage("defaultTimerDuration") private var defaultTimerDuration: Int = 300
    @AppStorage("timerSound") private var timerSound: TimerSound = .default
    @AppStorage("timerVibration") private var timerVibration: Bool = true
    @AppStorage("showTimerInNotifications") private var showTimerInNotifications: Bool = true
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    enum TimerSound: String, CaseIterable {
        case `default` = "Default"
        case chime = "Chime"
        case bell = "Bell"
        case buzz = "Buzz"
        case silent = "Silent"
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
                ScrollView {
                VStack(spacing: AppTheme.spacing32) {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                            Text("Default Timer Duration")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            VStack(spacing: AppTheme.spacing12) {
                                ForEach([60, 300, 600, 900, 1800, 3600], id: \.self) { seconds in
                                    let label = formatDuration(seconds)
                                    Button(action: {
                                        defaultTimerDuration = seconds
                                        HapticManager.shared.selection()
                                    }) {
                                        HStack {
                                            Image(systemName: "timer")
                                                .adaptiveForegroundColor()
                                                .frame(width: AppTheme.width30)
                                            
                                            Text(label)
                                                .adaptiveForegroundColor()
                                            
                                            Spacer()
                                            
                                            if defaultTimerDuration == seconds {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .adaptiveForegroundColor()
                                            }
                                        }
                                        .padding(AppTheme.spacing12)
                                        .background(
                                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius10)
                                                .fill(defaultTimerDuration == seconds ? AppTheme.secondaryText.opacity(0.2) : Color.clear)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(AppTheme.spacing24)
                    }
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                            Text("Sound & Alerts")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                                Text("Completion Sound")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                ForEach(TimerSound.allCases, id: \.self) { sound in
                                    Button(action: {
                                        timerSound = sound
                                        HapticManager.shared.selection()
                                    }) {
                                        HStack {
                                            Image(systemName: sound == .silent ? "speaker.slash" : "speaker.wave.2")
                                                .adaptiveForegroundColor()
                                                .frame(width: AppTheme.width30)
                                            
                                            Text(sound.rawValue)
                                                .adaptiveForegroundColor()
                                            
                                            Spacer()
                                            
                                            if timerSound == sound {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .adaptiveForegroundColor()
                                            }
                                        }
                                        .padding(AppTheme.spacing12)
                                        .background(
                                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius10)
                                                .fill(timerSound == sound ? AppTheme.secondaryText.opacity(0.2) : Color.clear)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            Divider()
                                .padding(.vertical, AppTheme.spacing4)
                            
                            Toggle(isOn: $timerVibration) {
                                HStack(spacing: AppTheme.spacing12) {
                                    Image(systemName: "iphone.radiowaves.left.and.right")
                                        .adaptiveForegroundColor()
                                        .frame(width: AppTheme.width30)
                                    
                                    VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                        Text("Vibration")
                                            .adaptiveForegroundColor()
                                        Text("Vibrate when timer completes")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .tint(AppTheme.accentColor)
                        }
                        .padding(AppTheme.spacing24)
                    }
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                            Text("Behavior")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            Toggle(isOn: $showTimerInNotifications) {
                                HStack(spacing: AppTheme.spacing12) {
                                    Image(systemName: "app.badge")
                                        .adaptiveForegroundColor()
                                        .frame(width: AppTheme.width30)
                                    
                                    VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                        Text("Show in Notifications")
                                            .adaptiveForegroundColor()
                                        Text("Display running timers in notification center")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .tint(AppTheme.accentColor)
                        }
                        .padding(AppTheme.spacing24)
                    }
                }
                .padding(AppTheme.spacing24)
        }
        .navigationTitle("Timers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) seconds"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            let hours = seconds / 3600
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
    }
}

struct UnitsSettingsView: View {
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
                ScrollView {
                VStack(spacing: AppTheme.spacing32) {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                            Text("Measurement System")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            ForEach(MeasurementSystem.allCases, id: \.self) { system in
                                Button(action: {
                                    measurementSystem = system
                                    HapticManager.shared.selection()
                                }) {
                                    HStack(spacing: AppTheme.spacing16) {
                                        Image(systemName: system == .metric ? "ruler" : "ruler.fill")
                                            .font(.title3)
                                            .adaptiveForegroundColor()
                                            .frame(width: AppTheme.width30)
                                        
                                        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                            Text(system.rawValue)
                                                .adaptiveForegroundColor()
                                            Text(system == .metric ? "kg, g, ml, l" : "lb, oz, cups, fl oz")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if measurementSystem == system {
                                            Image(systemName: "checkmark.circle.fill")
                                                .adaptiveForegroundColor()
                                        }
                                    }
                                    .padding(AppTheme.spacing16)
                                    .background(measurementSystem == system ? AppTheme.secondaryText.opacity(0.2) : Color.clear)
                                    .cornerRadius(AppTheme.cornerRadius12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(AppTheme.spacing24)
                    }
                }
                .padding(AppTheme.spacing24)
        }
        .navigationTitle("Units & Measurements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
}

struct DisplaySettingsView: View {
    @AppStorage("keepScreenAwake") private var keepScreenAwake: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.spacing32) {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                            Text("Screen Settings")
                                .font(.headline)
                                .adaptiveForegroundColor()

                            Toggle(isOn: $keepScreenAwake) {
                                HStack(spacing: AppTheme.spacing12) {
                                    Image(systemName: "light.max")
                                        .adaptiveForegroundColor()
                                        .frame(width: AppTheme.width30)

                                    VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                        Text("Keep Screen Awake")
                                            .adaptiveForegroundColor()
                                        Text("Prevent screen from dimming while cooking")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .tint(AppTheme.accentColor)
                        }
                        .padding(AppTheme.spacing24)
                    }

                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            HStack(spacing: AppTheme.spacing12) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title3)

                                Text("About This Setting")
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                            }

                            Text("When enabled, your screen will stay on while you're viewing recipes or using timers. This is helpful when cooking and you need to reference instructions without constantly touching your device.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            Divider()
                                .padding(.vertical, AppTheme.spacing4)

                            HStack(spacing: AppTheme.spacing8) {
                                Image(systemName: "battery.100")
                                    .foregroundColor(.green)
                                    .font(.caption)

                                Text("Note: Keeping the screen on may use more battery")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(AppTheme.spacing24)
                    }
                }
                .padding(AppTheme.spacing24)
            }
        }
        .navigationTitle("Display")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

struct PrivacySettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @StateObject private var authManager = AuthenticationManager.shared
    @AppStorage("biometricsEnabled") private var biometricsEnabled: Bool = false
    @State private var showPrivacyPolicy = false
    @State private var showBiometricError = false
    @State private var biometricErrorMessage = ""
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.spacing32) {
                    if authManager.biometricsAvailable {
                        SettingsCard {
                            VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                                Text("Security")
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                                
                                Toggle(isOn: Binding(
                                    get: { biometricsEnabled },
                                    set: { newValue in
                                        if newValue {
                                            enableBiometrics()
                                        } else {
                                            biometricsEnabled = false
                                            HapticManager.shared.light()
                                        }
                                    }
                                )) {
                                    HStack(spacing: AppTheme.spacing12) {
                                        Image(systemName: authManager.biometricType == "Face ID" ? "faceid" : "touchid")
                                            .adaptiveForegroundColor()
                                            .frame(width: AppTheme.width30)
                                        
                                        VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                            Text("\(authManager.biometricType)")
                                                .adaptiveForegroundColor()
                                            Text("Sign in with \(authManager.biometricType) instead of password")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .tint(AppTheme.accentColor)
                            }
                            .padding(AppTheme.spacing24)
                        }
                    }
                    
                    SettingsCard {
                        VStack(spacing: 0) {
                            Button(action: {
                                showPrivacyPolicy = true
                                HapticManager.shared.light()
                            }) {
                                HStack(spacing: AppTheme.spacing12) {
                                    Image(systemName: "hand.raised.fill")
                                        .foregroundColor(.blue)
                                        .frame(width: AppTheme.width30)
                                    
                                    VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                        Text("Privacy Policy")
                                            .adaptiveForegroundColor()
                                        Text("View our privacy and data practices")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                .padding(AppTheme.spacing24)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                }
                .padding(AppTheme.spacing24)
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .alert("Biometric Error", isPresented: $showBiometricError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(biometricErrorMessage)
        }
    }
    
    private func enableBiometrics() {
        Task {
            do {
                try await authManager.authenticateWithBiometrics()
                DispatchQueue.main.async {
                    biometricsEnabled = true
                    HapticManager.shared.success()
                }
            } catch {
                DispatchQueue.main.async {
                    biometricErrorMessage = error.localizedDescription
                    showBiometricError = true
                    HapticManager.shared.error()
                }
            }
        }
    }
}

struct PrivacyInfoRow: View {
    let icon: String
    var iconColor: Color = .green
    let title: String
    let description: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacing16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(AppTheme.cardDarkOpacity))
                    .frame(width: 40, height: AppTheme.height40)
                
                Image(systemName: icon)
                    .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct DataManagementSettingsView: View {
    @State private var showingResetAlert = false
    @State private var dataCleared = false
    @AppStorage("skipRecipeDeleteConfirmation") private var skipDeleteConfirmation: Bool = false
    @State private var showResetSuccess = false
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.spacing32) {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                            HStack(spacing: AppTheme.spacing12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                
                                VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                    Text("Reset App to Default")
                                        .font(.headline)
                                        .adaptiveForegroundColor()
                                    
                                    Text("Use this option if something goes wrong")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Text("This will reset the app to its initial state, clearing all your data and restoring default settings with sample recipes. Use this if you encounter issues or want a fresh start.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Divider()
                                .padding(.vertical, AppTheme.spacing4)
                            
                            Button(action: {
                                showingResetAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.body)
                                    Text("Reset to Default")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                }
                                .adaptiveForegroundColor()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.spacing12)
                                .background(Color.orange)
                                .cornerRadius(AppTheme.cornerRadius12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(AppTheme.spacing24)
                    }
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                            Text("Delete Confirmations")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            Toggle(isOn: Binding(
                                get: { !skipDeleteConfirmation },
                                set: { skipDeleteConfirmation = !$0 }
                            )) {
                                HStack(spacing: AppTheme.spacing12) {
                                    Image(systemName: "trash.circle")
                                        .adaptiveForegroundColor()
                                        .frame(width: AppTheme.width30)
                                    
                                    VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                        Text("Ask before deleting recipes")
                                            .adaptiveForegroundColor()
                                        Text(skipDeleteConfirmation ? "Recipes delete immediately on swipe" : "You'll be asked to confirm first")
                                            .font(.caption)
                                            .foregroundColor(skipDeleteConfirmation ? .orange : .secondary)
                                    }
                                }
                            }
                            .tint(AppTheme.accentColor)
                            
                            if showResetSuccess {
                                HStack(spacing: AppTheme.spacing8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Delete confirmations re-enabled")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(AppTheme.spacing24)
                    }
                    
                    if dataCleared {
                        Text("✓ Data cleared successfully")
                            .foregroundColor(.green)
                            .padding()
                    }
                }
                .padding(AppTheme.spacing24)
            }
        }
        .animation(.spring(response: 0.3), value: showResetSuccess)
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .alert("Reset to Default", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetToDefault()
            }
        } message: {
            Text("This will reset the app to factory defaults, clearing all your data and restoring sample recipes. Use this if you encounter any issues. This action cannot be undone!")
        }
    }
    
    private func resetToDefault() {
        let context = PersistenceController.shared.container.viewContext
        
        let recipeFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Recipe")
        let recipeBatchDelete = NSBatchDeleteRequest(fetchRequest: recipeFetch)
        _ = try? context.execute(recipeBatchDelete)
        _ = try? context.save()
        
        KitchenInventoryManager.shared.clearAll()
        ShoppingListManager.shared.clearAllItems()
        
        let defaults = UserDefaults.standard
        if let domain = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: domain)
            defaults.synchronize()
        }
        
        defaults.set("Teal", forKey: "appTheme")
        defaults.set("Frost Light", forKey: "cardStyle")
        defaults.set("metric", forKey: "measurementSystem")
        defaults.set(300, forKey: "defaultTimerDuration")
        
        PersistenceController.shared.populateDatabase()
        
        dataCleared = true
        HapticManager.shared.success()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayFeedback) {
            dataCleared = false
        }
    }
}

struct HelpView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @State private var showOnboarding = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.spacing32) {
                    SettingsCard {
                        Button(action: {
                            showOnboarding = true
                            HapticManager.shared.light()
                        }) {
                            HStack(spacing: AppTheme.spacing16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.purple.opacity(AppTheme.cardDarkOpacity))
                                        .frame(width: 50, height: AppTheme.height50)
                                    
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.purple)
                                }
                                
                                VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                    Text("Take the App Tour")
                                        .font(.headline)
                                        .adaptiveForegroundColor()
                                    
                                    Text("Learn how to use RecipeFinder")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding(AppTheme.spacing24)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                            Text("Getting Started")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            HelpItem(
                                icon: "magnifyingglass",
                                title: "Finding Recipes",
                                description: "Search by name, ingredients, or browse categories. Use the burger menu to access filters and sorting options."
                            )
                            
                            HelpItem(
                                icon: "heart.fill",
                                title: "Saving Favorites",
                                description: "Tap the heart icon on any recipe to add it to your favorites for quick access later."
                            )
                            
                            HelpItem(
                                icon: "calendar",
                                title: "Meal Planning",
                                description: "Plan your weekly meals by tapping dates and assigning recipes to breakfast, lunch, or dinner."
                            )
                            
                            HelpItem(
                                icon: "refrigerator",
                                title: "Managing Your Kitchen",
                                description: "Track ingredients you have on hand, set expiration dates, and manage storage locations."
                            )
                            
                            HelpItem(
                                icon: "cart",
                                title: "Shopping Lists",
                                description: "Create shopping lists from recipes or add items manually. Check them off as you shop!"
                            )
                            
                            HelpItem(
                                icon: "timer",
                                title: "Cooking Timers",
                                description: "Set multiple timers while cooking. Use preset buttons or create custom timers with names."
                            )
                            
                            HelpItem(
                                icon: "note.text",
                                title: "Recipe Notes",
                                description: "Add personal notes, modifications, and ratings to any recipe to remember what worked."
                            )
                        }
                        .padding(AppTheme.spacing24)
                    }
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                            Text("Tips & Tricks")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            HelpItem(
                                icon: "square.and.arrow.up",
                                title: "Sharing Recipes",
                                description: "Tap the share button on any recipe to send as text or beautiful PDF."
                            )
                            
                            HelpItem(
                                icon: "paintpalette",
                                title: "Customize Appearance",
                                description: "Choose from 8 beautiful themes and frosted or solid card styles in Settings > Appearance."
                            )
                            
                            HelpItem(
                                icon: "star",
                                title: "Smart Filters",
                                description: "Use the burger menu in Recipes to filter by difficulty, prep time, or category."
                            )
                            
                            HelpItem(
                                icon: "link",
                                title: "Import Recipes",
                                description: "Paste any recipe URL in the burger menu to automatically import it into your collection."
                            )
                        }
                        .padding(AppTheme.spacing24)
                    }
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                            Text("Contact Support")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            Button(action: {
                                if let url = URL(string: "mailto:recipefinderlimited@icloud.com?subject=RecipeFinder%20Support") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: AppTheme.spacing16) {
                                    Image(systemName: "envelope.fill")
                                        .font(.title3)
                                        .adaptiveForegroundColor()
                                        .frame(width: AppTheme.width30)
                                    
                                    VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                        Text("Email Support")
                                            .adaptiveForegroundColor()
                                        Text("recipefinderlimited@icloud.com")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(AppTheme.spacing16)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                if let url = URL(string: "https://recipefinder.uk") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: AppTheme.spacing16) {
                                    Image(systemName: "globe")
                                        .font(.title3)
                                        .adaptiveForegroundColor()
                                        .frame(width: AppTheme.width30)
                                    
                                    VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                        Text("Visit Website")
                                            .adaptiveForegroundColor()
                                        Text("recipefinder.uk")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(AppTheme.spacing16)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(AppTheme.spacing24)
                    }
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
                            Text("Frequently Asked Questions")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            FAQItem(
                                question: "Is RecipeFinder free to use?",
                                answer: "Yes! RecipeFinder is free with optional premium features coming soon."
                            )
                            
                            FAQItem(
                                question: "Does the app work offline?",
                                answer: "Yes. Your saved recipes and data are accessible offline."
                            )
                            
                            FAQItem(
                                question: "Can I import my own recipes?",
                                answer: "Absolutely! Use the recipe import feature in the burger menu to paste any recipe URL, or create recipes manually."
                            )
                            
                            FAQItem(
                                question: "How do I backup my data?",
                                answer: "Your data is automatically saved. You can also export your data from the Account tab."
                            )
                            
                            FAQItem(
                                question: "Can I share recipes with friends?",
                                answer: "Yes! Use the share button on any recipe to export as text or PDF that you can send via any app."
                            )
                            
                            FAQItem(
                                question: "How do I change the app theme?",
                                answer: "Go to Settings > Appearance & Theme to choose from 8 beautiful color themes and card styles."
                            )
                            
                            FAQItem(
                                question: "Is my data private and secure?",
                                answer: "Yes. See our Privacy Policy for full details on how we handle your information."
                            )
                            
                            FAQItem(
                                question: "How do I delete my account?",
                                answer: "Go to Settings > Account > Delete Account. Note that this will remove all your data permanently."
                            )
                        }
                        .padding(AppTheme.spacing24)
                    }
                }
                .padding(AppTheme.spacing24)
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
}

struct HelpItem: View {
    let icon: String
    let title: String
    let description: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacing16) {
            Image(systemName: icon)
                .font(.title3)
                .adaptiveForegroundColor()
                .frame(width: AppTheme.width30)
            
            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                HapticManager.shared.light()
            }) {
                HStack(alignment: .top, spacing: AppTheme.spacing12) {
                    Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.accentColor)
                        .frame(width: AppTheme.width30)
                    
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .adaptiveForegroundColor()
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(answer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, AppTheme.spacing42)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct AboutView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.spacing40) {
                    VStack(spacing: AppTheme.spacing16) {
                        Image(systemName: "book.circle.fill")
                            .font(.system(size: AppTheme.fontSize80))
                            .foregroundColor(AppTheme.accentColor(for: appTheme))
                        
                        Text("RecipeFinder")
                            .font(.system(size: AppTheme.fontSize32, weight: .bold))
                            .adaptiveForegroundColor()
                        
                        Text("Your Personal Cooking Companion")
                            .font(.subheadline)
                            .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppTheme.spacing40)
                    
                    SettingsCard {
                        VStack(spacing: AppTheme.spacing16) {
                            HStack {
                                Text("Version")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(appVersion)
                                    .fontWeight(.medium)
                                    .adaptiveForegroundColor()
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Build")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(buildNumber)
                                    .fontWeight(.medium)
                                    .adaptiveForegroundColor()
                            }
                        }
                        .padding(AppTheme.spacing24)
                    }
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                            Text("Legal Information")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                                Text("© 2025 RecipeFinder")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("All rights reserved")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            Text("For Terms of Service and Privacy Policy, please visit the Legal Information section in Settings.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(AppTheme.spacing24)
                    }
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            Text("Support")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            Button(action: {
                                if let url = URL(string: "mailto:recipefinderlimited@icloud.com") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(AppTheme.accentColor(for: appTheme))
                                    Text("recipefinderlimited@icloud.com")
                                        .font(.subheadline)
                                        .adaptiveForegroundColor()
                                }
                            }
                        }
                        .padding(AppTheme.spacing24)
                    }
                    
                    Text("Made with ❤️ for home cooks")
                        .font(.caption)
                        .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                    .padding(.bottom, AppTheme.spacing40)
                }
                .padding(.horizontal, AppTheme.spacing20)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

struct AboutFeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: AppTheme.iconSize20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(AppTheme.adaptiveEmphasis(for: colorScheme, level: AppTheme.cardLightOpacity))
        }
    }
}

struct PartyTimeView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @State private var isVibrating = false
    @State private var vibrationTimer: Timer?
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
                ScrollView {
                    VStack(spacing: AppTheme.spacing40) {
                        VStack(spacing: AppTheme.spacing12) {
                            Image(systemName: "party.popper.fill")
                                .font(.system(size: AppTheme.fontSize60))
                                .foregroundColor(AppTheme.accentColor(for: appTheme))
                                .symbolEffect(.bounce, value: isVibrating)
                            
                            Text("Party Time")
                                .font(.title)
                                .fontWeight(.bold)
                                .adaptiveForegroundColor()
                            
                            Text("Press and hold the button below for continuous vibration")
                                .font(.subheadline)
                                .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppTheme.spacing40)
                        }
                        .padding(.top, AppTheme.spacing40)
                        
                        VStack(spacing: AppTheme.spacing16) {
                            ZStack {
                                if isVibrating {
                                    ForEach(0..<3) { index in
                                        Circle()
                                            .stroke(AppTheme.accentColor(for: appTheme).opacity(0.3), lineWidth: 2)
                                            .frame(width: AppTheme.width200, height: AppTheme.height200)
                                            .scaleEffect(isVibrating ? AppTheme.scaleEffectBounce : AppTheme.scaleNeutral)
                                            .opacity(isVibrating ? AppTheme.zeroOpacity : AppTheme.highEmphasisOpacity)
                                            .animation(
                                                .easeOut(duration: AppTheme.animationDelayXLong)
                                                .repeatForever(autoreverses: false)
                                                .delay(Double(index) * 0.3),
                                                value: isVibrating
                                            )
                                    }
                                }
                                
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: isVibrating ? 
                                                [AppTheme.accentColor(for: appTheme), AppTheme.accentColor(for: appTheme).opacity(0.7)] :
                                                [AppTheme.accentColor(for: appTheme).opacity(0.8), AppTheme.accentColor(for: appTheme).opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: AppTheme.width200, height: AppTheme.height200)
                                    .shadow(color: AppTheme.accentColor(for: appTheme).opacity(0.5), radius: isVibrating ? AppTheme.shadowRadiusGlowActive : AppTheme.shadowRadiusGlow)
                                    .scaleEffect(isVibrating ? AppTheme.transitionScaleUp : AppTheme.scaleNeutral)
                                    .animation(.easeInOut(duration: AppTheme.animationDelayMedium).repeatForever(autoreverses: true), value: isVibrating)
                                
                                Image(systemName: isVibrating ? "iphone.radiowaves.left.and.right" : "hand.tap.fill")
                                    .font(.system(size: AppTheme.fontSize60))
                                    .adaptiveForegroundColor()
                                    .symbolEffect(.bounce, options: .repeating, value: isVibrating)
                            }
                            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                                if pressing {
                                    startVibration()
                                } else {
                                    stopVibration()
                                }
                            }, perform: {})
                            
                            Text(isVibrating ? "Release to stop" : "Press and hold to start")
                                .font(.caption)
                                .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                        }
                        .padding(.vertical, AppTheme.spacing40)
                        
                        SettingsCard {
                            VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("How it works")
                                        .font(.headline)
                                        .adaptiveForegroundColor()
                                }
                                
                                VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                                    BulletPoint("Press and hold the button")
                                    BulletPoint("Your device will vibrate continuously")
                                    BulletPoint("Release to stop the vibration")
                                    BulletPoint("Perfect for getting attention or just having fun!")
                                }
                            }
                            .padding(AppTheme.spacing24)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                }
        }
        .navigationTitle("Party Time")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onDisappear {
            stopVibration()
        }
    }
    
    private func startVibration() {
        isVibrating = true
        
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    private func stopVibration() {
        isVibrating = false
        vibrationTimer?.invalidate()
        vibrationTimer = nil
    }
}

private struct BulletPoint: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacing8) {
            Text("•")
                .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
            Text(text)
                .font(.subheadline)
                .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
        }
    }
}

#Preview {
    SettingsTabView()
        .environmentObject(KitchenInventoryManager.shared)
        .environmentObject(ShoppingListManager.shared)
        .environment(\.appTheme, AppTheme.ThemeType.teal)
}
