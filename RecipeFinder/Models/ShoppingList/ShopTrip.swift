import Foundation

/// "I'm in the shop": what's still to get, in aisle order, and what's already in the basket (ticked = bought).
struct ShopTrip: Equatable {
    static let empty = ShopTrip(items: [], store: nil)

    let toGet: [ShoppingListModel]
    let inBasket: [ShoppingListModel]
    /// Ticked one-offs, which Done moves At home (staples stay on the list for next time).
    private let goingAway: Int

    /// `store` nil = every item; otherwise items set to another store stay off the trip, as on To buy.
    init(items: [ShoppingListModel], store: String?) {
        let visible = ShoppingListGrouping.grouped(items.filter { $0.isAvailable(at: store) }).flatMap { $0.value }
        toGet = visible.filter { !$0.isChecked }
        inBasket = visible.filter { $0.isChecked }
        goingAway = ShoppingListManager.boughtToPutAway(inBasket).count
    }

    var total: Int { toGet.count + inBasket.count }
    var isDone: Bool { toGet.isEmpty && !inBasket.isEmpty }
    var progressText: String { "\(inBasket.count) of \(total) in the basket" }
    var doneTitle: String { goingAway == 0 ? "Done" : "Done · put \(goingAway) away" }

    /// "200 g", not "200" — a bare number read as 200 items.
    static func amount(_ item: ShoppingListModel) -> String {
        item.unit.isEmpty ? "\(item.quantity)" : "\(item.quantity) \(item.unit)"
    }

    /// Bought = at home: ticked one-offs move At home and leave the list; staples stay, unticked, for next time.
    /// So the plan's card doesn't ask for them again.
    @MainActor
    static func putAwayBasket(shopping: any ShoppingListManaging, kitchen: any KitchenInventoryManaging) {
        kitchen.putAway(ShoppingListManager.boughtToPutAway(shopping.items))
        shopping.clearCheckedItems()
    }
}
