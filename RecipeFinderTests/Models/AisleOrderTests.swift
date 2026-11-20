import Testing
import Foundation
@testable import RecipeFinder

/// Groceries writes itself slice 3: shop mode learns the order a cook ticks the aisles in (per shop), and the trip and
/// To buy list follow it; one odd trip doesn't scramble it; Reset clears it (an `rf.` key).
@Suite("AisleOrder")
struct AisleOrderTests {
    private let produce = "Produce"
    private let dairy = "Dairy & Eggs"
    private let grains = "Grains & Pasta"

    /// The default (unlearned) order of these three aisles, so tests don't hard-code `CategoryClassifier`'s list.
    private var defaultOrder: [String] {
        CategoryClassifier.categoryOrder.filter { [produce, dairy, grains].contains($0) }
    }

    @Test("Nothing learned keeps the usual aisle order")
    func nothingLearnedKeepsDefault() {
        #expect(AisleOrder().arranged(defaultOrder, at: nil) == defaultOrder)
    }

    @Test("After a trip, the aisles come in the order they were ticked")
    func followsTickOrder() {
        var order = AisleOrder()
        let walked = Array(defaultOrder.reversed())
        order.learn(ticked: walked, at: nil)
        #expect(order.arranged(defaultOrder, at: nil) == walked)
    }

    @Test("Only the first tick in an aisle counts — doubling back for one thing doesn't move it")
    func firstTickPerAisleCounts() {
        var order = AisleOrder()
        order.learn(ticked: [grains, dairy, grains, produce, grains], at: nil)
        #expect(order.arranged(defaultOrder, at: nil) == [grains, dairy, produce])
    }

    @Test("A trip in one aisle says nothing about order, so nothing is learned")
    func oneAisleLearnsNothing() {
        var order = AisleOrder()
        order.learn(ticked: [grains, grains], at: nil)
        #expect(order == AisleOrder())
    }

    @Test("One odd trip doesn't undo a habit; a second one does")
    func oneOddTripDoesNotFlip() {
        var order = AisleOrder()
        order.learn(ticked: [grains, produce], at: nil)
        order.learn(ticked: [grains, produce], at: nil)
        order.learn(ticked: [produce, grains], at: nil)
        #expect(order.arranged([produce, grains], at: nil) == [grains, produce])
        order.learn(ticked: [produce, grains], at: nil)
        #expect(order.arranged([produce, grains], at: nil) == [produce, grains])
    }

    @Test("Each shop keeps its own order")
    func perShop() {
        var order = AisleOrder()
        order.learn(ticked: [grains, produce], at: "Market")
        #expect(order.arranged([produce, grains], at: "Market") == [grains, produce])
        #expect(order.arranged([produce, grains], at: "Corner shop") == [produce, grains])
        #expect(order.arranged([produce, grains], at: nil) == [produce, grains])
    }

    @Test("Renaming a shop keeps its order; deleting it forgets it")
    func renameAndForgetShop() {
        var order = AisleOrder()
        order.learn(ticked: [grains, produce], at: "Market")
        order.renameShop("Market", to: "Farmers market")
        #expect(order.arranged([produce, grains], at: "Farmers market") == [grains, produce])
        #expect(order.arranged([produce, grains], at: "Market") == [produce, grains])
        order.forgetShop("Farmers market")
        #expect(order == AisleOrder())
    }

    @Test("A trip follows the learned order; ticked rows stay in place")
    func tripFollowsLearnedOrder() {
        var order = AisleOrder()
        order.learn(ticked: [grains, produce], at: nil)
        let items = [ShoppingListModel(name: "Onion", category: produce),
                     ShoppingListModel(name: "Rice", isChecked: true, category: grains)]
        #expect(ShopTrip(items: items, store: nil, aisleOrder: order).rows.map(\.name) == ["Rice", "Onion"])
        #expect(ShopTrip(items: items, store: nil).rows.map(\.name) == ["Onion", "Rice"])
    }

    // MARK: - Stored on the device

    private func makeStorage() -> LocalStore {
        LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
    }

    @MainActor private func makeShopping(_ storage: LocalStore) -> ShoppingListManager {
        ShoppingListManager(storage: storage, shoppingListStore: InMemoryShoppingListStore())
    }

    @MainActor @Test("A learned order survives a relaunch and leads To buy")
    func learnedOrderPersists() {
        let storage = makeStorage()
        makeShopping(storage).learnAisleOrder(ticked: [grains, produce], store: nil)
        let relaunched = makeShopping(storage)
        relaunched.addItem(name: "Onion", quantity: 1, unit: "", category: produce)
        relaunched.addItem(name: "Rice", quantity: 1, unit: "", category: grains)
        let aisles = ShoppingListGrouping.grouped(relaunched.items, aisleOrder: relaunched.aisleOrder, store: nil)
        #expect(aisles.map(\.key) == [grains, produce])
    }

    @MainActor @Test("Reset forgets the learned order")
    func resetForgets() {
        let storage = makeStorage()
        let shopping = makeShopping(storage)
        shopping.learnAisleOrder(ticked: [grains, produce], store: nil)
        shopping.removeAllShoppingData()
        #expect(shopping.aisleOrder == AisleOrder())
        #expect(storage.data(forKey: AisleOrder.storageKey) == nil)
    }

    @MainActor @Test("Renaming or deleting a store carries its learned order with it")
    func storeEditsCarryTheOrder() {
        let shopping = makeShopping(makeStorage())
        shopping.addStore("Market")
        shopping.learnAisleOrder(ticked: [grains, produce], store: "Market")
        shopping.renameStore("Market", to: "Farmers market")
        #expect(shopping.aisleOrder.arranged([produce, grains], at: "Farmers market") == [grains, produce])
        shopping.deleteStore("Farmers market")
        #expect(shopping.aisleOrder == AisleOrder())
    }
}
