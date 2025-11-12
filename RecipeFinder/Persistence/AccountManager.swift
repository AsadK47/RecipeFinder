import Foundation
import UIKit
import Combine

final class AccountManager: ObservableObject, @unchecked Sendable {
    static let shared = AccountManager()
    
    // Profile fields - MINIMAL DATA COLLECTION
    @Published private(set) var uuid: String = ""
    @Published private(set) var firstName: String = ""
    @Published private(set) var lastName: String = ""
    @Published private(set) var chefType: ChefType = .homeCook
    
    // Stats (non-PII)
    @Published private(set) var recipeCount: Int = 0
    @Published private(set) var kitchenItemCount: Int = 0
    @Published private(set) var shoppingListCount: Int = 0
    
    // UserDefaults keys (non-sensitive only!)
    private let uuidKey = "accountUUID"
    private let firstNameKey = "accountFirstName"
    private let lastNameKey = "accountLastName"
    private let chefTypeKey = "accountChefType"
    private let profileImageKey = "accountProfileImage"
    
    // Note: Email and password are handled by AuthenticationManager/Keychain ONLY
    
    var fullName: String {
        if firstName.isEmpty && lastName.isEmpty {
            return "Recipe Chef"
        }
        var name = firstName
        if !lastName.isEmpty {
            name += " \(lastName)"
        }
        return name.trimmingCharacters(in: .whitespaces)
    }
    
    var initials: String {
        var initialsString = ""
        if let first = firstName.first {
            initialsString += String(first)
        }
        if let last = lastName.first {
            initialsString += String(last)
        }
        return initialsString.isEmpty ? "RC" : initialsString.uppercased()
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
    
    // Profile Management
    
    func loadProfile() {
        // Load or generate UUID
        if let savedUUID = UserDefaults.standard.string(forKey: uuidKey) {
            uuid = savedUUID
        } else {
            uuid = UUID().uuidString
            UserDefaults.standard.set(uuid, forKey: uuidKey)
        }
        
        firstName = UserDefaults.standard.string(forKey: firstNameKey) ?? ""
        lastName = UserDefaults.standard.string(forKey: lastNameKey) ?? ""
        
        if let chefTypeRaw = UserDefaults.standard.string(forKey: chefTypeKey),
           let savedChefType = ChefType(rawValue: chefTypeRaw) {
            chefType = savedChefType
        }
    }
    
    func updateProfile(
        firstName: String,
        lastName: String,
        chefType: ChefType
    ) {
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        self.firstName = trimmedFirstName
        self.lastName = trimmedLastName
        self.chefType = chefType
        
        UserDefaults.standard.set(trimmedFirstName, forKey: firstNameKey)
        UserDefaults.standard.set(trimmedLastName, forKey: lastNameKey)
        UserDefaults.standard.set(chefType.rawValue, forKey: chefTypeKey)
        
        HapticManager.shared.success()
    }
    
    // Profile Image Management
    
    func saveProfileImage(_ image: UIImage?) {
        if let image = image,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(imageData, forKey: profileImageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: profileImageKey)
        }
    }
    
    func loadProfileImage() -> UIImage? {
        guard let imageData = UserDefaults.standard.data(forKey: profileImageKey) else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    func clearProfileImage() {
        UserDefaults.standard.removeObject(forKey: profileImageKey)
    }
    
    // Stats
    
    @objc func updateStats() {
        // Update recipe count from Core Data
        self.recipeCount = PersistenceController.shared.fetchRecipeCount()
        
        // Update kitchen items count
        if let data = UserDefaults.standard.data(forKey: Constants.UserDefaultsKeys.kitchenItems),
           let items = try? JSONDecoder().decode([KitchenItem].self, from: data) {
            self.kitchenItemCount = items.count
        }
        
        // Update shopping list count
        if let data = UserDefaults.standard.data(forKey: Constants.UserDefaultsKeys.shoppingListItems),
           let items = try? JSONDecoder().decode([ShoppingListModel].self, from: data) {
            self.shoppingListCount = items.count
        }
    }
    
    // MARK: - Data Management
    
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

// MARK: - Chef Type Enum

enum ChefType: String, CaseIterable {
    case homeCook = "Home Cook"
    case foodie = "Foodie"
    case baker = "Baker"
    case grillMaster = "Grill Master"
    case healthNut = "Health Nut"
    case adventurousEater = "Adventurous Eater"
    
    var icon: String {
        switch self {
        case .homeCook: return "house.fill"
        case .foodie: return "heart.circle.fill"
        case .baker: return "birthday.cake.fill"
        case .grillMaster: return "flame.fill"
        case .healthNut: return "leaf.fill"
        case .adventurousEater: return "globe.americas.fill"
        }
    }
    
    var description: String {
        switch self {
        case .homeCook: return "Cooking delicious meals at home"
        case .foodie: return "Passionate about discovering great food"
        case .baker: return "Master of breads, cakes & pastries"
        case .grillMaster: return "BBQ and grilling expert"
        case .healthNut: return "Focused on nutritious & wholesome meals"
        case .adventurousEater: return "Always trying new cuisines & flavors"
        }
    }
    
    var emoji: String {
        switch self {
        case .homeCook: return "🏠"
        case .foodie: return "😋"
        case .baker: return "🧁"
        case .grillMaster: return "🔥"
        case .healthNut: return "🥗"
        case .adventurousEater: return "🌍"
        }
    }
}
