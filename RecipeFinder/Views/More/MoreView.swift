import SwiftUI

struct MoreView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Binding var recipes: [RecipeModel]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        Text("More")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 24)
                        
                        VStack(spacing: 24) {
                            // Features Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Features")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 20)
                                
                                MoreCard {
                                    NavigationLink(destination: MealPlanningView(recipes: $recipes)) {
                                        MoreRow(
                                            icon: "calendar.circle.fill",
                                            iconColor: .green,
                                            title: "Meal Planner",
                                            subtitle: "Plan your weekly meals"
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Settings Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Settings")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 20)
                                
                                MoreCard {
                                    NavigationLink(destination: SettingsTabView()) {
                                        MoreRow(
                                            icon: "gearshape.circle.fill",
                                            iconColor: AppTheme.accentColor(for: appTheme),
                                            title: "Settings",
                                            subtitle: "Customize your experience"
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - More View Components

struct MoreCard<Content: View>: View {
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

struct MoreRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(iconColor)
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
        }
        .padding(20)
    }
}

#Preview {
    MoreView(recipes: .constant([]))
        .environment(\.appTheme, .teal)
}
