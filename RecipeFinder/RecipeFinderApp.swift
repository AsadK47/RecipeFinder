import SwiftUI
import UIKit

private let logger = AppLogger.logger(category: "RecipeFinderApp")

@main
struct RecipeFinderApp: App {
    private enum ActiveOnboarding {
        case biometrics
        case app
    }

    let persistenceController = PersistenceController.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var activeOnboarding: ActiveOnboarding?
    
    init() {
        configureAppearance()
        initializeDatabase()
        requestNotificationPermissions()
        
        #if DEBUG
        AuthTestHelper.ensureTestAccountExists()
        #endif
    }
    
    private func requestNotificationPermissions() {
        Task {
            NotificationManager.shared.requestPermission { granted in
                logger.info("\(granted ? "✅" : "⚠️") User \(granted ? "granted" : "denied") notification permissions")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
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
        }
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
        if authManager.isAuthenticated {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(themeManager)
                .onAppear { authManager.updateLastActiveTimestamp() }
                .transition(.opacity.combined(with: .scale(scale: AppTheme.transitionScaleDown)))
        } else {
            NavigationStack {
                AuthenticationView()
            }
            .environmentObject(themeManager)
            .transition(.opacity.combined(with: .scale(scale: AppTheme.transitionScaleUp)))
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
