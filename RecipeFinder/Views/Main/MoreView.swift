import SwiftUI

struct MoreView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Binding var recipes: [RecipeModel]
    @EnvironmentObject var kitchenManager: KitchenInventoryManager
    @EnvironmentObject var shoppingListManager: ShoppingListManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        GeometryReader { geometry in
                            HStack(spacing: 0) {
                                Spacer()
                                
                                Text("More")
                                    .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                
                                Spacer()
                            }
                        }
                        .frame(height: 44)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Settings Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Settings")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 20)
                                
                                MoreCard {
                                    NavigationLink(destination: SettingsTabView()
                                        .environmentObject(kitchenManager)
                                        .environmentObject(shoppingListManager)
                                    ) {
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
                            
                            // Features Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Features")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 20)
                                
                                VStack(spacing: 12) {
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
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 16)
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
        .environmentObject(KitchenInventoryManager())
        .environmentObject(ShoppingListManager())
        .environment(\.appTheme, .teal)
}
