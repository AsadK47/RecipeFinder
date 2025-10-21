//
//  RecipeFinderApp.swift
//  RecipeFinder
//
//  Created by asad.e.khan on 10/12/2024.
//

import SwiftUI
import SwiftData
import UIKit

@main
struct RecipeFinderApp: App {
    // Initialize PersistenceController
    let persistenceController = PersistenceController.shared
    
    init() {
        configureAppearance()
        
        // Populate database with sample data on first launch only
        if !UserDefaults.standard.bool(forKey: "hasPopulatedDatabase") {
            print("🔄 First launch detected - populating database with sample recipes...")
            persistenceController.populateDatabase()
            UserDefaults.standard.set(true, forKey: "hasPopulatedDatabase")
            print("✅ Database populated successfully")
        } else {
            print("✅ Database already populated - skipping initialization")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    
    // MARK: - UI Configuration
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
