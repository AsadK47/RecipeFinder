import SwiftUI

struct SettingsView: View {
    @State private var confettiTrigger: Int = 0
    @State private var showResetAlert: Bool = false
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .purple
    @AppStorage("measurementSystem") private var measurementSystem: MeasurementSystem = .metric
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
                            CardView {
                                VStack(alignment: .leading, spacing: 16) {
                                    settingRow(icon: "bell.fill", title: "Notifications", color: .orange)
                                    
                                    Divider()
                                    
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
                                        .onChange(of: selectedTheme) { oldValue, newValue in
                                            HapticManager.shared.selection()
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    // Measurement System Picker
                                    HStack(spacing: 16) {
                                        Image(systemName: measurementSystem.icon)
                                            .foregroundColor(.blue)
                                            .frame(width: 30)
                                        
                                        Text("Units")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        Menu {
                                            Picker("Units", selection: $measurementSystem) {
                                                ForEach(MeasurementSystem.allCases, id: \.self) { system in
                                                    Text(system.rawValue)
                                                        .tag(system)
                                                }
                                            }
                                        } label: {
                                            HStack(spacing: 6) {
                                                Text(measurementSystem.rawValue)
                                                    .font(.subheadline)
                                                    .foregroundColor(.blue)
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
                                        .onChange(of: measurementSystem) { oldValue, newValue in
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
                                        .onChange(of: appearanceMode) { oldValue, newValue in
                                            HapticManager.shared.selection()
                                        }
                                    }
                                }
                                .padding()
                            }
                            
                            CardView {
                                VStack(alignment: .leading, spacing: 16) {
                                    settingRow(icon: "person.fill", title: "Account", color: .green)
                                    Divider()
                                    settingRow(icon: "lock.fill", title: "Privacy", color: .red)
                                }
                                .padding()
                            }
                            
                            // Debug Section
                            #if DEBUG
                            CardView {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Developer Options")
                                        .font(.headline)
                                        .foregroundColor(AppTheme.secondaryText)
                                    
                                    Button(action: { showResetAlert = true }) {
                                        HStack(spacing: 16) {
                                            Image(systemName: "arrow.clockwise.circle.fill")
                                                .foregroundColor(.orange)
                                                .frame(width: 30)
                                            
                                            Text("Reset Database")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.orange)
                                                .font(.caption)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding()
                            }
                            #endif
                            
                            Button(action: {
                                HapticManager.shared.celebrate()
                                confettiTrigger += 1
                            }) {
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
            }
        } message: {
            Text("This will delete all recipes and reload the sample data. This action cannot be undone.")
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
