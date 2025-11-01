import SwiftUI
import AudioToolbox
import CoreData

enum CardStyle: String, CaseIterable {
    case frosted = "Frost Light"
    case solid = "Solid Dark"
}

struct SettingsTabView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @State private var notificationsEnabled: Bool = false
    @State private var cookModeEnabled: Bool = true
    @StateObject private var accountManager = AccountManager.shared
    @EnvironmentObject var kitchenManager: KitchenInventoryManager
    @EnvironmentObject var shoppingListManager: ShoppingListManager
    
    enum AppearanceMode: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        
        var icon: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            }
        }
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme, cardStyle: cardStyle)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        HStack {
                            Spacer()
                            Text("Settings")
                                .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .frame(height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                    
                ScrollView {
                    VStack(spacing: 24) {
                        // Account Section Header
                        SettingsSectionHeader(title: "Account")
                        
                        // Account Card
                        SettingsCard {
                                NavigationLink(destination: AccountView()) {
                                    HStack(spacing: 16) {
                                        Circle()
                                            .fill(AppTheme.accentColor(for: selectedTheme))
                                            .frame(width: 56, height: 56)
                                            .overlay {
                                                Text(accountManager.initials)
                                                    .font(.system(size: 22, weight: .semibold))
                                                    .foregroundStyle(.white)
                                            }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(accountManager.fullName.isEmpty ? accountManager.email : accountManager.fullName)
                                                .font(.headline)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            
                                            Text("Apple ID, iCloud & More")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                    }
                                    .padding(20)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Personalization
                            SettingsSectionHeader(title: "Personalization")
                            
                            SettingsCard {
                                NavigationLink(destination: AppearanceAndThemeSettingsView()) {
                                    SettingsRow(icon: "paintpalette.fill", iconColor: .pink, title: "Appearance & Theme")
                                        .padding(20)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Cooking
                            SettingsSectionHeader(title: "Cooking")
                            
                            SettingsCard {
                                VStack(spacing: 0) {
                                    NavigationLink(destination: NotificationSettingsView()) {
                                        SettingsRow(icon: "bell.fill", iconColor: .red, title: "Notifications")
                                            .padding(20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Divider()
                                        .padding(.leading, 60)
                                    
                                    NavigationLink(destination: TimerSettingsView()) {
                                        SettingsRow(icon: "timer", iconColor: .orange, title: "Timers")
                                            .padding(20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Divider()
                                        .padding(.leading, 60)
                                    
                                    NavigationLink(destination: UnitsSettingsView()) {
                                        SettingsRow(icon: "ruler.fill", iconColor: .blue, title: "Units & Measurements")
                                            .padding(20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Divider()
                                        .padding(.leading, 60)
                                    
                                    NavigationLink(destination: DisplaySettingsView()) {
                                        SettingsRow(icon: "display", iconColor: .cyan, title: "Display")
                                            .padding(20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Divider()
                                        .padding(.leading, 60)
                                    
                                    NavigationLink(destination: PartyTimeView()) {
                                        SettingsRow(icon: "party.popper.fill", iconColor: .purple, title: "Party Time")
                                            .padding(20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            // Privacy & Data
                            SettingsSectionHeader(title: "Privacy & Data")
                            
                            SettingsCard {
                                VStack(spacing: 0) {
                                    NavigationLink(destination: PrivacySettingsView()) {
                                        SettingsRow(icon: "hand.raised.fill", iconColor: .blue, title: "Privacy")
                                            .padding(20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Divider()
                                        .padding(.leading, 60)
                                    
                                    NavigationLink(destination: DataManagementSettingsView()
                                        .environmentObject(kitchenManager)
                                        .environmentObject(shoppingListManager)
                                    ) {
                                        SettingsRow(icon: "externaldrive.fill", iconColor: .gray, title: "Data Management")
                                            .padding(20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            // Support
                            SettingsSectionHeader(title: "Support")
                            
                            SettingsCard {
                                VStack(spacing: 0) {
                                    NavigationLink(destination: HelpView()) {
                                        SettingsRow(icon: "questionmark.circle.fill", iconColor: .teal, title: "Help & Support")
                                            .padding(20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Divider()
                                        .padding(.leading, 60)
                                    
                                    NavigationLink(destination: AboutView()) {
                                        SettingsRow(icon: "info.circle.fill", iconColor: .gray, title: "About RecipeFinder")
                                            .padding(20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            // App Info
                            VStack(spacing: 4) {
                                Text("RecipeFinder")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                Text("Version 1.0.0 (Build 1)")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.top, 24)
                            .padding(.bottom, 40)
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

// Settings Components

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
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                }
            }
    }
}

struct SettingsSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white.opacity(0.8))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.top, 8)
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(iconColor)
                    .frame(width: 29, height: 29)
                
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// Settings Detail Views

struct AppearanceAndThemeSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: SettingsTabView.AppearanceMode = .system
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme, cardStyle: cardStyle)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Appearance Mode Section
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "circle.lefthalf.filled")
                                    .font(.title2)
                                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                
                                Text("Appearance Mode")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                            
                            Text("Choose between light and dark mode, or follow system settings.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            // System
                            Button(action: {
                                appearanceMode = .system
                                cardStyle = colorScheme == .dark ? .solid : .frosted
                                HapticManager.shared.selection()
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.15))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: "circle.lefthalf.filled")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("System")
                                            .font(.body)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        
                                        Text(colorScheme == .dark ? "Currently: Fire Dark" : "Currently: Frost Light")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if appearanceMode == .system {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                    }
                                }
                                .padding(12)
                                .background(appearanceMode == .system ? Color.gray.opacity(0.15) : Color.clear)
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Frost Light
                            Button(action: {
                                appearanceMode = .light
                                cardStyle = .frosted
                                HapticManager.shared.selection()
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.cyan.opacity(0.15))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: "sparkles")
                                            .font(.title3)
                                            .foregroundColor(.cyan)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Frost Light")
                                            .font(.body)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        
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
                                .padding(12)
                                .background(appearanceMode == .light ? Color.gray.opacity(0.15) : Color.clear)
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Fire Dark
                            Button(action: {
                                appearanceMode = .dark
                                cardStyle = .solid
                                HapticManager.shared.selection()
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.orange.opacity(0.15))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: "flame.fill")
                                            .font(.title3)
                                            .foregroundColor(.orange)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Fire Dark")
                                            .font(.body)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        
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
                                .padding(12)
                                .background(appearanceMode == .dark ? Color.gray.opacity(0.15) : Color.clear)
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(20)
                    }
                    
                    // Color Theme Section
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.title2)
                                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                
                                Text("Color Theme")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                            
                            Text("Choose your favorite accent color for the app.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(AppTheme.ThemeType.allCases) { theme in
                                    Button(action: {
                                        selectedTheme = theme
                                        HapticManager.shared.selection()
                                    }) {
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(AppTheme.accentColor(for: theme))
                                                .frame(width: 32, height: 32)
                                                .overlay(
                                                    Circle()
                                                        .strokeBorder(selectedTheme == theme ? Color.white : Color.clear, lineWidth: 2)
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(theme.rawValue)
                                                    .font(.subheadline)
                                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                                
                                                if selectedTheme == theme {
                                                    Image(systemName: "checkmark")
                                                        .font(.caption2)
                                                        .foregroundColor(AppTheme.accentColor(for: theme))
                                                }
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(selectedTheme == theme ? AppTheme.accentColor(for: theme).opacity(0.15) : Color.gray.opacity(0.05))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(20)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Appearance & Theme")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onChange(of: appearanceMode) { _, newMode in
            // Auto-update card style when mode changes
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

// Keep old views for backwards compatibility but mark as deprecated
struct AppearanceSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: SettingsTabView.AppearanceMode = .system
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    // Computed property that returns the effective card style based on mode
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
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme, cardStyle: cardStyle)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Info
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "paintpalette.fill")
                                    .font(.title2)
                                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                
                                Text("Appearance")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                            
                            Text("Choose your preferred appearance mode. Each mode automatically applies the best card style.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(20)
                    }
                    
                    // Appearance Modes
                    SettingsCard {
                        VStack(spacing: 0) {
                            // System
                            Button(action: {
                                appearanceMode = .system
                                // Update card style based on current system scheme
                                cardStyle = colorScheme == .dark ? .solid : .frosted
                                HapticManager.shared.selection()
                            }) {
                                VStack(spacing: 0) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(AppTheme.accentColor(for: selectedTheme).opacity(0.2))
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: "circle.lefthalf.filled")
                                                .font(.title3)
                                                .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("System")
                                                .font(.headline)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            
                                            Text("Follows device settings")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Text(colorScheme == .dark ? "Currently: Fire Dark" : "Currently: Frost Light")
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
                                    .padding(20)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading, 86)
                            
                            // Frost Light
                            Button(action: {
                                appearanceMode = .light
                                cardStyle = .frosted
                                HapticManager.shared.selection()
                            }) {
                                VStack(spacing: 0) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.cyan.opacity(0.2))
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: "sparkles")
                                                .font(.title3)
                                                .foregroundColor(.cyan)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Frost Light")
                                                .font(.headline)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            
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
                                    .padding(20)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading, 86)
                            
                            // Fire Dark
                            Button(action: {
                                appearanceMode = .dark
                                cardStyle = .solid
                                HapticManager.shared.selection()
                            }) {
                                VStack(spacing: 0) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.orange.opacity(0.2))
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: "flame.fill")
                                                .font(.title3)
                                                .foregroundColor(.orange)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Fire Dark")
                                                .font(.headline)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            
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
                                    .padding(20)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onChange(of: appearanceMode) { _, newMode in
            // Auto-update card style when mode changes
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
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme, cardStyle: cardStyle)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Select Theme")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            ForEach(AppTheme.ThemeType.allCases) { theme in
                                Button(action: {
                                    selectedTheme = theme
                                    HapticManager.shared.selection()
                                }) {
                                    HStack(spacing: 16) {
                                        // Theme preview circle with gradient
                                        Circle()
                                            .fill(AppTheme.accentColor(for: theme))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedTheme == theme ? Color.white : Color.clear, lineWidth: 3)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(theme.rawValue)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                                .font(.body)
                                            
                                            Text(themeDescription(for: theme))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedTheme == theme {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.white)
                                                .font(.title3)
                                        }
                                    }
                                    .padding(16)
                                    .background(selectedTheme == theme ? Color.white.opacity(0.2) : Color.clear)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(20)
                    }
                }
                .padding(20)
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
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme, cardStyle: cardStyle)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    if notificationPermission != .authorized {
                        SettingsCard {
                            VStack(alignment: .center, spacing: 20) {
                                Image(systemName: "bell.slash.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.orange)
                                    .padding(.top, 10)
                                
                                VStack(spacing: 8) {
                                    Text("Notifications Disabled")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                    
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
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(AppTheme.accentColor)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.bottom, 10)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Notification Types")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Toggle(isOn: $timerNotifications) {
                                HStack(spacing: 12) {
                                    Image(systemName: "timer")
                                        .foregroundColor(AppTheme.accentColor)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Timer Alerts")
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        Text("Get notified when timers complete")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .tint(AppTheme.accentColor)
                            
                            Divider()
                                .padding(.horizontal, 60)
                            
                            Toggle(isOn: $mealPlanReminders) {
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(AppTheme.accentColor)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Meal Plan Reminders")
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        Text("Daily reminders for planned meals")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .tint(AppTheme.accentColor)
                            
                            Divider()
                                .padding(.horizontal, 60)
                            
                            Toggle(isOn: $shoppingListReminders) {
                                HStack(spacing: 12) {
                                    Image(systemName: "cart")
                                        .foregroundColor(AppTheme.accentColor)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Shopping List Reminders")
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        Text("Remind me about shopping list items")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .tint(AppTheme.accentColor)
                        }
                        .padding(20)
                    }
                    
                    if mealPlanReminders || shoppingListReminders {
                        SettingsCard {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Reminder Time")
                                    .font(.headline)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                
                                Button(action: {
                                    showingTimePicker = true
                                }) {
                                    HStack {
                                        Image(systemName: "clock")
                                            .foregroundColor(AppTheme.accentColor)
                                            .frame(width: 30)
                                        
                                        Text("Daily reminder at")
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        
                                        Spacer()
                                        
                                        Text(reminderTimeString)
                                            .foregroundColor(AppTheme.accentColor)
                                            .fontWeight(.semibold)
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    .padding(16)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(20)
                        }
                    }
                }
                .padding(20)
            }
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
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationPermission = settings.authorizationStatus
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
    @AppStorage("defaultTimerDuration") private var defaultTimerDuration: Int = 300 // 5 minutes in seconds
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
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme, cardStyle: cardStyle)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Default Duration
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Default Timer Duration")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            VStack(spacing: 12) {
                                ForEach([60, 300, 600, 900, 1800, 3600], id: \.self) { seconds in
                                    let label = formatDuration(seconds)
                                    Button(action: {
                                        defaultTimerDuration = seconds
                                        HapticManager.shared.selection()
                                    }) {
                                        HStack {
                                            Image(systemName: "timer")
                                                .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                                .frame(width: 30)
                                            
                                            Text(label)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            
                                            Spacer()
                                            
                                            if defaultTimerDuration == seconds {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                            }
                                        }
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(defaultTimerDuration == seconds ? Color.gray.opacity(0.2) : Color.clear)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(20)
                    }
                    
                    // Sound Settings
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Sound & Alerts")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            // Timer Sound
                            VStack(alignment: .leading, spacing: 12) {
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
                                                .foregroundColor(AppTheme.accentColor)
                                                .frame(width: 30)
                                            
                                            Text(sound.rawValue)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            
                                            Spacer()
                                            
                                            if timerSound == sound {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(AppTheme.accentColor)
                                            }
                                        }
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(timerSound == sound ? Color.gray.opacity(0.2) : Color.clear)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            // Vibration
                            Toggle(isOn: $timerVibration) {
                                HStack(spacing: 12) {
                                    Image(systemName: "iphone.radiowaves.left.and.right")
                                        .foregroundColor(AppTheme.accentColor)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Vibration")
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        Text("Vibrate when timer completes")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .tint(AppTheme.accentColor)
                        }
                        .padding(20)
                    }
                    
                    // Behavior Settings
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Behavior")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Toggle(isOn: $showTimerInNotifications) {
                                HStack(spacing: 12) {
                                    Image(systemName: "app.badge")
                                        .foregroundColor(AppTheme.accentColor)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Show in Notifications")
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        Text("Display running timers in notification center")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .tint(AppTheme.accentColor)
                        }
                        .padding(20)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Timers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
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
    @AppStorage("temperatureUnit") private var temperatureUnit: TemperatureUnit = .celsius
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme, cardStyle: cardStyle)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Measurement System")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            ForEach(MeasurementSystem.allCases, id: \.self) { system in
                                Button(action: {
                                    measurementSystem = system
                                    HapticManager.shared.selection()
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: system == .metric ? "ruler" : "ruler.fill")
                                            .font(.title3)
                                            .foregroundColor(AppTheme.accentColor)
                                            .frame(width: 30)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(system.rawValue)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            Text(system == .metric ? "kg, g, ml, l" : "lb, oz, cups, fl oz")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if measurementSystem == system {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(AppTheme.accentColor)
                                        }
                                    }
                                    .padding(16)
                                    .background(measurementSystem == system ? Color.gray.opacity(0.2) : Color.clear)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(20)
                    }
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Temperature Unit")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                                Button(action: {
                                    temperatureUnit = unit
                                    HapticManager.shared.selection()
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "thermometer")
                                            .font(.title3)
                                            .foregroundColor(AppTheme.accentColor)
                                            .frame(width: 30)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(unit.rawValue)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            Text(unit == .celsius ? "°C" : "°F")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if temperatureUnit == unit {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(AppTheme.accentColor)
                                        }
                                    }
                                    .padding(16)
                                    .background(temperatureUnit == unit ? Color.gray.opacity(0.2) : Color.clear)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(20)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Units & Measurements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

struct DisplaySettingsView: View {
    @AppStorage("keepScreenAwake") private var keepScreenAwake: Bool = false
    @AppStorage("brightnessBoost") private var brightnessBoost: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme, cardStyle: cardStyle)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Screen Settings
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Screen Settings")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Toggle(isOn: $keepScreenAwake) {
                                HStack(spacing: 12) {
                                    Image(systemName: "light.max")
                                        .foregroundColor(AppTheme.accentColor)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Keep Screen Awake")
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        Text("Prevent screen from dimming while cooking")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .tint(AppTheme.accentColor)
                        }
                        .padding(20)
                    }
                    
                    // Information Card
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                                
                                Text("About This Setting")
                                    .font(.headline)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                            
                            Text("When enabled, your screen will stay on while you're viewing recipes or using timers. This is helpful when cooking and you need to reference instructions without constantly touching your device.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            HStack(spacing: 8) {
                                Image(systemName: "battery.100")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                
                                Text("Note: Keeping the screen on may use more battery")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(20)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Display")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

// MeasurementSystem enum is defined in UnitConversion.swift

enum TemperatureUnit: String, CaseIterable {
    case celsius = "Celsius"
    case fahrenheit = "Fahrenheit"
}

struct PrivacySettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @StateObject private var authManager = AuthenticationManager.shared
    @AppStorage("skipRecipeDeleteConfirmation") private var skipDeleteConfirmation: Bool = false
    @AppStorage("biometricsEnabled") private var biometricsEnabled: Bool = false
    @State private var showResetSuccess = false
    @State private var showPrivacyPolicy = false
    @State private var showBiometricError = false
    @State private var biometricErrorMessage = ""
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme, cardStyle: cardStyle)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Biometric Authentication (if available and not in guest mode)
                    if authManager.biometricsAvailable && !authManager.isGuestMode {
                        SettingsCard {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Security")
                                    .font(.headline)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                
                                Toggle(isOn: Binding(
                                    get: { biometricsEnabled },
                                    set: { newValue in
                                        if newValue {
                                            // Enable biometrics
                                            enableBiometrics()
                                        } else {
                                            // Disable biometrics
                                            biometricsEnabled = false
                                            HapticManager.shared.light()
                                        }
                                    }
                                )) {
                                    HStack(spacing: 12) {
                                        Image(systemName: authManager.biometricType == "Face ID" ? "faceid" : "touchid")
                                            .foregroundColor(AppTheme.accentColor)
                                            .frame(width: 30)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(authManager.biometricType)")
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            Text("Sign in with \(authManager.biometricType) instead of password")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .tint(AppTheme.accentColor)
                            }
                            .padding(20)
                        }
                    }
                    
                    // Privacy Documents
                    SettingsCard {
                        VStack(spacing: 0) {
                            Button(action: {
                                showPrivacyPolicy = true
                                HapticManager.shared.light()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "hand.raised.fill")
                                        .foregroundColor(.blue)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Privacy Policy")
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        Text("View our privacy and data practices")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                .padding(20)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading, 62)
                            
                            NavigationLink(destination: DataPrivacyView()) {
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.doc.fill")
                                        .foregroundColor(.purple)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Data & Privacy")
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        Text("Control your data and privacy settings")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                .padding(20)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // Confirmation Preferences
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Confirmation Dialogs")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(.orange)
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Delete Confirmations")
                                        .font(.body)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                    
                                    Text("Currently: \(skipDeleteConfirmation ? "Disabled" : "Enabled")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            
                            if skipDeleteConfirmation {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("⚠️ Delete confirmations are disabled")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    
                                    Text("Recipes will be deleted immediately when you swipe without asking for confirmation.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Button(action: {
                                        skipDeleteConfirmation = false
                                        showResetSuccess = true
                                        HapticManager.shared.success()
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            showResetSuccess = false
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.clockwise")
                                            Text("Re-enable Delete Confirmations")
                                        }
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(AppTheme.accentColor)
                                        .cornerRadius(10)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.top, 4)
                            } else {
                                Text("You will be asked to confirm before deleting recipes.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                            
                            if showResetSuccess {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Delete confirmations re-enabled")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(20)
                    }
                    
                    // Data Privacy Info
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Data Privacy")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            VStack(spacing: 16) {
                                PrivacyInfoRow(
                                    icon: "externaldrive.fill",
                                    iconColor: .green,
                                    title: "Local Storage Only",
                                    description: "All your recipes, lists, and preferences are stored locally on your device using Core Data"
                                )
                                
                                PrivacyInfoRow(
                                    icon: "cloud.slash.fill",
                                    iconColor: .blue,
                                    title: "No Cloud Services",
                                    description: "RecipeFinder doesn't use any cloud services or remote servers. Your data never leaves your device"
                                )
                                
                                PrivacyInfoRow(
                                    icon: "chart.bar.xaxis",
                                    iconColor: .purple,
                                    title: "No Analytics or Tracking",
                                    description: "We don't collect usage data, analytics, crash reports, or any telemetry. Your privacy is paramount"
                                )
                                
                                PrivacyInfoRow(
                                    icon: "network.slash",
                                    iconColor: .orange,
                                    title: "No Third-Party SDKs",
                                    description: "No advertising networks, no social media trackers, no third-party libraries with data collection"
                                )
                                
                                PrivacyInfoRow(
                                    icon: "person.badge.shield.checkmark.fill",
                                    iconColor: .indigo,
                                    title: "GDPR & DPA 2018 Compliant",
                                    description: "Built with UK GDPR and Data Protection Act 2018 compliance as a core principle"
                                )
                            }
                            
                            // Export & Import reminder
                            VStack(alignment: .leading, spacing: 8) {
                                Divider()
                                    .padding(.vertical, 4)
                                
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(AppTheme.accentColor)
                                        .font(.system(size: 16))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Backup Your Data")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        
                                        Text("Since data is stored locally, we recommend regularly exporting your data from the Account tab for safekeeping")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                        .padding(20)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .animation(.spring(response: 0.3), value: showResetSuccess)
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
                await MainActor.run {
                    biometricsEnabled = true
                    HapticManager.shared.success()
                }
            } catch {
                await MainActor.run {
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
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
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
    @State private var showingClearAlert = false
    @State private var showingResetAlert = false
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var dataCleared = false
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @EnvironmentObject var kitchenManager: KitchenInventoryManager
    @EnvironmentObject var shoppingListManager: ShoppingListManager
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme, cardStyle: cardStyle)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Data Management")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Button(action: {
                                showingExportSheet = true
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Export Data")
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        Text("Save your recipes, kitchen inventory, and shopping lists")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(16)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                showingImportSheet = true
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.title3)
                                        .foregroundColor(.green)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Import Data")
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        Text("Restore from a previous export")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(16)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(20)
                    }
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Reset Options")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Button(action: {
                                showingResetAlert = true
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.title3)
                                        .foregroundColor(.orange)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Reset to Default")
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        Text("Clear everything and restore sample recipes + default settings")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(16)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                showingClearAlert = true
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "trash")
                                        .font(.title3)
                                        .foregroundColor(.red)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Clear User Content")
                                            .foregroundColor(.red)
                                        Text("Delete recipes, lists, and notes (keeps your settings)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(16)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(20)
                    }
                    
                    if dataCleared {
                        Text("✓ Data cleared successfully")
                            .foregroundColor(.green)
                            .padding()
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .alert("Clear User Content", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will delete all your recipes, kitchen inventory, shopping lists, meal plans, and notes. Your app settings and preferences will be preserved. This action cannot be undone.")
        }
        .alert("Reset to Default", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetToDefault()
            }
        } message: {
            Text("This will delete ALL your data including recipes, settings, preferences, and restore the app to a fresh install state. Sample recipes will be restored. This action cannot be undone!")
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataView()
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportDataView()
        }
    }
    
    private func resetToDefault() {
        let context = PersistenceController.shared.container.viewContext
        
        // 1. Clear Core Data (all recipes)
        let recipeFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "RecipeData")
        let recipeBatchDelete = NSBatchDeleteRequest(fetchRequest: recipeFetch)
        _ = try? context.execute(recipeBatchDelete)
        _ = try? context.save()
        
        // 2. Clear all managers
        kitchenManager.clearAll()
        shoppingListManager.clearAllItems()
        
        // 3. Clear all UserDefaults except critical ones
        let defaults = UserDefaults.standard
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
        
        // 4. Restore default settings
        defaults.set("teal", forKey: "appTheme")
        defaults.set("frosted", forKey: "cardStyle")
        defaults.set("metric", forKey: "measurementSystem")
        defaults.set(300, forKey: "defaultTimerDuration") // 5 minutes
        
        // 5. Restore sample recipes
        PersistenceController.shared.populateDatabase()
        
        dataCleared = true
        HapticManager.shared.success()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            dataCleared = false
        }
    }
    
    private func clearAllData() {
        let context = PersistenceController.shared.container.viewContext
        
        // 1. Clear Core Data (all recipes)
        let recipeFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "RecipeData")
        let recipeBatchDelete = NSBatchDeleteRequest(fetchRequest: recipeFetch)
        _ = try? context.execute(recipeBatchDelete)
        _ = try? context.save()
        
        // 2. Clear all managers
        kitchenManager.clearAll()
        shoppingListManager.clearAllItems()
        
        // 3. Clear specific UserDefaults data (keep settings)
        UserDefaults.standard.removeObject(forKey: "favoriteRecipeIDs")
        UserDefaults.standard.removeObject(forKey: "shoppingListItems")
        UserDefaults.standard.removeObject(forKey: "kitchenInventory")
        UserDefaults.standard.removeObject(forKey: "mealPlans")
        UserDefaults.standard.removeObject(forKey: "recipeNotes")
        
        dataCleared = true
        HapticManager.shared.success()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            dataCleared = false
        }
    }
}

struct ExportDataView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.accentColor)
                
                Text("Export Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Your data will be exported as a JSON file that you can save or share.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Button(action: {
                    exportData()
                }) {
                    Text("Export Now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accentColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ActivityViewController(items: [url])
                }
            }
        }
    }
    
    // Private share sheet for this view only
    private struct ActivityViewController: UIViewControllerRepresentable {
        let items: [Any]
        
        func makeUIViewController(context: Context) -> UIActivityViewController {
            let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
            
            if let popover = controller.popoverPresentationController,
               let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            return controller
        }
        
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }
    
    private func exportData() {
        // Create export data dictionary
        let exportData: [String: Any] = [
            "version": "1.0",
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "kitchen": UserDefaults.standard.dictionary(forKey: "kitchenItems") ?? [:],
            "shoppingList": UserDefaults.standard.array(forKey: "shoppingListItems") ?? [],
            "preferences": [
                "theme": UserDefaults.standard.string(forKey: "selectedTheme") ?? "ocean",
                "appearanceMode": UserDefaults.standard.string(forKey: "appearanceMode") ?? "system"
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("RecipeFinder_Export_\(Date().timeIntervalSince1970).json")
            try jsonData.write(to: tempURL)
            exportURL = tempURL
            showingShareSheet = true
        } catch {
            print("Export failed: \(error)")
        }
    }
}

struct ImportDataView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingFilePicker = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.down.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Import Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Select a previously exported JSON file to restore your data.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Button(action: {
                    showingFilePicker = true
                }) {
                    Text("Choose File")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Import Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// ShareSheet is defined in RecipeDetailView.swift

struct HelpView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @State private var showOnboarding = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // App Tour Section
                    SettingsCard {
                        Button(action: {
                            showOnboarding = true
                            HapticManager.shared.light()
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.purple.opacity(0.15))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "play.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.purple)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Take the App Tour")
                                        .font(.headline)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                    
                                    Text("Learn how to use RecipeFinder")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .padding(20)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Getting Started")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
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
                        .padding(20)
                    }
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Tips & Tricks")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            HelpItem(
                                icon: "square.and.arrow.up",
                                title: "Sharing Recipes",
                                description: "Tap the share button on any recipe to send as text or beautiful PDF."
                            )
                            
                            HelpItem(
                                icon: "paintpalette",
                                title: "Customize Appearance",
                                description: "Choose between System, Frost Light, or Fire Dark modes in Settings > Appearance."
                            )
                            
                            HelpItem(
                                icon: "arrow.counterclockwise",
                                title: "Backup Your Data",
                                description: "Export your data regularly from Account > Download Your Data for safekeeping."
                            )
                            
                            HelpItem(
                                icon: "star",
                                title: "Default Timer",
                                description: "Set your preferred timer duration in Settings > Cook Timer for quick access."
                            )
                        }
                        .padding(20)
                    }
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Support")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Button(action: {
                                if let url = URL(string: "mailto:support@recipefinder.com") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "envelope.fill")
                                        .font(.title3)
                                        .foregroundColor(AppTheme.accentColor)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Contact Support")
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        Text("support@recipefinder.com")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(16)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                if let url = URL(string: "https://recipefinder.com/faq") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(AppTheme.accentColor)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("FAQs")
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        Text("Common questions and answers")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding(16)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(20)
                    }
                }
                .padding(20)
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
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppTheme.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct AboutView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // App Icon & Name
                    VStack(spacing: 16) {
                        Image(systemName: "book.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(AppTheme.accentColor(for: appTheme))
                        
                        Text("RecipeFinder")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Your Personal Cooking Companion")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Version Info
                    SettingsCard {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Version")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("1.0.0 (Build 1)")
                                    .fontWeight(.medium)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Release Date")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("October 2025")
                                    .fontWeight(.medium)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                        }
                        .padding(20)
                    }
                    
                    // Description
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About RecipeFinder")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text("""
                                RecipeFinder is your ultimate kitchen companion, designed to make cooking easier, \
                                more organized, and enjoyable. Discover new recipes, manage your kitchen inventory, \
                                plan meals, and never forget an ingredient with our smart shopping lists.
                                """)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                FeatureRow(icon: "shield.fill", text: "Privacy-first: All data stored locally", color: .blue)
                                FeatureRow(icon: "doc.text.fill", text: "Ingredient database", color: .green)
                                FeatureRow(icon: "heart.fill", text: "Made with love for home cooks", color: .red)
                            }
                        }
                        .padding(20)
                    }
                    
                    // Legal
                    VStack(spacing: 8) {
                        Text("© 2025 RecipeFinder")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("All rights reserved")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .primary)
        }
    }
}

// MARK: - Party Time View
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
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        // Header Info
                        VStack(spacing: 12) {
                            Image(systemName: "party.popper.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppTheme.accentColor(for: appTheme))
                                .symbolEffect(.bounce, value: isVibrating)
                            
                            Text("Party Time")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Press and hold the button below for continuous vibration")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 40)
                        
                        // Vibration Button
                        VStack(spacing: 16) {
                            ZStack {
                                // Animated rings when vibrating
                                if isVibrating {
                                    ForEach(0..<3) { index in
                                        Circle()
                                            .stroke(AppTheme.accentColor(for: appTheme).opacity(0.3), lineWidth: 2)
                                            .frame(width: 200, height: 200)
                                            .scaleEffect(isVibrating ? 1.3 : 1.0)
                                            .opacity(isVibrating ? 0 : 0.8)
                                            .animation(
                                                .easeOut(duration: 1.5)
                                                .repeatForever(autoreverses: false)
                                                .delay(Double(index) * 0.3),
                                                value: isVibrating
                                            )
                                    }
                                }
                                
                                // Main button
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
                                    .frame(width: 200, height: 200)
                                    .shadow(color: AppTheme.accentColor(for: appTheme).opacity(0.5), radius: isVibrating ? 30 : 15)
                                    .scaleEffect(isVibrating ? 1.05 : 1.0)
                                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isVibrating)
                                
                                Image(systemName: isVibrating ? "iphone.radiowaves.left.and.right" : "hand.tap.fill")
                                    .font(.system(size: 70))
                                    .foregroundColor(.white)
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
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.vertical, 40)
                        
                        // Info Card
                        SettingsCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("How it works")
                                        .font(.headline)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    BulletPoint(text: "Press and hold the button")
                                    BulletPoint(text: "Your device will vibrate continuously")
                                    BulletPoint(text: "Release to stop the vibration")
                                    BulletPoint(text: "Perfect for getting attention or just having fun!")
                                }
                            }
                            .padding(20)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
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
        
        // Use AudioServicesPlaySystemSound for continuous vibration
        // Vibrate immediately
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        // Continue vibrating every 0.3 seconds for truly continuous feel (shorter interval = more continuous)
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

struct BulletPoint: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .primary)
            Text(text)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .primary)
        }
    }
}

#Preview {
    SettingsTabView()
        .environmentObject(KitchenInventoryManager())
        .environmentObject(ShoppingListManager())
        .environment(\.appTheme, AppTheme.ThemeType.teal)
}

