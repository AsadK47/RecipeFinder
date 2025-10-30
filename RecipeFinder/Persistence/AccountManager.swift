import Foundation
import Combine

final class AccountManager: ObservableObject {
    static let shared = AccountManager()
    
    @Published private(set) var name: String = ""
    @Published private(set) var email: String = ""
    @Published private(set) var recipeCount: Int = 0
    @Published private(set) var kitchenItemCount: Int = 0
    @Published private(set) var shoppingListCount: Int = 0
    
    private let nameKey = "accountName"
    private let emailKey = "accountEmail"
    
    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        } else if let first = name.first {
            return String(first).uppercased()
        }
        return "U"
    }
    
    private init() {
        loadProfile()
        updateStats()
        
        // Observe data changes to update stats
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateStats),
            name: NSNotification.Name("DataDidChange"),
            object: nil
        )
    }
    
    // MARK: - Profile Management
    
    func loadProfile() {
        name = UserDefaults.standard.string(forKey: nameKey) ?? "Recipe Chef"
        email = UserDefaults.standard.string(forKey: emailKey) ?? ""
    }
    
    func updateProfile(name: String, email: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else { return }
        
        self.name = trimmedName
        self.email = trimmedEmail
        
        UserDefaults.standard.set(trimmedName, forKey: nameKey)
        UserDefaults.standard.set(trimmedEmail, forKey: emailKey)
        
        HapticManager.shared.success()
    }
    
    // MARK: - Stats
    
    @objc func updateStats() {
        // Update recipe count from Core Data
        recipeCount = PersistenceController.shared.fetchRecipeCount()
        
        // Update kitchen items count
        if let data = UserDefaults.standard.data(forKey: Constants.UserDefaultsKeys.kitchenItems),
           let items = try? JSONDecoder().decode([KitchenItem].self, from: data) {
            kitchenItemCount = items.count
        }
        
        // Update shopping list count
        if let data = UserDefaults.standard.data(forKey: Constants.UserDefaultsKeys.shoppingListItems),
           let items = try? JSONDecoder().decode([ShoppingListItem].self, from: data) {
            shoppingListCount = items.count
        }
    }
    
    // MARK: - Data Management
    
    func exportData() {
        // TODO: Implement data export
        HapticManager.shared.success()
        print("📤 Data export initiated")
    }
    
    func clearAllData() {
        // Clear all UserDefaults data (except account info)
        let keysToRemove = [
            Constants.UserDefaultsKeys.kitchenItems,
            Constants.UserDefaultsKeys.shoppingListItems,
            Constants.UserDefaultsKeys.hasPopulatedDatabase
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // Clear Core Data recipes
        PersistenceController.shared.clearAllRecipes()
        
        // Repopulate with sample recipes
        PersistenceController.shared.populateDatabase()
        UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.hasPopulatedDatabase)
        
        updateStats()
        
        HapticManager.shared.success()
        print("🗑️ All data cleared and reset to defaults")
        
        // Notify other views to refresh
        NotificationCenter.default.post(name: NSNotification.Name("DataDidChange"), object: nil)
    }
}
