import Foundation

/// A complete, versioned snapshot of a user's library, suitable for writing to a
/// file and restoring later (or on another device). Every store the app persists
/// is `Codable`, so a backup is just the sum of them plus a schema version.
///
/// The previous export attempt failed by omitting recipes and mangling notes on
/// restore; this type includes every store explicitly and is exercised by
/// round-trip tests so that can't regress.
struct BackupArchive: Codable {
    /// Bump when the on-disk shape changes incompatibly. `BackupCodec` refuses to
    /// decode archives newer than it understands rather than silently dropping data.
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

    init(
        schemaVersion: Int = BackupArchive.currentSchemaVersion,
        exportedAt: Date = Date(),
        recipes: [RecipeModel] = [],
        shoppingList: [ShoppingListModel] = [],
        kitchenItems: [KitchenItem] = [],
        kitchenInventory: [KitchenInventoryModel] = [],
        mealPlans: [MealPlanModel] = [],
        badges: [String: Badge] = [:],
        collections: [RecipeCollection] = []
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
    }

    // `collections` was added after v1 archives were written, so old backups
    // won't have the key. Decode it optionally so restoring a pre-collections
    // backup still works rather than throwing `.corruptedData`.
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
    }
}

enum BackupError: LocalizedError, Equatable {
    /// The archive was written by a newer app version than this one understands.
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

/// Encodes/decodes `BackupArchive` to a stable, self-describing JSON representation
/// and enforces the schema-version guard on the way in.
enum BackupCodec {
    static let fileExtension = "recipefinderbackup"

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
