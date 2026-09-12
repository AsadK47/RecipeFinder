import Foundation
import UIKit
import Combine

private let logger = AppLogger.logger(category: "Account")

@MainActor
final class AccountManager: ObservableObject {
    static let shared = AccountManager()
    
    @Published private(set) var uuid: String = ""
    @Published private(set) var firstName: String = ""
    @Published private(set) var lastName: String = ""
    @Published private(set) var chefType: ChefType = .homeCook
    
    @Published private(set) var recipeCount: Int = 0
    @Published private(set) var kitchenItemCount: Int = 0
    @Published private(set) var shoppingListCount: Int = 0
    
    private let uuidKey = "accountUUID"
    private let firstNameKey = "accountFirstName"
    private let lastNameKey = "accountLastName"
    private let chefTypeKey = "accountChefType"
    private let profileImageKey = "accountProfileImage"
    
    var fullName: String {
        AccountNameFormatter.displayName(firstName: firstName, lastName: lastName)
    }

    var initials: String {
        AccountNameFormatter.initials(firstName: firstName, lastName: lastName)
    }
    
    private init() {
        loadProfile()
        updateStats()
        
        unlockWelcomeBadge()
    }
    
    private func unlockWelcomeBadge() {
        if !BadgeManager.shared.isBadgeUnlocked(BadgeType.welcomeAboard.rawValue) {
            let signupDate = UserScopedStorage.shared.object(forKey: "accountCreationDate") as? Date ?? Date()
            BadgeManager.shared.unlockBadge(.welcomeAboard, customDate: signupDate)
            
            if UserScopedStorage.shared.object(forKey: "accountCreationDate") == nil {
                UserScopedStorage.shared.set(Date(), forKey: "accountCreationDate")
            }
        }
    }
    
    func loadProfile() {
        guard UserScopedStorage.shared.currentUserId != nil else {
            uuid = ""
            firstName = ""
            lastName = ""
            chefType = .homeCook
            return
        }
        
        if let savedUUID = UserScopedStorage.shared.string(forKey: uuidKey) {
            uuid = savedUUID
        } else {
            uuid = UUID().uuidString
            UserScopedStorage.shared.set(uuid, forKey: uuidKey)
        }
        
        firstName = UserScopedStorage.shared.string(forKey: firstNameKey) ?? ""
        lastName = UserScopedStorage.shared.string(forKey: lastNameKey) ?? ""
        
        if let chefTypeRaw = UserScopedStorage.shared.string(forKey: chefTypeKey),
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
        
        UserScopedStorage.shared.set(trimmedFirstName, forKey: firstNameKey)
        UserScopedStorage.shared.set(trimmedLastName, forKey: lastNameKey)
        UserScopedStorage.shared.set(chefType.rawValue, forKey: chefTypeKey)
        
        HapticManager.shared.success()
    }
    
    func saveProfileImage(_ image: UIImage?) {
        if let image = image,
           let imageData = image.jpegData(compressionQuality: AppTheme.jpegCompressionQuality) {
            UserScopedStorage.shared.set(imageData, forKey: profileImageKey)
        } else {
            UserScopedStorage.shared.removeObject(forKey: profileImageKey)
        }
    }
    
    func loadProfileImage() -> UIImage? {
        guard let imageData = UserScopedStorage.shared.data(forKey: profileImageKey) else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    func clearProfileImage() {
        UserScopedStorage.shared.removeObject(forKey: profileImageKey)
    }
    
    func updateStats() {
        self.recipeCount = PersistenceController.shared.fetchRecipeCount()
        self.kitchenItemCount = KitchenInventoryManager.shared.items.count
        self.shoppingListCount = ShoppingListManager.shared.items.count
    }
    
    func clearAllData() {
        let keysToRemove = [
            Constants.UserDefaultsKeys.kitchenItems,
            Constants.UserDefaultsKeys.shoppingListItems,
            Constants.UserDefaultsKeys.hasPopulatedDatabase
        ]
        
        for key in keysToRemove {
            UserScopedStorage.shared.removeObject(forKey: key)
        }
        
        PersistenceController.shared.clearAllRecipes()
        
        clearProfileData()
        
        logger.debug("🗑️ All user data cleared")

        updateStats()
    }
    
    func clearProfileData() {
        UserScopedStorage.shared.removeObject(forKey: firstNameKey)
        UserScopedStorage.shared.removeObject(forKey: lastNameKey)
        UserScopedStorage.shared.removeObject(forKey: chefTypeKey)
        UserScopedStorage.shared.removeObject(forKey: profileImageKey)
        UserScopedStorage.shared.removeObject(forKey: uuidKey)
        
        firstName = ""
        lastName = ""
        chefType = .homeCook
        uuid = ""
        
        logger.debug("🗑️ Profile data cleared")
    }
    
    func resetToDefaults() {
        clearAllData()
        
        PersistenceController.shared.populateDatabase()
        UserScopedStorage.shared.set(true, forKey: Constants.UserDefaultsKeys.hasPopulatedDatabase)
        
        HapticManager.shared.success()
        logger.debug("🔄 Reset to defaults complete")
    }
}

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
