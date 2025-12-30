import SwiftData
import SwiftUI
import UIKit

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
        // Auto-create test account for easy sign-in during development
        AuthTestHelper.ensureTestAccountExists()
        #endif
    }
    
    /// Request notification permissions on app launch
    private func requestNotificationPermissions() {
        // Request asynchronously without blocking main thread
        Task {
            NotificationManager.shared.requestPermission { granted in
                debugLog(granted ? "✅ User granted notification permissions" : "⚠️ User denied notification permissions")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            rootView
                .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
                .fullScreenCover(isPresented: $showFaceIDOnboarding) {
                    FaceIDOnboardingSplash {
                        // Save user-scoped Face ID onboarding completion
                        UserScopedStorage.shared.set(true, forKey: "hasSeenBiometricOnboarding")
                        hasSeenBiometricOnboarding = true
                        showFaceIDOnboarding = false
                        // Show main onboarding after Face ID setup
                        if !hasCompletedOnboarding {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showOnboarding = true
                            }
                        }
                    }
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView()
                        .onDisappear {
                            // Save user-scoped onboarding completion
                            UserScopedStorage.shared.set(true, forKey: "hasCompletedOnboarding")
                            hasCompletedOnboarding = true
                        }
                }
                .onAppear {
                    // Load user-scoped onboarding flags
                    loadUserOnboardingFlags()
                    
                    // Check what to show on first launch after authentication
                    if authManager.isAuthenticated {
                        handleOnboardingFlow()
                    }
                }
                .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
                    // Handle onboarding flow when user first signs in
                    if isAuthenticated {
                        loadUserOnboardingFlags()
                        handleOnboardingFlow()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    authManager.checkSessionExpiration()
                }
        }
    }
    
    // MARK: - Onboarding Flow
    
    private func loadUserOnboardingFlags() {
        hasCompletedOnboarding = UserScopedStorage.shared.bool(forKey: "hasCompletedOnboarding")
        hasSeenBiometricOnboarding = UserScopedStorage.shared.bool(forKey: "hasSeenBiometricOnboarding")
    }
    
    private func handleOnboardingFlow() {
        // Priority 1: Face ID onboarding (if biometrics available and not seen)
        if authManager.biometricsAvailable && !hasSeenBiometricOnboarding {
            showFaceIDOnboarding = true
        }
        // Priority 2: Main app onboarding
        else if !hasCompletedOnboarding {
            showOnboarding = true
        }
    }
    
    // Views
    
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
    
    // Initialization
    
    private func initializeDatabase() {
        guard !UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.hasPopulatedDatabase) else {
            debugLog("✅ Database already populated")
            return
        }
        
        debugLog("🔄 First launch - populating database...")
        persistenceController.populateDatabase()
        UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.hasPopulatedDatabase)
        debugLog("✅ Database ready")
    }
    
    // Appearance Configuration
    
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
        
        // Make all TextField placeholders more readable
        UITextField.appearance().attributedPlaceholder = NSAttributedString(
            string: "",
            attributes: [.foregroundColor: UIColor.label.withAlphaComponent(0.6)]
        )
    }
}
