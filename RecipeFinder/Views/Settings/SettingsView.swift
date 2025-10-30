import SwiftUI
import UserNotifications

// Card Style Enum
enum CardStyle: String, CaseIterable {
    case frosted = "Frosted Glass"
    case solid = "Solid"
}

struct SettingsView: View {
    @State private var confettiTrigger: Int = 0
    @State private var showResetAlert: Bool = false
    @State private var notificationsEnabled: Bool = false
    @State private var cookModeEnabled: Bool = true
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme
    
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
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    HStack {
                        // Left spacer for alignment
                        Color.clear
                            .frame(width: 48, height: 48)
                        
                        Spacer()
                        
                        Text("Settings")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Right spacer for alignment
                        Color.clear
                            .frame(width: 48, height: 48)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // Appearance Section
                            CardView {
                                VStack(alignment: .leading, spacing: 16) {
                                    // Theme Picker
                                    HStack(spacing: 16) {
                                        Image(systemName: "paintpalette.fill")
                                            .foregroundColor(.pink)
                                            .frame(width: 30)
                                        
                                        Text("Theme")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        Menu {
                                            Picker("Theme", selection: $selectedTheme) {
                                                ForEach(AppTheme.ThemeType.allCases) { theme in
                                                    Text(theme.rawValue)
                                                        .tag(theme)
                                                }
                                            }
                                        } label: {
                                            HStack(spacing: 6) {
                                                Text(selectedTheme.rawValue)
                                                    .font(.subheadline)
                                                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                                Image(systemName: "chevron.up.chevron.down")
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(.systemGray6))
                                            )
                                        }
                                        .onChange(of: selectedTheme) { _, _ in
                                            HapticManager.shared.selection()
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    // Dark Mode Toggle with Picker
                                    HStack(spacing: 16) {
                                        Image(systemName: appearanceMode.icon)
                                            .foregroundColor(.purple)
                                            .frame(width: 30)
                                        
                                        Text("Appearance")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        Menu {
                                            Picker("Appearance", selection: $appearanceMode) {
                                                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                                    Label(mode.rawValue, systemImage: mode.icon)
                                                        .tag(mode)
                                                }
                                            }
                                        } label: {
                                            HStack(spacing: 6) {
                                                Text(appearanceMode.rawValue)
                                                    .font(.subheadline)
                                                    .foregroundColor(AppTheme.accentColor)
                                                Image(systemName: "chevron.up.chevron.down")
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(.systemGray6))
                                            )
                                        }
                                        .onChange(of: appearanceMode) { _, _ in
                                            HapticManager.shared.selection()
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    // Card Style Toggle
                                    HStack(spacing: 16) {
                                        Image(systemName: "rectangle.inset.filled")
                                            .foregroundColor(.cyan)
                                            .frame(width: 30)
                                        
                                        Text("Card Style")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        Menu {
                                            Picker("Card Style", selection: $cardStyle) {
                                                Label("Frosted Glass", systemImage: "sparkles")
                                                    .tag(CardStyle.frosted)
                                                Label("Solid", systemImage: "square.fill")
                                                    .tag(CardStyle.solid)
                                            }
                                        } label: {
                                            HStack(spacing: 6) {
                                                Text(cardStyle.rawValue)
                                                    .font(.subheadline)
                                                    .foregroundColor(AppTheme.accentColor)
                                                Image(systemName: "chevron.up.chevron.down")
                                                    .font(.caption2)
                                                    .foregroundColor(.gray)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color(.systemGray6))
                                            )
                                        }
                                        .onChange(of: cardStyle) { _, _ in
                                            HapticManager.shared.selection()
                                        }
                                    }
                                }
                                .padding()
                            }
                            
                            // Cooking Features Section
                            CardView {
                                VStack(alignment: .leading, spacing: 16) {
                                    // Notifications Toggle
                                    HStack(spacing: 16) {
                                        Image(systemName: "bell.fill")
                                            .foregroundColor(.orange)
                                            .frame(width: 30)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Notifications")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text("Enable timer alerts")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: $notificationsEnabled)
                                            .labelsHidden()
                                            .onChange(of: notificationsEnabled) { _, newValue in
                                                HapticManager.shared.light()
                                                if newValue {
                                                    requestNotificationPermission()
                                                }
                                            }
                                    }
                                    
                                    Divider()
                                    
                                    // Cook Mode Toggle
                                    HStack(spacing: 16) {
                                        Image(systemName: "flame.fill")
                                            .foregroundColor(.red)
                                            .frame(width: 30)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Cook Mode")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text("Keep screen on while cooking")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: $cookModeEnabled)
                                            .labelsHidden()
                                            .onChange(of: cookModeEnabled) { _, _ in
                                                HapticManager.shared.light()
                                                UIApplication.shared.isIdleTimerDisabled = cookModeEnabled
                                            }
                                    }
                                }
                                .padding()
                            }
                            
                            // Account & Privacy Section
                            CardView {
                                VStack(alignment: .leading, spacing: 16) {
                                    NavigationLink(destination: AccountView()) {
                                        HStack(spacing: 16) {
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.green)
                                                .frame(width: 30)
                                            
                                            Text("Account")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                                .font(.caption)
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    settingRow(icon: "lock.fill", title: "Privacy", color: .red)
                                }
                                .padding()
                            }
                            
                            // About Section
                            CardView {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "app.badge")
                                            .foregroundColor(.blue)
                                            .frame(width: 30)
                                        
                                        Text("Version")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        Text("1.0.0")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Divider()
                                    
                                    HStack(spacing: 16) {
                                        Image(systemName: "hammer")
                                            .foregroundColor(.purple)
                                            .frame(width: 30)
                                        
                                        Text("Build")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        Text("2025.10.30")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                            }
                            
                            // Data Management Section
                            CardView {
                                VStack(alignment: .leading, spacing: 16) {
                                    Button(action: { showResetAlert = true }, label: {
                                        HStack(spacing: 16) {
                                            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                                .foregroundColor(.orange)
                                                .frame(width: 30)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Reset to Sample Recipes")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.primary)
                                                Text("Restore default recipe collection")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.orange)
                                                .font(.caption)
                                        }
                                    })
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding()
                            }
                            
                            Button(
                                action: {
                                    HapticManager.shared.celebrate()
                                    confettiTrigger += 1
                                },
                                label: {
                                    HStack {
                                        Image(systemName: "party.popper.fill")
                                        Text("Celebrate!")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppTheme.accentColor)
                                    .cornerRadius(16)
                                }
                            )
                            .confettiCannon(
                                trigger: $confettiTrigger,
                                num: 50,
                                radius: 500.0
                            )
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(appearanceMode == .system ? nil : (appearanceMode == .light ? .light : .dark))
        .alert("Reset Database", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                PersistenceController.shared.resetDatabase()
                HapticManager.shared.success()
            }
        } message: {
            Text("This will delete all your recipes and reload the original sample recipes. This action cannot be undone.")
        }
        .onAppear {
            // Set cook mode on appear
            UIApplication.shared.isIdleTimerDisabled = cookModeEnabled
            // Check notification permission status
            checkNotificationStatus()
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if !granted {
                    notificationsEnabled = false
                }
            }
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func settingRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
    }
}
