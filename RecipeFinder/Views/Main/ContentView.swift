import SwiftUI

private let logger = AppLogger.logger(category: "ContentView")

struct ContentView: View {
    @Environment(\.recipeStore) private var store
    @State private var showTimer = false
    @State private var selectedTab: Int = 0
    @State private var sidebarSelection: SidebarItem? = .recipes
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.badges) private var badgeManager
    @State private var showProfileFromBadge = false
    /// Set by "View all badges"; the Profile sheet opens only once the badge sheet has fully dismissed (presenting
    /// it mid-dismissal was silently dropped, so the button appeared to do nothing).
    @State private var openProfileAfterBadge = false
    @State private var pendingFileImport: RecipeModel?
    @State private var fileImportError: String?


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
            if store.recipes.isEmpty {
                store.load()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openRecipes)) { _ in
            selectedTab = 0
            sidebarSelection = .recipes
        }
        .onReceive(NotificationCenter.default.publisher(for: .openGroceries)) { _ in
            selectedTab = 1
            sidebarSelection = .groceries
        }
        .onReceive(NotificationCenter.default.publisher(for: .openMealPlan)) { _ in
            selectedTab = 3
            sidebarSelection = .planning
        }
        .onReceive(NotificationCenter.default.publisher(for: .openRecipe)) { _ in
            selectedTab = 0
            sidebarSelection = .recipes
        }
        // Tapping a finished-timer notification opens the timer (it shows the shared RecipeTimerManager state).
        .onReceive(NotificationCenter.default.publisher(for: .openTimer)) { _ in
            showTimer = true
        }
        .sheet(isPresented: $showTimer) {
            CookTimerView()
        }
        .onOpenURL { url in
            guard url.pathExtension == "recipefinderrecipe" else { return }
            do {
                let data = try Data(contentsOf: url)
                pendingFileImport = try RecipeFileExporter.decode(data)
            } catch {
                // Surface the failure — tapping a shared recipe file that won't open must not be a silent no-op.
                logger.error("Failed to open shared recipe file: \(error.localizedDescription)")
                fileImportError = "This recipe file couldn't be opened. It may be damaged or from a newer version."
            }
        }
        .alert("Couldn't Open Recipe", isPresented: Binding(
            get: { fileImportError != nil },
            set: { if !$0 { fileImportError = nil } }
        )) {
            Button("OK", role: .cancel) { fileImportError = nil }
        } message: {
            Text(fileImportError ?? "")
        }
        .sheet(item: Binding(
            get: { badgeManager.pendingCelebration },
            set: { if $0 == nil { badgeManager.dismissCelebration() } }
        ), onDismiss: {
            if openProfileAfterBadge {
                openProfileAfterBadge = false
                showProfileFromBadge = true
            }
        }) { badge in
            BadgeEarnedSheet(badge: badge, onDismiss: {
                badgeManager.dismissCelebration()
            }, onViewAllBadges: {
                openProfileAfterBadge = true
                badgeManager.dismissCelebration()
            })
            .presentationDetents([.height(380)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showProfileFromBadge) {
            NavigationStack {
                ProfileView()
            }
        }
        .sheet(item: $pendingFileImport) { recipe in
            RecipeFileImportSheet(recipe: recipe) { confirmed in
                saveImportedRecipe(confirmed)
            }
        }
    }

    private func saveImportedRecipe(_ recipe: RecipeModel) {
        guard store.add(recipe) else {
            logger.error("Failed to save imported recipe '\(recipe.name)'")
            return
        }
        selectedTab = 0
        sidebarSelection = .recipes
    }

    private var iPhoneLayout: some View {
        // No backdrop here: each tab root draws its own AppBackground (their NavigationStacks are opaque, so one here never shows).
        ZStack {
            TabView(selection: $selectedTab) {
                RecipeSearchView(isLoading: store.isLoading)
                    .tabItem { Label("Recipes", systemImage: "book.fill") }
                    .tag(0)
                KitchenShoppingView()
                    .tabItem { Label("Groceries", systemImage: "cart.fill") }
                    .tag(1)
                ImportView()
                    .tabItem { Label("Import", systemImage: "plus.circle.fill") }
                    .tag(2)
                MealPlanningView()
                    .tabItem { Label("Planning", systemImage: "calendar") }
                    .tag(3)
                NavigationStack {
                    SettingsTabView()
                }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
            }
            .tint(AppTheme.textColor())
            .onAppear {
                configureTabBarAppearance()
            }
            .onChange(of: ThemeStore.shared.theme) { _, _ in
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
                AppBackground()

                List(SidebarItem.allCases, id: \.self, selection: $sidebarSelection) { item in
                    Label(item.label, systemImage: item.icon)
                }
                .scrollContentBackground(.hidden)
                .appNavigationTitle("RecipeFinder")
            }
        } detail: {
            sidebarDetailView
        }
    }

    @ViewBuilder
    private var sidebarDetailView: some View {
        switch sidebarSelection ?? .recipes {
        case .recipes:
            RecipeSearchView(isLoading: store.isLoading)
        case .groceries:
            KitchenShoppingView()
        case .importRecipes:
            ImportView()
        case .planning:
            MealPlanningView()
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
        
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: isDarkMode ? .systemMaterialDark : .systemMaterialLight)
        appearance.backgroundColor = isDarkMode
            ? UIColor(white: 0.1, alpha: 0.85)
            : UIColor(white: 0.95, alpha: 0.90)
        
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

}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
