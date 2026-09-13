import SwiftUI
import UIKit

private let logger = AppLogger.logger(category: "RecipeFinderApp")

@main
struct RecipeFinderApp: App {

    init() {
        #if DEBUG
        // UI-test launch hooks, consumed only under XCUITest and gated to DEBUG
        // so no reset path can ever ship in a release build. App.init runs on
        // the main thread, so assuming main-actor isolation here is safe.
        MainActor.assumeIsolated {
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("-ui-testing") {
                // Deterministic, flicker-free UI so element queries don't race animations.
                UIView.setAnimationsEnabled(false)
                if arguments.contains("-resetState") {
                    AuthTestHelper.clearAllAuthData()
                }
            }
        }
        #endif

        configureAppearance()
        initializeDatabase()

        // Runs after any -resetState wipe above so the known debug account is
        // always available to sign in with.
        #if DEBUG
        AuthTestHelper.ensureTestAccountExists()
        if ProcessInfo.processInfo.arguments.contains("-skip-auth") {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.set(true, forKey: "hasSeenBiometricOnboarding")
            AuthTestHelper.autoSignIn()
        }
        #endif
    }
    
    var body: some Scene {
        // The scene content closure can be evaluated by SwiftUI's async
        // renderer off the main thread. It must stay trivial: all MainActor
        // state (auth, onboarding, theme) lives inside AppRootView, whose
        // body is guaranteed main-actor by the View protocol. Reading that
        // state directly here crashes with dispatch_assert_queue_fail
        // (EXC_BREAKPOINT in RecipeFinderApp.body closure #1).
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
            .font: UIFont.systemFont(ofSize: AppTheme.fontSize18, weight: .semibold)
        ]
        
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: AppTheme.fontSize34, weight: .bold)
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
    private enum ActiveOnboarding {
        case biometrics
        case app
    }

    let persistenceController = PersistenceController.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var activeOnboarding: ActiveOnboarding?
    @AppStorage("preferredColorScheme") private var colorSchemePreference: Int = 0
    @AppStorage("guestModeEnabled") private var guestModeEnabled = false

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    var body: some View {
        Group {
            if activeOnboarding == .biometrics {
                FaceIDOnboardingSplash {
                    UserScopedStorage.shared.set(true, forKey: "hasSeenBiometricOnboarding")

                    if !UserScopedStorage.shared.bool(forKey: "hasCompletedOnboarding") {
                        withAnimation(.easeInOut(duration: AppTheme.animationDelayXShort)) {
                            activeOnboarding = .app
                        }
                    } else {
                        withAnimation(.easeInOut(duration: AppTheme.animationDelayXShort)) {
                            activeOnboarding = nil
                        }
                    }
                }
                .ignoresSafeArea()
                .transition(.opacity)
            } else if activeOnboarding == .app {
                OnboardingView(onComplete: {
                    UserScopedStorage.shared.set(true, forKey: "hasCompletedOnboarding")
                    withAnimation(.easeInOut(duration: AppTheme.animationDelayXShort)) {
                        activeOnboarding = nil
                    }
                })
                .ignoresSafeArea()
                .transition(.opacity)
            } else {
                rootView
                    .animation(.easeInOut(duration: AppTheme.animationDelayXShort), value: authManager.isAuthenticated)
                    .onAppear {
                        if authManager.isAuthenticated {
                            evaluateOnboardingFlow()
                        }
                    }
                    .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
                        if isAuthenticated {
                            guestModeEnabled = false  // Sign-in supersedes guest mode
                            evaluateOnboardingFlow()
                        } else {
                            activeOnboarding = nil
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        authManager.checkSessionExpiration()
                    }
            }
        }
        .animation(.easeInOut(duration: AppTheme.animationDelayXShort), value: activeOnboarding)
        .preferredColorScheme(preferredColorScheme)
    }

    private func evaluateOnboardingFlow() {
        let hasCompletedOnboarding = UserScopedStorage.shared.bool(forKey: "hasCompletedOnboarding")
        let hasSeenBiometricOnboarding = UserScopedStorage.shared.bool(forKey: "hasSeenBiometricOnboarding")

        if authManager.biometricsAvailable && !hasSeenBiometricOnboarding {
            withAnimation(.easeInOut(duration: AppTheme.animationDelayXShort)) {
                activeOnboarding = .biometrics
            }
        } else if !hasCompletedOnboarding {
            withAnimation(.easeInOut(duration: AppTheme.animationDelayXShort)) {
                activeOnboarding = .app
            }
        } else {
            withAnimation(.easeInOut(duration: AppTheme.animationDelayXShort)) {
                activeOnboarding = nil
            }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        if authManager.isAuthenticated || guestModeEnabled {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(themeManager)
                .onAppear { if authManager.isAuthenticated { authManager.updateLastActiveTimestamp() } }
                .transition(.opacity.combined(with: .scale(scale: AppTheme.transitionScaleDown)))
        } else {
            NavigationStack {
                AuthenticationView()
            }
            .environmentObject(themeManager)
            .transition(.opacity.combined(with: .scale(scale: AppTheme.transitionScaleUp)))
        }
    }
}
