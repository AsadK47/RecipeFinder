import SwiftUI
import UIKit

/// Behavioural seam so views depend on this protocol, not the `ProfileManager` singleton, and tests can inject a fake.
@MainActor
protocol ProfileManaging: AnyObject, Observable {
    var firstName: String { get }
    var lastName: String { get }
    var chefType: ChefType { get }
    var fullName: String { get }
    var initials: String { get }
    func loadProfileImage() -> UIImage?
    func saveProfileImage(_ image: UIImage?)
    func updateProfile(firstName: String, lastName: String, chefType: ChefType)
}

private struct ProfileManagingKey: EnvironmentKey {
    // SwiftUI reads environment defaults on the main actor, so assuming main-actor isolation is safe.
    static var defaultValue: any ProfileManaging {
        MainActor.assumeIsolated { ProfileManager.shared }
    }
}

extension EnvironmentValues {
    /// Injected local profile; defaults to the shared singleton, override with `.environment(\.profile, fake)` in tests/previews.
    var profile: any ProfileManaging {
        get { self[ProfileManagingKey.self] }
        set { self[ProfileManagingKey.self] = newValue }
    }
}

@MainActor
@Observable
final class ProfileManager: ProfileManaging {
    static let shared = ProfileManager()

    private(set) var uuid: String = ""
    private(set) var firstName: String = ""
    private(set) var lastName: String = ""
    private(set) var chefType: ChefType = .homeCook

    private(set) var recipeCount: Int = 0
    private(set) var kitchenItemCount: Int = 0
    private(set) var shoppingListCount: Int = 0

    @ObservationIgnored private let uuidKey = "profileUUID"
    @ObservationIgnored private let firstNameKey = "profileFirstName"
    @ObservationIgnored private let lastNameKey = "profileLastName"
    @ObservationIgnored private let chefTypeKey = "profileChefType"
    @ObservationIgnored private let profileImageKey = "profileProfileImage"
    
    var fullName: String {
        ProfileNameFormatter.displayName(firstName: firstName, lastName: lastName)
    }

    var initials: String {
        ProfileNameFormatter.initials(firstName: firstName, lastName: lastName)
    }
    
    private init() {
        loadProfile()
        updateStats()
        
        unlockWelcomeBadge()
    }
    
    private func unlockWelcomeBadge() {
        if !BadgeManager.shared.isBadgeUnlocked(BadgeType.welcomeAboard.rawValue) {
            let joinedDate = LocalStore.shared.object(forKey: "profileCreatedDate") as? Date ?? Date()
            BadgeManager.shared.unlockBadge(.welcomeAboard, customDate: joinedDate)
            
            if LocalStore.shared.object(forKey: "profileCreatedDate") == nil {
                LocalStore.shared.set(Date(), forKey: "profileCreatedDate")
            }
        }
    }
    
    func loadProfile() {
        if let savedUUID = LocalStore.shared.string(forKey: uuidKey) {
            uuid = savedUUID
        } else {
            uuid = UUID().uuidString
            LocalStore.shared.set(uuid, forKey: uuidKey)
        }
        
        firstName = LocalStore.shared.string(forKey: firstNameKey) ?? ""
        lastName = LocalStore.shared.string(forKey: lastNameKey) ?? ""
        
        // Default when unset so a reload after Reset doesn't keep the previous in-memory chef type.
        chefType = LocalStore.shared.string(forKey: chefTypeKey).flatMap(ChefType.init(rawValue:)) ?? .homeCook
    }
    
    func updateProfile(
        firstName: String,
        lastName: String,
        chefType: ChefType
    ) {
        let trimmedFirstName = firstName.trimmed
        let trimmedLastName = lastName.trimmed
        
        self.firstName = trimmedFirstName
        self.lastName = trimmedLastName
        self.chefType = chefType
        
        LocalStore.shared.set(trimmedFirstName, forKey: firstNameKey)
        LocalStore.shared.set(trimmedLastName, forKey: lastNameKey)
        LocalStore.shared.set(chefType.rawValue, forKey: chefTypeKey)
        
        HapticManager.shared.success()
    }
    
    func saveProfileImage(_ image: UIImage?) {
        if let image = image,
           let imageData = image.jpegData(compressionQuality: AppTheme.jpegCompressionQuality) {
            LocalStore.shared.set(imageData, forKey: profileImageKey)
        } else {
            LocalStore.shared.removeObject(forKey: profileImageKey)
        }
    }
    
    func loadProfileImage() -> UIImage? {
        guard let imageData = LocalStore.shared.data(forKey: profileImageKey) else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    func clearProfileImage() {
        LocalStore.shared.removeObject(forKey: profileImageKey)
    }
    
    func updateStats() {
        self.recipeCount = PersistenceController.shared.fetchRecipeCount()
        self.kitchenItemCount = KitchenInventoryManager.shared.items.count
        self.shoppingListCount = ShoppingListManager.shared.items.count
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
