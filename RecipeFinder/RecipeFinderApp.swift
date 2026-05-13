import SwiftData
import SwiftUI
import UIKit

private let logger = AppLogger.logger(category: "RecipeFinderApp")

@main
struct RecipeFinderApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var hasCompletedOnboarding = false
    @State private var hasSeenBiometricOnboarding = false
    @State private var showOnboarding = false
    @State private var showFaceIDOnboarding = false
    
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
            ZStack {
                rootView
                    .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
                    .fullScreenCover(isPresented: $showFaceIDOnboarding) {
                        FaceIDOnboardingSplash {
                            UserScopedStorage.shared.set(true, forKey: "hasSeenBiometricOnboarding")
                            hasSeenBiometricOnboarding = true
                            showFaceIDOnboarding = false
                            if !hasCompletedOnboarding {
                                DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayXShort) {
                                    showOnboarding = true
                                }
                            }
                        }
                    }
                    .fullScreenCover(isPresented: $showOnboarding) {
                        OnboardingView()
                            .onDisappear {
                                UserScopedStorage.shared.set(true, forKey: "hasCompletedOnboarding")
                                hasCompletedOnboarding = true
                            }
                    }
                    .onAppear {
                        loadUserOnboardingFlags()
                        if authManager.isAuthenticated {
                            handleOnboardingFlow()
                        }
                    }
                    .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
                        if isAuthenticated {
                            loadUserOnboardingFlags()
                            handleOnboardingFlow()
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        authManager.checkSessionExpiration()
                    }
                
                if showFaceIDOnboarding || showOnboarding {
                    Color.black
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    private func loadUserOnboardingFlags() {
        hasCompletedOnboarding = UserScopedStorage.shared.bool(forKey: "hasCompletedOnboarding")
        hasSeenBiometricOnboarding = UserScopedStorage.shared.bool(forKey: "hasSeenBiometricOnboarding")
    }
    
    private func handleOnboardingFlow() {
        if authManager.biometricsAvailable && !hasSeenBiometricOnboarding {
            showFaceIDOnboarding = true
        }
        else if !hasCompletedOnboarding {
            showOnboarding = true
        }
    }
    
    @ViewBuilder
    private var rootView: some View {
        if authManager.isAuthenticated {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(themeManager)
                .onAppear { authManager.updateLastActiveTimestamp() }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        } else {
            NavigationStack {
                AuthenticationView()
            }
            .environmentObject(themeManager)
            .transition(.opacity.combined(with: .scale(scale: 1.05)))
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
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
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
