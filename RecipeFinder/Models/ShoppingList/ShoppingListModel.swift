import Foundation

struct ShoppingListModel: Identifiable, Codable, Hashable {
    // Synthesized (all-field) Equatable/Hashable on purpose: id-only equality made SwiftUI treat a checked or re-quantified
    // item as unchanged, so its row never redrew. Look items up by `id` explicitly instead.
    var id: UUID = UUID()
    var name: String
    var quantity: Int
    var unit: String
    var isChecked: Bool = false
    var isCompleted: Bool = false
    var category: String
    var dateAdded: Date
    /// Stores this item is bought at; empty means "anywhere", so it shows under every store filter.
    var stores: [String] = []
    var isRecurring: Bool = false

    init(id: UUID = UUID(), name: String, isChecked: Bool = false, quantity: Int = 1, unit: String = "", category: String = "Other", dateAdded: Date = Date(), stores: [String] = [], isRecurring: Bool = false) {
        self.id = id
        self.name = name
        self.isChecked = isChecked
        self.isCompleted = isChecked
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.dateAdded = dateAdded
        self.stores = stores
        self.isRecurring = isRecurring
    }

    /// Keys only older builds wrote; read once to migrate, never encoded.
    private enum LegacyKeys: String, CodingKey {
        case preferredStore
    }

    // Custom decoder so JSON predating isRecurring/isCompleted/stores decodes with safe defaults instead of throwing .keyNotFound.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(UUID.self,   forKey: .id)
        name           = try c.decode(String.self, forKey: .name)
        quantity       = try c.decode(Int.self,    forKey: .quantity)
        unit           = try c.decode(String.self, forKey: .unit)
        isChecked      = try c.decode(Bool.self,   forKey: .isChecked)
        isCompleted    = (try? c.decodeIfPresent(Bool.self, forKey: .isCompleted)) ?? isChecked
        category       = try c.decode(String.self, forKey: .category)
        dateAdded      = try c.decode(Date.self,   forKey: .dateAdded)
        if let decodedStores = try? c.decodeIfPresent([String].self, forKey: .stores) {
            stores = decodedStores
        } else if let legacy = try? decoder.container(keyedBy: LegacyKeys.self).decodeIfPresent(String.self, forKey: .preferredStore) {
            // Older builds tagged at most one store per item.
            stores = [legacy]
        } else {
            stores = []
        }
        isRecurring    = (try? c.decodeIfPresent(Bool.self, forKey: .isRecurring)) ?? false
    }
}

extension ShoppingListModel {
    /// Whether the item belongs on the list while shopping at `store`; `nil` means every store ("All").
    /// Untagged items can be bought anywhere, so they show under every store.
    func isAvailable(at store: String?) -> Bool {
        guard let store else { return true }
        return stores.isEmpty || stores.contains(store)
    }
}

/// Rules for the user's own list of grocery stores.
enum GroceryStoreNames {
    /// The trimmed name to save, or nil when it's blank or already in `existing` (ignoring case).
    static func validated(_ raw: String, existing: [String]) -> String? {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let taken = existing.contains { $0.caseInsensitiveCompare(name) == .orderedSame }
        return taken ? nil : name
    }
}
