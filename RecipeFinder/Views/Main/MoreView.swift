import SwiftUI

struct MoreView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Themed background gradient
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header with title only (no icon)
                    HStack {
                        Spacer()
                        
                        Text("More")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Navigation cards
                    ScrollView {
                        VStack(spacing: 16) {
                            CardView {
                                VStack(spacing: 0) {
                                    NavigationLink(destination: AccountView()) {
                                        moreRow(
                                            icon: "person.fill",
                                            title: "Account",
                                            subtitle: "Profile & preferences",
                                            color: .blue
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Divider()
                                        .padding(.leading, 54)
                                    
                                    NavigationLink(destination: SettingsView()) {
                                        moreRow(
                                            icon: "gearshape.fill",
                                            title: "Settings",
                                            subtitle: "App configuration",
                                            color: .gray
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func moreRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}

#Preview {
    MoreView()
        .environment(\.appTheme, .teal)
}

