import SwiftUI

private let logger = AppLogger.logger(category: "ContentView")

struct ContentView: View {
    @State private var recipes: [RecipeModel] = []
    @State private var selectedTab: Int = 0
    @State private var sidebarSelection: SidebarItem? = .recipes
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var badgeManager = BadgeManager.shared
    @State private var showBadgeSheet = false
    @State private var showAccountFromBadge = false
    
    private var themeBinding: AppTheme.ThemeType { selectedTheme }

    private enum SidebarItem: Int, Hashable, CaseIterable {
        case recipes, groceries, importRecipes, planning, settings

        var label: String {
            switch self {
            case .recipes: "Recipes"
            case .groceries: "Groceries"
            case .importRecipes: "Import"
            case .planning: "Planning"
            case .settings: "Settings"
            }
        }

        var icon: String {
            switch self {
            case .recipes: "book.fill"
            case .groceries: "cart.fill"
            case .importRecipes: "plus.circle.fill"
            case .planning: "calendar"
            case .settings: "gearshape.fill"
            }
        }
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .onAppear {
            if recipes.isEmpty {
                loadRecipes()
            }
            NotificationManager.shared.requestPermission { _ in }
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                loadRecipes()
            } else {
                recipes = []
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userScopeDidChange)) { _ in
            guard authManager.isAuthenticated else { return }
            loadRecipes()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenRecipes"))) { _ in
            selectedTab = 0
            sidebarSelection = .recipes
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenGroceries"))) { _ in
            selectedTab = 1
            sidebarSelection = .groceries
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenMealPlan"))) { _ in
            selectedTab = 3
            sidebarSelection = .planning
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenRecipe"))) { _ in
            selectedTab = 0
            sidebarSelection = .recipes
        }
        .onChange(of: badgeManager.pendingCelebration) { _, newValue in
            if newValue != nil { showBadgeSheet = true }
        }
        .sheet(isPresented: $showBadgeSheet, onDismiss: {
            badgeManager.dismissCelebration()
        }) {
            if let badge = badgeManager.pendingCelebration {
                BadgeEarnedSheet(badge: badge, onDismiss: {
                    showBadgeSheet = false
                }, onViewAllBadges: {
                    showBadgeSheet = false
                    showAccountFromBadge = true
                })
                .presentationDetents([.height(380)])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showAccountFromBadge) {
            NavigationStack {
                AccountView()
            }
        }
    }

    private var iPhoneLayout: some View {
        ZStack {
            AppTheme.backgroundGradient(for: themeBinding, colorScheme: colorScheme)
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                RecipeSearchView(recipes: $recipes)
                    .tabItem { Label("Recipes", systemImage: "book.fill") }
                    .tag(0)
                KitchenShoppingView(recipes: $recipes)
                    .tabItem { Label("Groceries", systemImage: "cart.fill") }
                    .tag(1)
                ImportView(recipes: $recipes)
                    .tabItem { Label("Import", systemImage: "plus.circle.fill") }
                    .tag(2)
                MealPlanningView(recipes: $recipes)
                    .tabItem { Label("Planning", systemImage: "calendar") }
                    .tag(3)
                NavigationStack {
                    SettingsTabView()
                }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
            }
            .environment(\.appTheme, themeBinding)
            .tint(AppTheme.textColor(for: colorScheme))
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    configureTabBarAppearance()
                }
            }
            .onChange(of: selectedTab) { _, _ in
                HapticManager.shared.selection()
            }
        }
    }

    private var iPadLayout: some View {
        NavigationSplitView {
            ZStack {
                AppTheme.backgroundGradient(for: themeBinding, colorScheme: colorScheme)
                    .ignoresSafeArea()

                List(SidebarItem.allCases, id: \.self, selection: $sidebarSelection) { item in
                    Label(item.label, systemImage: item.icon)
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("RecipeFinder")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
            }
        } detail: {
            sidebarDetailView
                .environment(\.appTheme, themeBinding)
        }
    }

    @ViewBuilder
    private var sidebarDetailView: some View {
        switch sidebarSelection ?? .recipes {
        case .recipes:
            RecipeSearchView(recipes: $recipes)
        case .groceries:
            KitchenShoppingView(recipes: $recipes)
        case .importRecipes:
            ImportView(recipes: $recipes)
        case .planning:
            MealPlanningView(recipes: $recipes)
        case .settings:
            NavigationStack { SettingsTabView() }
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        
        let isDarkMode = colorScheme == .dark
        let textColor: UIColor = isDarkMode ? .white : .black
        let dimmedTextColor: UIColor = isDarkMode 
            ? UIColor.white.withAlphaComponent(0.6) 
            : UIColor.black.withAlphaComponent(0.6)
        
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
        
        appearance.stackedLayoutAppearance.selected.iconColor = textColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: textColor,
            .font: UIFont.systemFont(ofSize: AppTheme.fontSize11, weight: .semibold)
        ]
        
        appearance.stackedLayoutAppearance.normal.iconColor = dimmedTextColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: dimmedTextColor,
            .font: UIFont.systemFont(ofSize: AppTheme.fontSize11, weight: .medium)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
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

    private func loadRecipes(retryAttempt: Int = 0) {
        // Guest mode: show seed recipes so the app isn't empty before sign-up.
        guard authManager.isAuthenticated else {
            if recipes.isEmpty {
                recipes = SeedRecipeProvider.recipes
            }
            return
        }

        guard PersistenceController.shared.hasCurrentUserScope() else {
            logger.debug("⚠️ Skipping recipe reload because user scope is not available")
            return
        }

        // The store loads synchronously at launch, but corrupted-store
        // recovery reloads it late. Without a retry, one empty fetch here
        // used to strand the user with a blank recipe list for the session.
        guard PersistenceController.shared.isStoreLoaded else {
            guard retryAttempt < 5 else {
                logger.error("❌ Store never became ready; giving up on recipe reload")
                return
            }
            logger.debug("⚠️ Store not ready; retrying recipe load (attempt \(retryAttempt + 1))")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                loadRecipes(retryAttempt: retryAttempt + 1)
            }
            return
        }

        var fetched = PersistenceController.shared.fetchRecipes()
        // Seed starter recipes for brand-new users — one-time per user account.
        if fetched.isEmpty, !UserScopedStorage.shared.bool(forKey: "seedRecipesLoaded") {
            SeedRecipeProvider.recipes.forEach { PersistenceController.shared.saveRecipeModel($0) }
            UserScopedStorage.shared.set(true, forKey: "seedRecipesLoaded")
            fetched = PersistenceController.shared.fetchRecipes()
        }
        recipes = fetched
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
