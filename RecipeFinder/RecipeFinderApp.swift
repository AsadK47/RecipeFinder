import SwiftData
import SwiftUI
import UIKit

@main
struct RecipeFinderApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    
    init() {
        configureAppearance()
        initializeDatabase()
        requestNotificationPermissions()
    }
    
    /// Request notification permissions on app launch
    private func requestNotificationPermissions() {
        // Request after a short delay to let the app fully load
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NotificationManager.shared.requestPermission { granted in
                if granted {
                    print("✅ User granted notification permissions")
                } else {
                    print("⚠️ User denied notification permissions")
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            rootView
                .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView()
                        .onDisappear {
                            hasCompletedOnboarding = true
                        }
                }
                .onAppear {
                    // Show onboarding on first launch after authentication
                    if authManager.isAuthenticated && !hasCompletedOnboarding {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showOnboarding = true
                        }
                    }
                }
                .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
                    // Show onboarding when user first signs in
                    if isAuthenticated && !hasCompletedOnboarding {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showOnboarding = true
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    authManager.checkSessionExpiration()
                }
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
        appearance.configureWithOpaqueBackground()
        
        // Use a frosted/blurred material background for better readability
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        appearance.backgroundColor = .clear
        
        let accentColor = UIColor(red: 0.8, green: 0.2, blue: 0.6, alpha: 1.0)
        
        // Use label color (adapts to light/dark mode automatically)
        appearance.stackedLayoutAppearance.normal.iconColor = .label
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.label]
        
        appearance.stackedLayoutAppearance.selected.iconColor = accentColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: accentColor]
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
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
        
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
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
