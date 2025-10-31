import Foundation
import Combine

final class AccountManager: ObservableObject {
    static let shared = AccountManager()
    
    // Profile fields
    @Published private(set) var uuid: String = ""
    @Published private(set) var firstName: String = ""
    @Published private(set) var middleName: String = ""
    @Published private(set) var lastName: String = ""
    @Published private(set) var email: String = ""
    @Published private(set) var address: String = ""
    @Published private(set) var chefType: ChefType = .homeCook
    
    // Stats
    @Published private(set) var recipeCount: Int = 0
    @Published private(set) var kitchenItemCount: Int = 0
    @Published private(set) var shoppingListCount: Int = 0
    
    // UserDefaults keys
    private let uuidKey = "accountUUID"
    private let firstNameKey = "accountFirstName"
    private let middleNameKey = "accountMiddleName"
    private let lastNameKey = "accountLastName"
    private let emailKey = "accountEmail"
    private let addressKey = "accountAddress"
    private let chefTypeKey = "accountChefType"
    
    var fullName: String {
        var name = firstName
        if !middleName.isEmpty {
            name += " \(middleName)"
        }
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
    
    // MARK: - Profile Management
    
    func loadProfile() {
        // Load or generate UUID
        if let savedUUID = UserDefaults.standard.string(forKey: uuidKey) {
            uuid = savedUUID
        } else {
            uuid = UUID().uuidString
            UserDefaults.standard.set(uuid, forKey: uuidKey)
        }
        
        firstName = UserDefaults.standard.string(forKey: firstNameKey) ?? ""
        middleName = UserDefaults.standard.string(forKey: middleNameKey) ?? ""
        lastName = UserDefaults.standard.string(forKey: lastNameKey) ?? ""
        email = UserDefaults.standard.string(forKey: emailKey) ?? ""
        address = UserDefaults.standard.string(forKey: addressKey) ?? ""
        
        if let chefTypeRaw = UserDefaults.standard.string(forKey: chefTypeKey),
           let savedChefType = ChefType(rawValue: chefTypeRaw) {
            chefType = savedChefType
        }
    }
    
    func updateProfile(
        firstName: String,
        middleName: String,
        lastName: String,
        email: String,
        address: String,
        chefType: ChefType
    ) {
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMiddleName = middleName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        self.firstName = trimmedFirstName
        self.middleName = trimmedMiddleName
        self.lastName = trimmedLastName
        self.email = trimmedEmail
        self.address = trimmedAddress
        self.chefType = chefType
        
        UserDefaults.standard.set(trimmedFirstName, forKey: firstNameKey)
        UserDefaults.standard.set(trimmedMiddleName, forKey: middleNameKey)
        UserDefaults.standard.set(trimmedLastName, forKey: lastNameKey)
        UserDefaults.standard.set(trimmedEmail, forKey: emailKey)
        UserDefaults.standard.set(trimmedAddress, forKey: addressKey)
        UserDefaults.standard.set(chefType.rawValue, forKey: chefTypeKey)
        
        HapticManager.shared.success()
    }
    
    // MARK: - Stats
    
    @objc func updateStats() {
        // Ensure UI updates happen on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update recipe count from Core Data
            self.recipeCount = PersistenceController.shared.fetchRecipeCount()
            
            // Update kitchen items count
            if let data = UserDefaults.standard.data(forKey: Constants.UserDefaultsKeys.kitchenItems),
               let items = try? JSONDecoder().decode([KitchenItem].self, from: data) {
                self.kitchenItemCount = items.count
            }
            
            // Update shopping list count
            if let data = UserDefaults.standard.data(forKey: Constants.UserDefaultsKeys.shoppingListItems),
               let items = try? JSONDecoder().decode([ShoppingListItem].self, from: data) {
                self.shoppingListCount = items.count
            }
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

// MARK: - Chef Type Enum

enum ChefType: String, CaseIterable {
    case homeCook = "Home Cook"
    case aspiring = "Aspiring Chef"
    case hobbyist = "Hobbyist"
    case professional = "Professional Chef"
    case baker = "Baker"
    case grillMaster = "Grill Master"
    case sousChef = "Sous Chef"
    case executiveChef = "Executive Chef"
    case pastryChef = "Pastry Chef"
    case foodEnthusiast = "Food Enthusiast"
    
    var icon: String {
        switch self {
        case .homeCook: return "house.fill"
        case .aspiring: return "star.fill"
        case .hobbyist: return "heart.fill"
        case .professional: return "chef.hat"
        case .baker: return "birthday.cake.fill"
        case .grillMaster: return "flame.fill"
        case .sousChef: return "person.2.fill"
        case .executiveChef: return "crown.fill"
        case .pastryChef: return "gift.fill"
        case .foodEnthusiast: return "fork.knife"
        }
    }
    
    var description: String {
        switch self {
        case .homeCook: return "Cooking delicious meals at home"
        case .aspiring: return "Learning and growing every day"
        case .hobbyist: return "Cooking for fun and passion"
        case .professional: return "Expert culinary professional"
        case .baker: return "Master of breads and pastries"
        case .grillMaster: return "BBQ and grilling expert"
        case .sousChef: return "Second-in-command in the kitchen"
        case .executiveChef: return "Leading the culinary team"
        case .pastryChef: return "Specialist in desserts and sweets"
        case .foodEnthusiast: return "Passionate about all things food"
        }
    }
}
