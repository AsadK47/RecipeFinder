import SwiftUI

// MARK: - Card Style Enum
enum CardStyle: String, CaseIterable {
    case frosted = "Frosted Glass"
    case solid = "Solid"
}

/// Beautiful Settings View with app's gradient background aesthetic  
struct SettingsTabView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @State private var notificationsEnabled: Bool = false
    @State private var cookModeEnabled: Bool = true
    @StateObject private var accountManager = AccountManager.shared
    
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
        NavigationStack {
            ZStack {
                // Beautiful gradient background like rest of app
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Spacer()
                        Text("Settings")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Account Section
                            SettingsCard {
                                NavigationLink(destination: AccountView()) {
                                    HStack(spacing: 16) {
                                        Circle()
                                            .fill(AppTheme.accentColor(for: appTheme))
                                            .frame(width: 56, height: 56)
                                            .overlay {
                                                Text(accountManager.initials)
                                                    .font(.system(size: 22, weight: .semibold))
                                                    .foregroundStyle(.white)
                                            }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(accountManager.fullName)
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
                            
                            // Planning
                            SettingsSectionHeader(title: "Planning")
                            
                            SettingsCard {
                                NavigationLink(destination: MealPlanningView(recipes: .constant(PersistenceController.shared.fetchRecipes()))) {
                                    SettingsRow(icon: "calendar", iconColor: .green, title: "Meal Planning")
                                        .padding(20)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Personalization
                            SettingsSectionHeader(title: "Personalization")
                            
                            SettingsCard {
                                VStack(spacing: 0) {
                                    NavigationLink(destination: AppearanceSettingsView()) {
                                        SettingsRow(icon: "paintpalette.fill", iconColor: .pink, title: "Appearance")
                                            .padding(20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Divider()
                                        .padding(.leading, 60)
                                    
                                    NavigationLink(destination: ThemeSettingsView()) {
                                        SettingsRow(icon: "sparkles", iconColor: AppTheme.accentColor(for: appTheme), title: "Theme")
                                            .padding(20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
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
                                    
                                    NavigationLink(destination: DataManagementSettingsView()) {
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
                            .padding(.top, 8)
                            .padding(.bottom, 40)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Settings Components

struct SettingsCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
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

// MARK: - Settings Detail Views

struct AppearanceSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: SettingsTabView.AppearanceMode = .system
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Appearance Mode")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            ForEach(SettingsTabView.AppearanceMode.allCases, id: \.self) { mode in
                                Button(action: {
                                    appearanceMode = mode
                                    HapticManager.shared.selection()
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: mode.icon)
                                            .font(.title3)
                                            .foregroundColor(AppTheme.accentColor)
                                            .frame(width: 30)
                                        
                                        Text(mode.rawValue)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        
                                        Spacer()
                                        
                                        if appearanceMode == mode {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(AppTheme.accentColor)
                                        }
                                    }
                                    .padding(16)
                                    .background(appearanceMode == mode ? Color.gray.opacity(0.2) : Color.clear)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(20)
                    }
                    
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Card Style")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            ForEach(CardStyle.allCases, id: \.self) { style in
                                Button(action: {
                                    cardStyle = style
                                    HapticManager.shared.selection()
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: style == .frosted ? "sparkles" : "square.fill")
                                            .font(.title3)
                                            .foregroundColor(AppTheme.accentColor)
                                            .frame(width: 30)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(style.rawValue)
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            Text(style == .frosted ? "Translucent glass effect" : "Solid background")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if cardStyle == style {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(AppTheme.accentColor)
                                        }
                                    }
                                    .padding(16)
                                    .background(cardStyle == style ? Color.gray.opacity(0.2) : Color.clear)
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
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ThemeSettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
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
    @Environment(\.appTheme) var appTheme
    
    var reminderTime: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: reminderTimeString) ?? Date()
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    if notificationPermission != .authorized {
                        SettingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Notifications Disabled")
                                        .font(.headline)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                                
                                Text("Enable notifications in Settings to receive reminders and alerts.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Text("Open Settings")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(AppTheme.accentColor)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(20)
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
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    SettingsCard {
                        Text("Timer settings coming soon")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding()
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Timers")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct UnitsSettingsView: View {
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric
    @AppStorage("temperatureUnit") private var temperatureUnit: TemperatureUnit = .celsius
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
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
    }
}

// MeasurementSystem enum is defined in UnitConversion.swift

enum TemperatureUnit: String, CaseIterable {
    case celsius = "Celsius"
    case fahrenheit = "Fahrenheit"
}

struct PrivacySettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    SettingsCard {
                        Text("Privacy settings coming soon")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding()
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataManagementSettingsView: View {
    @State private var showingClearAlert = false
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var dataCleared = false
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @EnvironmentObject var kitchenManager: KitchenInventoryManager
    @EnvironmentObject var shoppingListManager: ShoppingListManager
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
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
                            Text("Clear Data")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Button(action: {
                                showingClearAlert = true
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "trash")
                                        .font(.title3)
                                        .foregroundColor(.red)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Clear All Data")
                                            .foregroundColor(.red)
                                        Text("This will delete all your data permanently")
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
        .alert("Clear All Data", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will permanently delete all your saved recipes, kitchen inventory, shopping lists, and preferences. This action cannot be undone.")
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataView()
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportDataView()
        }
    }
    
    private func clearAllData() {
        // Clear kitchen inventory
        kitchenManager.clearAll()
        
        // Clear shopping list
        shoppingListManager.clearAllItems()
        
        // Clear UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        
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
                    ShareSheet(items: [url])
                }
            }
        }
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
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Getting Started")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            HelpItem(
                                icon: "magnifyingglass",
                                title: "Finding Recipes",
                                description: "Search by name, ingredients, or browse categories to discover delicious recipes"
                            )
                            
                            HelpItem(
                                icon: "refrigerator",
                                title: "Managing Your Kitchen",
                                description: "Add ingredients you have on hand to get personalized recipe suggestions"
                            )
                            
                            HelpItem(
                                icon: "cart",
                                title: "Shopping Lists",
                                description: "Create shopping lists from recipes or add items manually"
                            )
                            
                            HelpItem(
                                icon: "timer",
                                title: "Cooking Timers",
                                description: "Set multiple timers to keep track of different cooking steps"
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
                VStack(spacing: 16) {
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("RecipeFinder")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text("Version 1.0.0 (Build 1)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("© 2025 RecipeFinder")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsTabView()
        .environment(\.appTheme, AppTheme.ThemeType.teal)
}
