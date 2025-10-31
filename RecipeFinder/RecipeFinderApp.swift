import SwiftData
import SwiftUI
import UIKit

@main
struct RecipeFinderApp: App {
    // Initialize PersistenceController
    let persistenceController = PersistenceController.shared
    @StateObject private var authManager = AuthenticationManager.shared
    
    init() {
        configureAppearance()
        
        // Populate database with sample data on first launch only
        if !UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.hasPopulatedDatabase) {
            debugLog("🔄 First launch detected - populating database with sample recipes...")
            persistenceController.populateDatabase()
            UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.hasPopulatedDatabase)
            debugLog("✅ Database populated successfully")
        } else {
            debugLog("✅ Database already populated - skipping initialization")
        }
        
        #if DEBUG
        // Seed test accounts for easy testing (Debug only)
        if !UserDefaults.standard.bool(forKey: "hasSeededTestAccounts") {
            AuthTestHelper.seedTestAccounts()
            UserDefaults.standard.set(true, forKey: "hasSeededTestAccounts")
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .onAppear {
                            authManager.updateLastActiveTimestamp()
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    NavigationStack {
                        AuthenticationView()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Check if session expired when app comes back to foreground
                authManager.checkSessionExpiration()
            }
        }
    }
    
    // UI Configuration
    private func configureAppearance() {
        // Configure tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        
        // Style unselected tabs
        tabAppearance.stackedLayoutAppearance.normal.iconColor = .gray
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.gray
        ]
        
        // Style selected tabs
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.8, green: 0.2, blue: 0.6, alpha: 1.0)
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0.8, green: 0.2, blue: 0.6, alpha: 1.0)
        ]
        
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
        
        // Configure navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        
        // Style navigation bar text
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        // Style back button
        navAppearance.backButtonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        UINavigationBar.appearance().tintColor = .white
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        
        // Configure search bar appearance
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = UIColor.white.withAlphaComponent(0.1)
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = UIColor(red: 0.8, green: 0.2, blue: 0.6, alpha: 1.0)
    }
}
