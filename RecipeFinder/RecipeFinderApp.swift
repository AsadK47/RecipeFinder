import SwiftUI
import TipKit
import UIKit

private let logger = AppLogger.logger(category: "RecipeFinderApp")

@main
struct RecipeFinderApp: App {

    init() {
        // First, before anything opens the database: the Settings sync switch only takes effect at launch.
        SyncPreference.applyAtLaunch(in: .shared)

        #if DEBUG
        // UI-test launch hook; DEBUG-gated, and App.init is main-thread so assumeIsolated is safe.
        MainActor.assumeIsolated {
            if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
                // Deterministic, flicker-free UI so element queries don't race animations.
                UIView.setAnimationsEnabled(false)
            }
            if ProcessInfo.processInfo.arguments.contains("-show-badge-reveal") {
                BadgeManager.shared.showRevealForUITesting(.headChef)
            }
        }
        #endif

        try? Tips.configure([.displayFrequency(.daily)])
        configureAppearance()
        initializeDatabase()
        // App.init runs on the main thread.
        MainActor.assumeIsolated { Self.reloadOnICloudChanges() }
    }

    /// Holds the app's reloader for its lifetime; nil while sync is off.
    @MainActor private static var iCloudReloader: RemoteChangeReloader?

    /// With iCloud sync on, every list re-reads the store when another device's edits arrive.
    @MainActor private static func reloadOnICloudChanges() {
        let persistence = PersistenceController.shared
        guard persistence.isSyncing, iCloudReloader == nil else { return }
        persistence.startTrackingOutsideChanges()
        let reloader = RemoteChangeReloader(
            hasOutsideChanges: { persistence.takeOutsideChanges() },
            reloads: [
                { RecipeStore.shared.load() },
                { CollectionManager.shared.reload() },
                { MealPlanningManager.shared.reload() },
                { ShoppingListManager.shared.reload() },
                { KitchenInventoryManager.shared.reload() },
                { BadgeManager.shared.reload() },
                { CookingStreakManager.shared.reload() },
                { ProfileManager.shared.loadProfile() }
            ]
        )
        reloader.observe(persistence.container.persistentStoreCoordinator)
        iCloudReloader = reloader
        logger.info("iCloud sync on: lists reload when other devices' edits arrive")
    }
    
    var body: some Scene {
        // Keep trivial: SwiftUI may evaluate this closure off-main, so all MainActor state stays in AppRootView — reading it here crashes (dispatch_assert_queue_fail).
        WindowGroup {
            AppRootView()
        }
    }
    
    private func initializeDatabase() {
        logger.debug("✅ Database initialized")
    }
    
    private func configureAppearance() {
        configureTabBar()
        configureNavigationBar()
        configureSearchBar()
    }
    
    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        
        let tabBarAppearance = UITabBar.appearance()
        tabBarAppearance.standardAppearance = appearance
        tabBarAppearance.scrollEdgeAppearance = appearance
    }
    
    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .black.withAlphaComponent(0.1)
        
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFontMetrics(forTextStyle: .headline).scaledFont(
                for: UIFont.systemFont(ofSize: AppTheme.fontSize18, weight: .semibold)
            )
        ]

        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(
                for: UIFont.systemFont(ofSize: AppTheme.fontSize34, weight: .bold)
            )
        ]
        
        appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        let navBarAppearance = UINavigationBar.appearance()
        navBarAppearance.tintColor = .white
        navBarAppearance.standardAppearance = appearance
        navBarAppearance.compactAppearance = appearance
        navBarAppearance.scrollEdgeAppearance = appearance
    }
    
    private func configureSearchBar() {
        let textField = UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        textField.backgroundColor = .white.withAlphaComponent(0.1)
        textField.tintColor = UIColor(red: 0.8, green: 0.2, blue: 0.6, alpha: 1.0)
        textField.textColor = .label
        textField.attributedPlaceholder = NSAttributedString(
            string: "",
            attributes: [.foregroundColor: UIColor.secondaryLabel]
        )
        
        UITextField.appearance().attributedPlaceholder = NSAttributedString(
            string: "",
            attributes: [.foregroundColor: UIColor.label.withAlphaComponent(0.6)]
        )
    }
}

/// Root view owning the app's top-level MainActor state. Kept out of the
/// WindowGroup closure on purpose — see the note in RecipeFinderApp.body.
struct AppRootView: View {
    let persistenceController = PersistenceController.shared
    @State private var showOnboarding = false
    @AppStorage("preferredColorScheme") private var colorSchemePreference: Int = 0

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(onComplete: {
                    LocalStore.shared.set(true, forKey: "hasCompletedOnboarding")
                    withAnimation(.easeInOut(duration: AppTheme.animationDelayXShort)) {
                        showOnboarding = false
                    }
                })
                .ignoresSafeArea()
                .transition(.opacity)
            } else {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .transition(.opacity.combined(with: .scale(scale: AppTheme.transitionScaleDown)))
            }
        }
        .onAppear(perform: evaluateOnboardingFlow)
        .animation(.easeInOut(duration: AppTheme.animationDelayXShort), value: showOnboarding)
        .preferredColorScheme(preferredColorScheme)
    }

    /// First run shows onboarding once; UI tests skip it so the tab bar is reachable immediately.
    private func evaluateOnboardingFlow() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing") { return }
        #endif
        showOnboarding = !LocalStore.shared.bool(forKey: "hasCompletedOnboarding")
    }
}
