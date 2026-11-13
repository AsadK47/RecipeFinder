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

    static let uuidKey = "profileUUID"
    static let firstNameKey = "profileFirstName"
    static let lastNameKey = "profileLastName"
    static let chefTypeKey = "profileChefType"
    static let profileImageKey = "profileProfileImage"
    static let createdDateKey = "profileCreatedDate"

    /// The profile lives in a `ProfileEntity` row; the old `LocalStore` keys are kept current for one release.
    @ObservationIgnored private let mirror: MirroredSnapshot<ProfileRecord>
    @ObservationIgnored private var record = ProfileRecord(uuid: "")
    /// The photo as last handed out, so Me saving back the image it just loaded (its `onChange`) writes nothing —
    /// a re-encode would rewrite the photo, and lose quality, on every visit.
    @ObservationIgnored private var loadedImage: UIImage?

    var fullName: String {
        ProfileNameFormatter.displayName(firstName: firstName, lastName: lastName)
    }

    var initials: String {
        ProfileNameFormatter.initials(firstName: firstName, lastName: lastName)
    }

    private convenience init() {
        self.init(storage: .shared, profileStore: CoreDataProfileStore(persistence: .shared))
        updateStats()
        unlockWelcomeBadge()
    }

    init(storage: LocalStore, profileStore: any ProfileStoring) {
        self.mirror = MirroredSnapshot(
            blobKey: Self.uuidKey,
            storage: storage,
            readBlob: { Self.readKeptCopy(from: storage) },
            writeBlob: { Self.writeKeptCopy($0.first, to: storage) },
            removeBlob: { Self.writeKeptCopy(nil, to: storage) },
            fetch: { try profileStore.fetchProfile().map { [$0] } ?? [] },
            replace: { try profileStore.replaceProfile(with: $0.first) },
            // One profile per cook: every device's row is the same row, whatever its uuid.
            sync: .iCloudRules(storage: storage) { _ in "profile" }
        )
        loadProfile()
    }

    private func unlockWelcomeBadge() {
        if !BadgeManager.shared.isBadgeUnlocked(BadgeType.welcomeAboard.rawValue) {
            BadgeManager.shared.unlockBadge(.welcomeAboard, customDate: record.createdDate ?? Date())

            if record.createdDate == nil {
                record.createdDate = Date()
                mirror.save([record])
            }
        }
    }

    func loadProfile() {
        loadedImage = nil
        if let saved = mirror.load().first {
            record = saved
        } else {
            record = ProfileRecord(uuid: UUID().uuidString)
            mirror.save([record])
        }
        uuid = record.uuid
        firstName = record.firstName
        lastName = record.lastName
        // Default when unset so a reload after Reset doesn't keep the previous in-memory chef type.
        chefType = record.chefType.flatMap(ChefType.init(rawValue:)) ?? .homeCook
    }

    /// Erase & Reset: removes the name, chef type and photo, then starts a fresh profile. If the store can't delete
    /// now, the next launch finishes it.
    func removeProfile() {
        mirror.removeAll()
        loadProfile()
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

        record.firstName = trimmedFirstName
        record.lastName = trimmedLastName
        record.chefType = chefType.rawValue
        mirror.save([record])

        HapticManager.shared.success()
    }

    func saveProfileImage(_ image: UIImage?) {
        guard image == nil || image !== loadedImage else { return }
        loadedImage = image
        record.imageData = image?.jpegData(compressionQuality: AppTheme.jpegCompressionQuality)
        mirror.save([record])
    }

    func loadProfileImage() -> UIImage? {
        if loadedImage == nil {
            loadedImage = record.imageData.flatMap(UIImage.init(data:))
        }
        return loadedImage
    }

    func clearProfileImage() {
        saveProfileImage(nil)
    }

    func updateStats() {
        self.recipeCount = PersistenceController.shared.fetchRecipeCount()
        self.kitchenItemCount = KitchenInventoryManager.shared.items.count
        self.shoppingListCount = ShoppingListManager.shared.items.count
    }

    /// The old shape: one `LocalStore` key per field. Nil when there's no uuid — every older build wrote it first, so
    /// without it there's no kept profile and the store's stands.
    private static func readKeptCopy(from storage: LocalStore) -> [ProfileRecord]? {
        guard let uuid = storage.string(forKey: uuidKey) else { return nil }
        return [ProfileRecord(
            uuid: uuid,
            firstName: storage.string(forKey: firstNameKey) ?? "",
            lastName: storage.string(forKey: lastNameKey) ?? "",
            chefType: storage.string(forKey: chefTypeKey),
            createdDate: storage.object(forKey: createdDateKey) as? Date,
            imageData: storage.data(forKey: profileImageKey)
        )]
    }

    /// Nil removes every key.
    private static func writeKeptCopy(_ record: ProfileRecord?, to storage: LocalStore) {
        storage.set(record?.uuid, forKey: uuidKey)
        storage.set(record?.firstName, forKey: firstNameKey)
        storage.set(record?.lastName, forKey: lastNameKey)
        storage.set(record?.chefType, forKey: chefTypeKey)
        storage.set(record?.createdDate, forKey: createdDateKey)
        storage.set(record?.imageData, forKey: profileImageKey)
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
