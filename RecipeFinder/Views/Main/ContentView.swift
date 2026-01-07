import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var recipes: [RecipeModel] = []
    @State private var selectedTab: Int = 0
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var authManager = AuthenticationManager.shared
    
    private var themeBinding: AppTheme.ThemeType { selectedTheme }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: themeBinding, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                RecipeSearchView(recipes: $recipes)
                    .tabItem {
                        Label("Recipes", systemImage: "book.fill")
                    }
                    .tag(0)

                ShoppingListView()
                    .tabItem {
                        Label("Shopping", systemImage: "cart.fill")
                    }
                    .tag(1)

                KitchenView(recipes: $recipes)
                    .tabItem {
                        Label("Kitchen", systemImage: "refrigerator.fill")
                    }
                    .tag(2)
                
                MealPlanningView(recipes: $recipes)
                    .tabItem {
                        Label("Planning", systemImage: "calendar")
                    }
                    .tag(3)
                
                MoreView(recipes: $recipes)
                    .tabItem {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                    .tag(4)
            }
            .environment(\.appTheme, themeBinding)
            .tint(colorScheme == .dark ? .white : .black)
            .onAppear {
                configureTabBarAppearance()
            }
            .onChange(of: selectedTheme) { _, _ in
                // Already on main thread - no need for DispatchQueue
                configureTabBarAppearance()
            }
            .onChange(of: cardStyle) { _, _ in
                // Already on main thread - no need for DispatchQueue
                configureTabBarAppearance()
            }
            .onChange(of: colorScheme) { _, newScheme in
                // Force immediate refresh when color scheme changes
                configureTabBarAppearance()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    configureTabBarAppearance()
                }
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
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            // Reload recipes when user signs in
            if isAuthenticated {
                loadRecipes()
            } else {
                recipes = []
            }
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        
        // Simple rule: Dark mode = white text, Light mode = black text
        let isDarkMode = colorScheme == .dark
        let textColor: UIColor = isDarkMode ? .white : .black
        let dimmedTextColor: UIColor = isDarkMode 
            ? UIColor.white.withAlphaComponent(0.6) 
            : UIColor.black.withAlphaComponent(0.6)
        
        // Background styling based on card style preference
        if cardStyle == .solid {
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = isDarkMode 
                ? UIColor(white: 0.12, alpha: 0.98)
                : UIColor(white: 0.98, alpha: 0.98)
        } else {
            appearance.configureWithDefaultBackground()
            appearance.backgroundEffect = UIBlurEffect(style: isDarkMode ? .systemMaterialDark : .systemMaterialLight)
            appearance.backgroundColor = isDarkMode
                ? UIColor(white: 0.1, alpha: 0.85)
                : UIColor(white: 0.95, alpha: 0.90)
        }
        
        // Selected tab: Full brightness text color
        appearance.stackedLayoutAppearance.selected.iconColor = textColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: textColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        
        // Unselected tab: Dimmed text color
        appearance.stackedLayoutAppearance.normal.iconColor = dimmedTextColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: dimmedTextColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        
        // Apply the appearance
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // Update existing tab bars (already on main thread in SwiftUI)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .compactMap { $0.rootViewController }
            .forEach { updateTabBars(in: $0, with: appearance, textColor: textColor, dimmedColor: dimmedTextColor) }
    }
    
    private func updateTabBars(in viewController: UIViewController, with appearance: UITabBarAppearance, textColor: UIColor, dimmedColor: UIColor) {
        if let tabBarController = viewController as? UITabBarController {
            tabBarController.tabBar.standardAppearance = appearance
            tabBarController.tabBar.scrollEdgeAppearance = appearance
            tabBarController.tabBar.tintColor = textColor
            tabBarController.tabBar.unselectedItemTintColor = dimmedColor
        }
        
        viewController.children.forEach { updateTabBars(in: $0, with: appearance, textColor: textColor, dimmedColor: dimmedColor) }
        
        if let presented = viewController.presentedViewController {
            updateTabBars(in: presented, with: appearance, textColor: textColor, dimmedColor: dimmedColor)
        }
    }

    private func loadRecipes() {
        recipes = PersistenceController.shared.fetchRecipes()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
