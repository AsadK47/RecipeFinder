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
                    VStack(spacing: AppTheme.spacing12) {
                        Text("More")
                            .font(.system(size: AppTheme.fontSize34, weight: .bold))
                            .adaptiveForegroundColor()
                            .frame(maxWidth: .infinity)
                            .frame(height: AppTheme.height44)
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.top, AppTheme.spacing16)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            MoreCard {
                                VStack(spacing: 0) {
                                    NavigationLink(destination: SettingsTabView()) {
                                        MoreRow(
                                            icon: "gearshape.circle.fill",
                                            iconColor: AppTheme.accentColor(for: selectedTheme),
                                            title: "Settings",
                                            subtitle: "Customize your experience"
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    Divider().padding(.leading, AppTheme.spacing60)

                                    NavigationLink(destination: NutritionalTipsView()) {
                                        MoreRow(
                                            icon: "heart.text.square.fill",
                                            iconColor: .pink,
                                            title: "Nutritional Science",
                                            subtitle: "Evidence-based health guidance"
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    Divider().padding(.leading, AppTheme.spacing60)

                                    NavigationLink(destination: CookingTipsView()) {
                                        MoreRow(
                                            icon: "lightbulb.fill",
                                            iconColor: .yellow,
                                            title: "Cooking Tips",
                                            subtitle: "Expert advice & kitchen hacks"
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    Divider().padding(.leading, AppTheme.spacing60)

                                    NavigationLink(destination: CookTimerView()) {
                                        MoreRow(
                                            icon: "calendar.circle.fill",
                                            iconColor: .green,
                                            title: "Cook Timer",
                                            subtitle: "Ready, set, cook!"
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    Divider().padding(.leading, AppTheme.spacing60)

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
                            }
                            .padding(.horizontal, AppTheme.spacing20)
                        }
                        .padding(.top, AppTheme.spacing16)
                        .padding(.bottom, AppTheme.spacing40)
                    }
                }
            }
        }
    }
}

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
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                        .fill(AppTheme.adaptiveCard(for: colorScheme))
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
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
        HStack(spacing: AppTheme.spacing16) {
            ZStack {
                Circle()
                    .fill(iconColor)
                    .frame(width: 40, height: AppTheme.height40)
                
                Image(systemName: icon)
                    .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                    .adaptiveForegroundColor()
            }
            
            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(systemName: "chevron.right")
                .font(.system(size: AppTheme.fontSize13, weight: .semibold))
                .foregroundColor(AppTheme.adaptiveSecondaryIndicator(for: colorScheme))
        }
        .padding(.horizontal, AppTheme.spacing16)
        .padding(.vertical, AppTheme.spacing12)
        .contentShape(Rectangle())
    }
}

#Preview {
    MoreView(recipes: .constant([]))
        .environmentObject(KitchenInventoryManager.shared)
        .environmentObject(ShoppingListManager.shared)
        .environment(\.appTheme, .teal)
}
