import Foundation

/// Versioned snapshot of a user's library (every store is `Codable`); includes each store explicitly + round-trip tested so restore can't drop recipes/notes.
struct BackupArchive: Codable {
    /// Bump on incompatible on-disk shape changes; `BackupCodec` rejects newer archives rather than dropping data.
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var exportedAt: Date

    var recipes: [RecipeModel]
    var shoppingList: [ShoppingListModel]
    var kitchenItems: [KitchenItem]
    var kitchenInventory: [KitchenInventoryModel]
    var mealPlans: [MealPlanModel]
    var badges: [String: Badge]
    var collections: [RecipeCollection]
    /// Cook dates behind the weekly cooking streak.
    var cookDates: [Date]

    init(
        schemaVersion: Int = BackupArchive.currentSchemaVersion,
        exportedAt: Date = Date(),
        recipes: [RecipeModel] = [],
        shoppingList: [ShoppingListModel] = [],
        kitchenItems: [KitchenItem] = [],
        kitchenInventory: [KitchenInventoryModel] = [],
        mealPlans: [MealPlanModel] = [],
        badges: [String: Badge] = [:],
        collections: [RecipeCollection] = [],
        cookDates: [Date] = []
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.recipes = recipes
        self.shoppingList = shoppingList
        self.kitchenItems = kitchenItems
        self.kitchenInventory = kitchenInventory
        self.mealPlans = mealPlans
        self.badges = badges
        self.collections = collections
        self.cookDates = cookDates
    }

    // `collections` postdates v1 archives; decode optionally so pre-collections backups restore instead of throwing `.corruptedData`.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decode(Int.self, forKey: .schemaVersion)
        exportedAt = try c.decode(Date.self, forKey: .exportedAt)
        recipes = try c.decode([RecipeModel].self, forKey: .recipes)
        shoppingList = try c.decode([ShoppingListModel].self, forKey: .shoppingList)
        kitchenItems = try c.decode([KitchenItem].self, forKey: .kitchenItems)
        kitchenInventory = try c.decode([KitchenInventoryModel].self, forKey: .kitchenInventory)
        mealPlans = try c.decode([MealPlanModel].self, forKey: .mealPlans)
        badges = try c.decode([String: Badge].self, forKey: .badges)
        collections = (try? c.decodeIfPresent([RecipeCollection].self, forKey: .collections)) ?? []
        // Added after v1; older backups have no streak history.
        cookDates = (try? c.decodeIfPresent([Date].self, forKey: .cookDates)) ?? []
    }
}

enum BackupError: LocalizedError, Equatable {
    /// Archive written by a newer app version than this one understands.
    case unsupportedSchemaVersion(found: Int, supported: Int)
    case corruptedData

    var errorDescription: String? {
        switch self {
        case let .unsupportedSchemaVersion(found, supported):
            return "This backup was made with a newer version of RecipeFinder (format \(found); this app supports up to \(supported)). Update the app and try again."
        case .corruptedData:
            return "This file isn't a valid RecipeFinder backup, or it's damaged."
        }
    }
}

/// Encodes/decodes `BackupArchive` as stable JSON and enforces the schema-version guard on decode.
enum BackupCodec {
    static let fileExtension = "recipefinderbackup"

    /// "RecipeFinder-Backup-2026-11-05" (local date). Fixed Gregorian calendar + POSIX locale so the name doesn't follow
    /// the device calendar — a Buddhist-calendar device produced "2569-…".
    static func defaultFilename(for date: Date = Date()) -> String {
        "RecipeFinder-Backup-\(filenameDateFormatter.string(from: date))"
    }

    private static let filenameDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func encode(_ archive: BackupArchive) throws -> Data {
        try makeEncoder().encode(archive)
    }

    static func decode(_ data: Data) throws -> BackupArchive {
        let archive: BackupArchive
        do {
            archive = try makeDecoder().decode(BackupArchive.self, from: data)
        } catch {
            throw BackupError.corruptedData
        }
        guard archive.schemaVersion <= BackupArchive.currentSchemaVersion else {
            throw BackupError.unsupportedSchemaVersion(
                found: archive.schemaVersion,
                supported: BackupArchive.currentSchemaVersion
            )
        }
        return archive
    }
}
