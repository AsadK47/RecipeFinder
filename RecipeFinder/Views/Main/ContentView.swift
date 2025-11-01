import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var recipes: [RecipeModel] = []
    @State private var selectedTab: Int = 0
    @StateObject private var shoppingListManager = ShoppingListManager()
    @StateObject private var kitchenManager = KitchenInventoryManager()
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
                    .environmentObject(kitchenManager)
                    .tabItem {
                        Label("Kitchen", systemImage: "refrigerator.fill")
                    }
                    .tag(2)
                
                CookTimerView()
                    .tabItem {
                        Label("Timer", systemImage: "timer")
                    }
                    .tag(3)
                
                MoreView(recipes: $recipes)
                    .environmentObject(kitchenManager)
                    .environmentObject(shoppingListManager)
                    .tabItem {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                    .tag(4)
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
            // Solid mode: Use opaque backgrounds
            appearance.configureWithOpaqueBackground()
            let tabBarBgColor: UIColor = {
                if colorScheme == .dark {
                    // Dark mode: Rich dark background
                    return UIColor(white: 0.12, alpha: 0.98)
                } else {
                    // Light mode: Clean light background
                    return UIColor(white: 0.98, alpha: 0.98)
                }
            }()
            appearance.backgroundColor = tabBarBgColor
        } else {
            // Frosted Glass mode: Enhanced blur with theme-tinted background
            appearance.configureWithDefaultBackground()
            
            // Create a rich, readable background with theme color
            let tintedBackground: UIColor = {
                if colorScheme == .dark {
                    // Dark mode: Deep tinted background for better readability
                    // Mix theme color with dark base for subtle branded effect
                    return themeColor
                        .withAlphaComponent(0.25)
                        .blended(with: UIColor(white: 0.1, alpha: 0.85))
                } else {
                    // Light mode: Light tinted background
                    // Stronger tint in light mode for contrast with colorful content
                    return themeColor
                        .withAlphaComponent(0.20)
                        .blended(with: UIColor(white: 0.95, alpha: 0.90))
                }
            }()
            appearance.backgroundColor = tintedBackground
            
            // Enhanced blur effect for premium frosted glass look
            let blurStyle: UIBlurEffect.Style = colorScheme == .dark 
                ? .systemUltraThinMaterialDark 
                : .systemUltraThinMaterialLight
            
            appearance.backgroundEffect = UIBlurEffect(style: blurStyle)
        }
        
        // Icon colors - optimized for readability over colored backgrounds
        let accentColor = UIColor(AppTheme.accentColor(for: themeBinding))
        let selectedIconColor = colorScheme == .dark 
            ? accentColor.lighter(by: 0.1) // Slightly brighter in dark mode
            : accentColor
        
        appearance.stackedLayoutAppearance.selected.iconColor = selectedIconColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedIconColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        
        // Unselected icons - high contrast for readability
        let unselectedColor: UIColor = colorScheme == .dark 
            ? UIColor.white.withAlphaComponent(0.7)  // Increased from 0.6
            : UIColor.black.withAlphaComponent(0.6)  // Increased from 0.5
        
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)  // Medium instead of regular
        ]
        
        // Apply to all tab bar states
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
