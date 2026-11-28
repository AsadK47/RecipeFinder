import Foundation

/// "I'm in the shop": what's still to get, in aisle order, and what's already in the basket (ticked = bought).
/// Same-name items share one row ("Carrots · 454 g + 2 cups"), so the cook picks them up once.
struct ShopTrip: Equatable {
    static let empty = ShopTrip(items: [], store: nil)

    /// One thing to pick up: every list item with this name (case and spaces ignored), in aisle order.
    struct Row: Identifiable, Equatable {
        /// The first of `items` in list order — not tick order, so the row keeps its id and amount as it's ticked.
        let first: ShoppingListModel
        let items: [ShoppingListModel]

        init(first: ShoppingListModel, rest: [ShoppingListModel] = []) {
            self.first = first
            items = [first] + rest
        }

        var id: UUID { first.id }
        var name: String { first.name }
        var category: String { first.category }
        /// In the basket once every item in it is ticked.
        var isChecked: Bool { items.allSatisfy(\.isChecked) }
        /// Same units add up ("2 cups" + "1 cup" → "3 cups"); different ones join ("454 g + 2 cups").
        var amount: String {
            var totals: [(unit: String, key: String, quantity: Int)] = []
            for item in items {
                let key = UnitConversion.canonicalUnit(item.unit)
                if let index = totals.firstIndex(where: { $0.key == key }) {
                    totals[index].quantity += item.quantity
                } else {
                    totals.append((item.unit, key, item.quantity))
                }
            }
            return totals.map { ShopTrip.amount(quantity: $0.quantity, unit: $0.unit) }.joined(separator: " + ")
        }
        /// The items a tap flips: unticked ones when the row isn't done yet, else all of them (untick the row).
        var idsToToggle: [UUID] {
            isChecked ? items.map(\.id) : items.filter { !$0.isChecked }.map(\.id)
        }
    }

    let rows: [Row]
    let toGet: [Row]
    let inBasket: [Row]
    /// Ticked one-offs, which Done moves At home (staples stay on the list for next time); a merged row counts once.
    private let goingAway: Int
    /// Every ticked item on the trip — what Done puts away (this store's ticks only).
    let basketIDs: Set<UUID>

    /// `store` nil = every item; otherwise items set to another store stay off the trip, as on To buy. Aisles follow
    /// the order learned at this store (`aisleOrder`).
    init(items: [ShoppingListModel], store: String?, aisleOrder: AisleOrder = AisleOrder()) {
        // Aisle order by category, then name — not grouped()'s unticked-first, which moved a row as it was ticked.
        let visible = ShoppingListGrouping.grouped(items.filter { $0.isAvailable(at: store) }, aisleOrder: aisleOrder, store: store)
            .flatMap { $0.value.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending } }
        var keys: [String] = []
        var byKey: [String: [ShoppingListModel]] = [:]
        for item in visible {
            let key = Self.rowKey(item.name)
            if byKey[key] == nil { keys.append(key) }
            byKey[key, default: []].append(item)
        }
        // Within a row, list order: grouped() puts unticked first, which would flip the row's id and amount on a tick.
        let position = Dictionary(items.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { first, _ in first })
        rows = keys.compactMap { key -> Row? in
            let group = (byKey[key] ?? []).sorted { (position[$0.id] ?? 0) < (position[$1.id] ?? 0) }
            guard let first = group.first else { return nil }
            return Row(first: first, rest: Array(group.dropFirst()))
        }
        toGet = rows.filter { !$0.isChecked }
        inBasket = rows.filter { $0.isChecked }
        let ticked = visible.filter(\.isChecked)
        basketIDs = Set(ticked.map(\.id))
        goingAway = Set(ticked.filter { !$0.isRecurring }.map { Self.rowKey($0.name) }).count
    }

    var total: Int { rows.count }
    var isDone: Bool { toGet.isEmpty && !inBasket.isEmpty }
    var progressText: String { "\(inBasket.count) of \(total) in the basket" }
    var doneTitle: String { goingAway == 0 ? "Done" : "Done · put \(goingAway) away" }

    /// "200 g", not "200" — a bare number read as 200 items; "16 cloves", not "16 clove".
    static func amount(_ item: ShoppingListModel) -> String {
        amount(quantity: item.quantity, unit: item.unit)
    }

    private static func amount(quantity: Int, unit: String) -> String {
        unit.isEmpty ? "\(quantity)" : "\(quantity) \(UnitConversion.unitText(unit, quantity: quantity))"
    }

    private static func rowKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
