import CoreData
import SwiftUI
import TipKit
import UIKit

private let logger = AppLogger.logger(category: "RecipeFinderApp")

@main
struct RecipeFinderApp: App {

    /// Unit tests run inside this app; skipping its launch work and screens keeps them off CI's 3 CPUs.
    /// UI tests launch the app as a separate process without these variables, so they get the real app.
    private static let isHostingUnitTests: Bool = {
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        return env["XCTestConfigurationFilePath"] != nil || env["XCTestBundlePath"] != nil
            || env["XCTestSessionIdentifier"] != nil
        #else
        false
        #endif
    }()

    init() {
        guard !Self.isHostingUnitTests else { return }
        // First, before anything opens the database: the Settings sync switch only takes effect at launch.
        SyncPreference.applyAtLaunch(in: .shared)
        // Hang and crash reports from earlier runs arrive through this (issue #16).
        DiagnosticReporter.shared.start()

        #if DEBUG
        // UI-test launch hook; DEBUG-gated, and App.init is main-thread so assumeIsolated is safe.
        MainActor.assumeIsolated {
            if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
                // Deterministic, flicker-free UI so element queries don't race animations.
                UIView.setAnimationsEnabled(false)
                // The Recipes toggle is remembered, and UI tests share a simulator: start each run on My recipes
                // (the list most tests tap into) unless a test asks for Discover.
                let mode: RecipeBrowse.Mode = ProcessInfo.processInfo.arguments.contains("-recipes-discover")
                    ? .discover : .myRecipes
                UserDefaults.standard.set(mode.rawValue, forKey: RecipeBrowse.modeKey)
                // Groceries' To buy | At home is remembered too; every run starts on the shopping list.
                UserDefaults.standard.set(GroceriesMode.toBuy.rawValue, forKey: GroceriesMode.modeKey)
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
        MainActor.assumeIsolated {
            Self.reloadOnICloudChanges()
            Self.purgeOldStoreHistory()
        }
    }

    /// Keeps the store's history to the last week, unless iCloud still needs it (`HistoryPurgeRule`).
    @MainActor private static func purgeOldStoreHistory() {
        let persistence = PersistenceController.shared
        guard let cutoff = HistoryPurgeRule.cutoff(now: .now, in: .shared) else { return }
        Task { await persistence.purgeHistory(before: cutoff) }
    }

    /// Holds the export-event observer for the app's lifetime; nil while sync is off.
    @MainActor private static var exportObserver: NSObjectProtocol?

    /// Records each export CloudKit finishes, so the launch purge keeps what it hasn't sent (`HistoryPurgeRule`).
    @MainActor private static func recordICloudExports() {
        guard exportObserver == nil else { return }
        exportObserver = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification, object: nil, queue: .main
        ) { notification in
            guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event,
                  let sent = HistoryPurgeRule.sentUpTo(
                    isExport: event.type == .export, succeeded: event.succeeded,
                    startDate: event.startDate, endDate: event.endDate
                  )
            else { return }
            HistoryPurgeRule.recordExport(startedAt: sent, in: .shared)
        }
    }

    /// Holds the app's reloader for its lifetime; nil while sync is off.
    @MainActor private static var iCloudReloader: RemoteChangeReloader?

    /// With iCloud sync on, every list re-reads the store when another device's edits arrive.
    @MainActor private static func reloadOnICloudChanges() {
        let persistence = PersistenceController.shared
        guard persistence.isSyncing, iCloudReloader == nil else { return }
        persistence.startTrackingOutsideChanges()
        recordICloudExports()
        let reloader = RemoteChangeReloader(
            hasOutsideChanges: { await persistence.takeOutsideChanges() },
            reloads: [
                // Starts the recipe fetch and returns; the fetch itself runs off the main thread.
                .init(name: "recipes") { RecipeStore.shared.load() },
                .init(name: "collections") { CollectionManager.shared.reload() },
                .init(name: "meal plans") { MealPlanningManager.shared.reload() },
                .init(name: "shopping list") { ShoppingListManager.shared.reload() },
                .init(name: "kitchen") { KitchenInventoryManager.shared.reload() },
                .init(name: "badges") { BadgeManager.shared.reload() },
                .init(name: "cooking streak") { CookingStreakManager.shared.reload() },
                .init(name: "profile") { ProfileManager.shared.loadProfile() }
            ]
        )
        reloader.observe(persistence.container.persistentStoreCoordinator)
        iCloudReloader = reloader
        logger.info("iCloud sync on: lists reload when other devices' edits arrive")
    }
    
    var body: some Scene {
        // Keep trivial: SwiftUI may evaluate this closure off-main, so all MainActor state stays in AppRootView — reading it here crashes (dispatch_assert_queue_fail).
        WindowGroup {
            if Self.isHostingUnitTests {
                Color.clear
            } else {
                AppRootView()
            }
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
    @AppStorage("keepScreenAwake") private var keepScreenAwake = false
    @Environment(\.scenePhase) private var scenePhase
    private let keepAwake = KeepAwakeSetting(write: { UIApplication.shared.isIdleTimerDisabled = $0 })

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
        .onAppear {
            evaluateOnboardingFlow()
            keepAwake.appBecameActive(settingOn: keepScreenAwake)
        }
        .onChange(of: keepScreenAwake) { _, isOn in keepAwake.switched(on: isOn) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { keepAwake.appBecameActive(settingOn: keepScreenAwake) }
        }
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
