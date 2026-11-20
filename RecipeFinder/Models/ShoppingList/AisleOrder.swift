import Foundation

/// One tick in shop mode: which row, its aisle, and when.
struct ShopTick: Equatable {
    let itemID: UUID
    let category: String
    let at: Date
}

/// A shop-mode trip's ticks in order. Unticking a row drops its tick, so a mis-tap teaches nothing.
struct TripTicks: Equatable {
    private(set) var ticks: [ShopTick] = []

    /// Call before the row flips: ticking `item` (not yet checked) records it; unticking drops it.
    mutating func toggled(_ item: ShoppingListModel, at date: Date) {
        if item.isChecked {
            ticks.removeAll { $0.itemID == item.id }
        } else {
            ticks.append(ShopTick(itemID: item.id, category: item.category, at: date))
        }
    }
}

/// The order a cook walks the aisles, learned from "I'm in the shop" ticks, per shop (Privacy Policy §4.2; owner OK
/// 2026-11-20). Kept in `LocalStore` (`rf.` key → cleared by Reset, never synced) via `ShoppingListManager`.
struct AisleOrder: Codable, Equatable {
    static let storageKey = "aisleOrder"
    /// Ticks spread over less than this weren't ticked aisle by aisle (at the checkout, unpacking at home), so the
    /// trip teaches nothing.
    static let minimumTripSeconds: TimeInterval = 60
    /// Trips with no shop chosen ("In the shop") learn under this key.
    private static let anyShop = ""

    /// Per shop, each aisle's learned place on the usual order's 0 (first) … 1 (last) scale.
    private(set) var places: [String: [String: Double]]

    init(places: [String: [String: Double]] = [:]) {
        self.places = places
    }

    /// Learns from one trip: the aisles it ticked swap among the places they already hold (learned, else usual) into
    /// the order walked. Aisles the trip didn't touch keep their places, so a top-up trip through two aisles walked in
    /// the usual order changes nothing. Only the first tick in an aisle counts; a one-aisle trip, or one ticked in a
    /// rush, is ignored.
    mutating func learn(from ticks: [ShopTick], at shop: String?) {
        guard let first = ticks.first?.at, let last = ticks.last?.at,
              last.timeIntervalSince(first) >= Self.minimumTripSeconds else { return }
        learn(walked: ticks.map(\.category), at: shop)
    }

    /// The aisles in the order walked (repeats allowed), with no timing check.
    mutating func learn(walked categories: [String], at shop: String?) {
        var walked: [String] = []
        for category in categories where !walked.contains(category) { walked.append(category) }
        guard walked.count > 1 else { return }
        let key = shop ?? Self.anyShop
        var learned = places[key] ?? [:]
        let held = walked.map { learned[$0] ?? Self.usualPlace($0) }.sorted()
        for (category, place) in zip(walked, held) { learned[category] = place }
        places[key] = learned
    }

    /// `categories` (in the usual order) rearranged by this shop's learned places. An aisle never ticked here keeps
    /// its usual place among them, so a new aisle slots in rather than jumping to the end.
    func arranged(_ categories: [String], at shop: String?) -> [String] {
        guard let learned = places[shop ?? Self.anyShop], !learned.isEmpty else { return categories }
        return categories.enumerated()
            .map { (index: $0.offset, category: $0.element, place: learned[$0.element] ?? Self.usualPlace($0.element)) }
            .sorted { ($0.place, $0.index) < ($1.place, $1.index) }
            .map(\.category)
    }

    mutating func renameShop(_ shop: String, to newName: String) {
        guard let moved = places.removeValue(forKey: shop) else { return }
        places[newName] = moved
    }

    mutating func forgetShop(_ shop: String) {
        places[shop] = nil
    }

    /// Drops what was learned for shops no longer on the list (deleted or renamed on another device via iCloud).
    mutating func keepShops(_ shops: [String]) {
        places = places.filter { $0.key == Self.anyShop || shops.contains($0.key) }
    }

    /// Where an aisle sits in the usual order, on the same 0…1 scale; a category of the cook's own goes last.
    private static func usualPlace(_ category: String) -> Double {
        let order = CategoryClassifier.categoryOrder
        guard let rank = order.firstIndex(of: category), order.count > 1 else { return 1 }
        return Double(rank) / Double(order.count - 1)
    }

    // MARK: - Stored on the device

    static func load(from storage: LocalStore) -> AisleOrder {
        storage.decodable(AisleOrder.self, forKey: storageKey) ?? AisleOrder()
    }

    func save(to storage: LocalStore) {
        storage.setEncodable(self, forKey: Self.storageKey)
    }
}
