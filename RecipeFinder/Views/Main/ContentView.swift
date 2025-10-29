import ConfettiSwiftUI
import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var recipes: [RecipeModel] = []
    @State private var selectedTab: Int = 0
    @StateObject private var shoppingListManager = ShoppingListManager()
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme
    
    // Performance: Cache the theme for the session
    private var themeBinding: AppTheme.ThemeType { selectedTheme }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: themeBinding, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                RecipeSearchView(recipes: $recipes, shoppingListManager: shoppingListManager)
                    .tabItem {
                        Label("Recipes", systemImage: "book.fill")
                    }
                    .tag(0)

                KitchenView(recipes: $recipes, shoppingListManager: shoppingListManager)
                    .tabItem {
                        Label("Kitchen", systemImage: "refrigerator.fill")
                    }
                    .tag(1)

                ShoppingListView(manager: shoppingListManager)
                    .tabItem {
                        Label("Shopping", systemImage: "cart.fill")
                    }
                    .tag(2)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            .environment(\.appTheme, themeBinding)
            .tint(AppTheme.accentColor(for: themeBinding))
            .onAppear {
                configureTabBarAppearance()
            }
            .onChange(of: cardStyle) { _, _ in
                configureTabBarAppearance()
            }
            .onChange(of: colorScheme) { _, _ in
                configureTabBarAppearance()
            }
            .onChange(of: selectedTab) { _, _ in
                HapticManager.shared.selection()
            }
        }
        .onAppear {
            // Load recipes only once on appear
            if recipes.isEmpty {
                loadRecipes()
            }
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        
        if cardStyle == .solid {
            // Solid mode: Use opaque backgrounds
            appearance.configureWithOpaqueBackground()
            let tabBarBgColor: UIColor = {
                if colorScheme == .dark {
                    return UIColor(white: 0.15, alpha: 1.0) // Match cardBackgroundDark
                } else {
                    return UIColor(white: 1.0, alpha: 0.95) // Match cardBackground
                }
            }()
            appearance.backgroundColor = tabBarBgColor
        } else {
            // Frosted mode: Use blur with subtle base layer
            appearance.configureWithTransparentBackground()
            
            // Add subtle base color for contrast
            let baseColor: UIColor = {
                if colorScheme == .dark {
                    return UIColor(white: 0.0, alpha: 0.15) // Subtle dark base
                } else {
                    return UIColor(white: 1.0, alpha: 0.3) // Subtle light base
                }
            }()
            appearance.backgroundColor = baseColor
            
            // Add blur effect
            appearance.backgroundEffect = UIBlurEffect(style: colorScheme == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight)
        }
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private func loadRecipes() {
        recipes = PersistenceController.shared.fetchRecipes()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
