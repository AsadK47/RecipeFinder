import SwiftData
import SwiftUI
import UIKit

@main
struct RecipeFinderApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authManager = AuthenticationManager.shared
    
    init() {
        configureAppearance()
        initializeDatabase()
    }
    
    var body: some Scene {
        WindowGroup {
            rootView
                .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
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
                .onAppear { authManager.updateLastActiveTimestamp() }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        } else {
            NavigationStack {
                AuthenticationView()
            }
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
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .black.withAlphaComponent(0.1)
        
        let accentColor = UIColor(red: 0.8, green: 0.2, blue: 0.6, alpha: 1.0)
        
        appearance.stackedLayoutAppearance.normal.iconColor = .gray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
        
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
    }
}
