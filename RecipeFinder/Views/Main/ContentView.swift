import SwiftUI

private let logger = AppLogger.logger(category: "ContentView")

struct ContentView: View {
    @Environment(\.recipeStore) private var store
    @State private var showTimer = false
    @State private var selectedTab: AppTab = .launchDefault
    /// iPad sidebar selection; optional because `List(selection:)` can clear it.
    @State private var sidebarSelection: AppTab? = .launchDefault
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.badges) private var badgeManager
    @Environment(\.madeItPresenter) private var madeItPresenter
    /// Set by "View all badges"; the Me tab opens once the badge reveal has fully closed.
    @State private var openMeAfterBadge = false
    @State private var showAddRecipe = false
    /// True from opening the "+" sheet until it has fully dismissed: a badge earned by the import waits for it, since a
    /// second sheet presented over (or mid-dismissal of) another is silently dropped.
    @State private var addRecipeBusy = false
    /// A link pasted on Today's clipboard card, imported straight away.
    @State private var clipboardLink: ClipboardLinkImport?
    @State private var pendingFileImport: RecipeModel?
    @State private var fileImportError: String?
    /// Held until the import sheet finishes dismissing — an alert raised while it's still up never appears.
    @State private var pendingFileSaveError: String?
    @State private var fileSaveError: String?


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
        .onReceive(NotificationCenter.default.publisher(for: .openToday)) { select(AppTab.destination(for: $0.name)) }
        .onReceive(NotificationCenter.default.publisher(for: .openRecipes)) { select(AppTab.destination(for: $0.name)) }
        .onReceive(NotificationCenter.default.publisher(for: .openGroceries)) { select(AppTab.destination(for: $0.name)) }
        .onReceive(NotificationCenter.default.publisher(for: .openMealPlan)) { select(AppTab.destination(for: $0.name)) }
        .onReceive(NotificationCenter.default.publisher(for: .openRecipe)) { select(AppTab.destination(for: $0.name)) }
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
        .errorAlert("Couldn't Open Recipe", message: $fileImportError)
        // A celebration waits for the Made it sheet: the same cook often unlocks a badge, and presenting both at once
        // left neither on screen.
        .fullScreenCover(item: Binding(
            get: {
                BadgeReveal.showing(
                    badgeManager.pendingCelebration,
                    isAnotherSheetUp: madeItPresenter.isBusy || addRecipeBusy
                )
            },
            set: { if $0 == nil { badgeManager.dismissCelebration() } }
        ), onDismiss: {
            if openMeAfterBadge {
                openMeAfterBadge = false
                select(.me)
            }
        }) { badge in
            BadgeRevealView(badge: badge, onDismiss: {
                badgeManager.dismissCelebration()
            }, onViewAllBadges: {
                openMeAfterBadge = true
                badgeManager.dismissCelebration()
            })
        }
        .errorAlert("Couldn't Save Recipe", message: $fileSaveError)
        .sheet(isPresented: $showAddRecipe, onDismiss: { addRecipeBusy = false }) {
            ImportView()
        }
        .sheet(item: $clipboardLink, onDismiss: {
            addRecipeBusy = false
            fileSaveError = pendingFileSaveError
            pendingFileSaveError = nil
        }) { link in
            AddRecipeImportFlow(source: .link(link.url), existingNames: store.recipes.map(\.name)) {
                saveLinkImport($0)
            }
        }
        .sheet(item: $pendingFileImport, onDismiss: {
            fileSaveError = pendingFileSaveError
            pendingFileSaveError = nil
        }) { recipe in
            RecipeFileImportSheet(recipe: recipe) { confirmed in
                saveImportedRecipe(confirmed)
            }
        }
    }

    private func saveImportedRecipe(_ recipe: RecipeModel) {
        guard store.add(recipe) else {
            logger.error("Failed to save imported recipe '\(recipe.name)'")
            pendingFileSaveError = "\"\(recipe.name)\" couldn't be saved. Please try again."
            return
        }
        select(.recipes)
    }

    /// Same outcome as the "+" sheet's link import: first-import badge on success (shown once the sheet closes).
    private func saveLinkImport(_ recipe: RecipeModel) {
        switch RecipeImportStore.outcome(didPersist: store.add(recipe), recipeName: recipe.name, source: .link) {
        case .failed(let name):
            logger.error("Failed to save clipboard-link recipe '\(name)'")
            pendingFileSaveError = "\"\(name)\" couldn't be saved. Please try again."
        case .saved(let badge):
            HapticManager.shared.success()
            if let badge { BadgeManager.shared.unlockBadge(badge) }
        }
    }

    private func importClipboardLink(_ url: URL) {
        addRecipeBusy = true
        clipboardLink = ClipboardLinkImport(url: url)
    }

    private func openAddRecipe() {
        addRecipeBusy = true
        showAddRecipe = true
    }

    private func select(_ tab: AppTab?) {
        guard let tab else { return }
        selectedTab = tab
        sidebarSelection = tab
    }

    private var iPhoneLayout: some View {
        // No backdrop here: each tab root draws its own AppBackground (their NavigationStacks are opaque, so one here never shows).
        ZStack {
            TabView(selection: $selectedTab) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    tabRoot(tab)
                        .tabItem { Label(tab.title, systemImage: tab.icon) }
                        .tag(tab)
                }
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

                List(AppTab.allCases, id: \.self, selection: $sidebarSelection) { tab in
                    Label(tab.title, systemImage: tab.icon)
                }
                .scrollContentBackground(.hidden)
                .appNavigationTitle("RecipeFinder")
            }
        } detail: {
            sidebarDetailView
        }
    }

    private var sidebarDetailView: some View {
        tabRoot(sidebarSelection ?? .launchDefault)
    }

    @ViewBuilder
    private func tabRoot(_ tab: AppTab) -> some View {
        switch tab {
        case .today: TodayView(onOpen: { select($0) }, onAddRecipe: openAddRecipe, onImportLink: importClipboardLink)
        case .recipes: RecipeSearchView(isLoading: store.isLoading, onAddRecipe: openAddRecipe)
        case .plan: MealPlanningView()
        case .groceries: KitchenShoppingView()
        case .me: MeView()
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

private struct ClipboardLinkImport: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
