import Foundation

/// "I'm in the shop": what's still to get, in aisle order, and what's already in the basket (ticked = bought).
struct ShopTrip: Equatable {
    static let empty = ShopTrip(items: [], store: nil)

    let toGet: [ShoppingListModel]
    let inBasket: [ShoppingListModel]
    private let order: [ShoppingListModel]
    /// Ticked one-offs, which Done moves At home (staples stay on the list for next time).
    private let goingAway: Int

    /// `store` nil = every item; otherwise items set to another store stay off the trip, as on To buy. Aisles follow
    /// the order learned at this store (`aisleOrder`).
    init(items: [ShoppingListModel], store: String?, aisleOrder: AisleOrder = AisleOrder()) {
        // Aisle order by category, then name — not grouped()'s unticked-first, which moved a row as it was ticked.
        let visible = ShoppingListGrouping.grouped(items.filter { $0.isAvailable(at: store) }, aisleOrder: aisleOrder, store: store)
            .flatMap { $0.value.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending } }
        order = visible
        toGet = visible.filter { !$0.isChecked }
        inBasket = visible.filter { $0.isChecked }
        goingAway = inBasket.filter { !$0.isRecurring }.count
    }

    var total: Int { toGet.count + inBasket.count }
    var isDone: Bool { toGet.isEmpty && !inBasket.isEmpty }
    var progressText: String { "\(inBasket.count) of \(total) in the basket" }
    var doneTitle: String { goingAway == 0 ? "Done" : "Done · put \(goingAway) away" }

    /// "200 g", not "200" — a bare number read as 200 items.
    static func amount(_ item: ShoppingListModel) -> String {
        item.unit.isEmpty ? "\(item.quantity)" : "\(item.quantity) \(item.unit)"
    }

    /// The basket's ids — what Done puts away (this store's ticks only).
    var basketIDs: Set<UUID> { Set(inBasket.map { $0.id }) }

    /// Rows in aisle order with ticked ones left where they were, so a row never slides under the thumb.
    var rows: [ShoppingListModel] { order }
}
