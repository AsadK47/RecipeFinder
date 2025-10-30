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

                ShoppingListView(manager: shoppingListManager)
                    .tabItem {
                        Label("Shopping", systemImage: "cart.fill")
                    }
                    .tag(1)

                KitchenView(recipes: $recipes, shoppingListManager: shoppingListManager)
                    .tabItem {
                        Label("Kitchen", systemImage: "refrigerator.fill")
                    }
                    .tag(2)
                
                MealPlanningView(recipes: $recipes)
                    .tabItem {
                        Label("Meals", systemImage: "calendar")
                    }
                    .tag(3)
                
                AccountView()
                    .tabItem {
                        Label("Account", systemImage: "person.fill")
                    }
                    .tag(4)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(5)
            }
            .environment(\.appTheme, themeBinding)
            .tint(AppTheme.accentColor(for: themeBinding))
            .onAppear {
                configureTabBarAppearance()
            }
            .onChange(of: selectedTheme) { _, _ in
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
        
        // Get the theme's accent color
        let themeColor = UIColor(AppTheme.accentColor(for: themeBinding))
        
        if cardStyle == .solid {
            // Solid mode: Use opaque backgrounds with theme tint
            appearance.configureWithOpaqueBackground()
            let tabBarBgColor: UIColor = {
                if colorScheme == .dark {
                    // Dark mode: Dark background with subtle theme tint
                    return UIColor(white: 0.15, alpha: 1.0).withAlphaComponent(0.95)
                } else {
                    // Light mode: Light background with very subtle theme tint
                    return UIColor(white: 0.98, alpha: 0.98)
                }
            }()
            appearance.backgroundColor = tabBarBgColor
        } else {
            // Frosted Glass mode: Colored blur for readability
            appearance.configureWithDefaultBackground()
            
            // Add theme-colored tint to the blur for better readability
            let tintedBackground: UIColor = {
                if colorScheme == .dark {
                    // Dark mode: Dark blur with theme tint
                    return themeColor.withAlphaComponent(0.15)
                } else {
                    // Light mode: Light blur with stronger theme tint for readability
                    return themeColor.withAlphaComponent(0.12)
                }
            }()
            appearance.backgroundColor = tintedBackground
            
            // Add blur effect for frosted glass look
            let blurStyle: UIBlurEffect.Style = colorScheme == .dark 
                ? .systemMaterialDark 
                : .systemMaterialLight
            
            appearance.backgroundEffect = UIBlurEffect(style: blurStyle)
        }
        
        // Icon colors - stronger contrast for readability
        let accentColor = UIColor(AppTheme.accentColor(for: themeBinding))
        appearance.stackedLayoutAppearance.selected.iconColor = accentColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: accentColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        
        // Unselected icons - better contrast
        let unselectedColor: UIColor = colorScheme == .dark 
            ? UIColor.white.withAlphaComponent(0.6)
            : UIColor.black.withAlphaComponent(0.5)
        
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .regular)
        ]
        
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
