import SwiftUI

struct MoreView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Binding var recipes: [RecipeModel]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        Text("More")
                            .font(.system(size: 34, weight: .bold))
                            .adaptiveForegroundColor()
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            MoreCard {
                                NavigationLink(destination: SettingsTabView()
                                ) {
                                    MoreRow(
                                        icon: "gearshape.circle.fill",
                                        iconColor: AppTheme.accentColor(for: selectedTheme),
                                        title: "Settings",
                                        subtitle: "Customize your experience"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 20)
                            
                            MoreCard {
                                NavigationLink(destination: NutritionalTipsView()) {
                                    MoreRow(
                                        icon: "heart.text.square.fill",
                                        iconColor: .pink,
                                        title: "Nutritional Science",
                                        subtitle: "Evidence-based health guidance"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 20)
                            
                            MoreCard {
                                NavigationLink(destination: CookingTipsView()) {
                                    MoreRow(
                                        icon: "lightbulb.fill",
                                        iconColor: .yellow,
                                        title: "Cooking Tips",
                                        subtitle: "Expert advice & kitchen hacks"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 20)
                            
                            MoreCard {
                                NavigationLink(destination: CookTimerView()) {
                                    MoreRow(
                                        icon: "calendar.circle.fill",
                                        iconColor: .green,
                                        title: "Cook Timer",
                                        subtitle: "Ready, set, cook!"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 20)
                            
                            MoreCard {
                                NavigationLink(destination: NotesListView()) {
                                    MoreRow(
                                        icon: "note.text.badge.plus",
                                        iconColor: .orange,
                                        title: "Notes",
                                        subtitle: "Capture your cooking ideas"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
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

struct MoreRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .adaptiveForegroundColor()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    MoreView(recipes: .constant([]))
        .environmentObject(KitchenInventoryManager.shared)
        .environmentObject(ShoppingListManager.shared)
        .environment(\.appTheme, .teal)
}
