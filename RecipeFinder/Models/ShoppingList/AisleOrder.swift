import Foundation

/// The order a cook walks the aisles, learned from "I'm in the shop" ticks, per shop (Privacy Policy §4.2; owner OK
/// 2026-11-20). Kept in `LocalStore` (`rf.` key → cleared by Reset, never synced) via `ShoppingListManager`.
struct AisleOrder: Codable, Equatable {
    static let storageKey = "aisleOrder"
    /// How far one trip moves a learned place: one odd trip (a detour, a closed aisle) doesn't undo a habit, two do.
    static let learningRate = 0.4
    /// Trips with no shop chosen ("In the shop") learn under this key.
    private static let anyShop = ""

    /// Per shop, each aisle's learned place from 0 (walked first) to 1 (walked last).
    private(set) var places: [String: [String: Double]]

    init(places: [String: [String: Double]] = [:]) {
        self.places = places
    }

    /// Learns from one trip's ticks in the order they happened. Only the first tick in an aisle counts (doubling back
    /// for one thing doesn't move it); a trip through one aisle says nothing about order, so it's ignored.
    mutating func learn(ticked categories: [String], at shop: String?) {
        var walked: [String] = []
        for category in categories where !walked.contains(category) { walked.append(category) }
        guard walked.count > 1 else { return }
        let key = shop ?? Self.anyShop
        var learned = places[key] ?? [:]
        let last = Double(walked.count - 1)
        for (index, category) in walked.enumerated() {
            let place = Double(index) / last
            learned[category] = learned[category].map { $0 + (place - $0) * Self.learningRate } ?? place
        }
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
