import Testing
import Foundation
@testable import RecipeFinder

/// Groceries writes itself slice 3: shop mode learns the order a cook ticks the aisles in (per shop), and the trip and
/// To buy list follow it; a top-up trip doesn't scramble it; a rushed or mis-tapped tick teaches nothing; Reset clears it (an `rf.` key).
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
        order.learn(walked: walked, at: nil)
        #expect(order.arranged(defaultOrder, at: nil) == walked)
    }

    @Test("Only the first tick in an aisle counts — doubling back for one thing doesn't move it")
    func firstTickPerAisleCounts() {
        var order = AisleOrder()
        order.learn(walked: [grains, dairy, grains, produce, grains], at: nil)
        #expect(order.arranged(defaultOrder, at: nil) == [grains, dairy, produce])
    }

    @Test("A trip in one aisle says nothing about order, so nothing is learned")
    func oneAisleLearnsNothing() {
        var order = AisleOrder()
        order.learn(walked: [grains, grains], at: nil)
        #expect(order == AisleOrder())
    }

    @Test("A later trip in a new order moves the aisles it touched")
    func latestTripReorders() {
        var order = AisleOrder()
        order.learn(walked: [grains, produce], at: nil)
        order.learn(walked: [produce, grains], at: nil)
        #expect(order.arranged([produce, grains], at: nil) == [produce, grains])
    }

    @Test("A top-up trip through the last aisles, in the learned order, changes nothing")
    func topUpTripKeepsTheHabit() {
        let bakery = "Bakery", frozen = "Frozen", drinks = "Beverages"
        var order = AisleOrder()
        order.learn(walked: [drinks, frozen, bakery, produce], at: nil)
        let learned = order
        order.learn(walked: [bakery, produce], at: nil)
        order.learn(walked: [bakery, produce], at: nil)
        #expect(order == learned)
        #expect(order.arranged([produce, bakery, frozen, drinks], at: nil) == [drinks, frozen, bakery, produce])
    }

    @Test("Aisles a trip learned slot in among ones never ticked, on the same scale")
    func learnedAislesSlotIn() {
        var order = AisleOrder()
        order.learn(walked: [dairy, produce], at: nil)
        #expect(order.arranged([produce, dairy, grains, "Frozen"], at: nil) == [dairy, produce, grains, "Frozen"])
    }

    // MARK: - Ticks

    private func ticks(_ categories: [String], every seconds: TimeInterval) -> [ShopTick] {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        return categories.enumerated().map {
            ShopTick(itemID: UUID(), category: $0.element, at: start.addingTimeInterval(Double($0.offset) * seconds))
        }
    }

    @Test("Ticks spread over a walk round the shop are learned")
    func walkedTripLearns() {
        var order = AisleOrder()
        order.learn(from: ticks([grains, produce], every: 90), at: nil)
        #expect(order.arranged([produce, grains], at: nil) == [grains, produce])
    }

    @Test("Ticks made in a rush (at the checkout, unpacking at home) teach nothing")
    func rushedTripLearnsNothing() {
        var order = AisleOrder()
        order.learn(from: ticks([grains, dairy, produce], every: 2), at: nil)
        #expect(order == AisleOrder())
    }

    @Test("Unticking a row drops its tick, so a mis-tap teaches nothing")
    func untickDropsTheTick() {
        let onion = ShoppingListModel(name: "Onion", category: produce)
        var ticked = onion
        ticked.isChecked = true
        let rice = ShoppingListModel(name: "Rice", category: grains)
        let now = Date()
        var trip = TripTicks()
        trip.toggled(onion, at: now)
        trip.toggled(rice, at: now)
        trip.toggled(ticked, at: now)
        #expect(trip.ticks.map(\.category) == [grains])
    }

    @Test("Each shop keeps its own order")
    func perShop() {
        var order = AisleOrder()
        order.learn(walked: [grains, produce], at: "Market")
        #expect(order.arranged([produce, grains], at: "Market") == [grains, produce])
        #expect(order.arranged([produce, grains], at: "Corner shop") == [produce, grains])
        #expect(order.arranged([produce, grains], at: nil) == [produce, grains])
    }

    @Test("Renaming a shop keeps its order; deleting it forgets it")
    func renameAndForgetShop() {
        var order = AisleOrder()
        order.learn(walked: [grains, produce], at: "Market")
        order.renameShop("Market", to: "Farmers market")
        #expect(order.arranged([produce, grains], at: "Farmers market") == [grains, produce])
        #expect(order.arranged([produce, grains], at: "Market") == [produce, grains])
        order.forgetShop("Farmers market")
        #expect(order == AisleOrder())
    }

    @Test("Shops gone from the list (deleted on another device) lose their order; no-shop trips keep theirs")
    func keepShopsDropsGoneShops() {
        var order = AisleOrder()
        order.learn(walked: [grains, produce], at: "Market")
        order.learn(walked: [grains, produce], at: nil)
        order.keepShops([])
        #expect(order.arranged([produce, grains], at: "Market") == [produce, grains])
        #expect(order.arranged([produce, grains], at: nil) == [grains, produce])
    }

    @Test("A trip follows the learned order; ticked rows stay in place")
    func tripFollowsLearnedOrder() {
        var order = AisleOrder()
        order.learn(walked: [grains, produce], at: nil)
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
        makeShopping(storage).learnAisleOrder(from: ticks([grains, produce], every: 90), store: nil)
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
        shopping.learnAisleOrder(from: ticks([grains, produce], every: 90), store: nil)
        shopping.removeAllShoppingData()
        #expect(shopping.aisleOrder == AisleOrder())
        #expect(storage.data(forKey: AisleOrder.storageKey) == nil)
    }

    @MainActor @Test("Renaming or deleting a store carries its learned order with it")
    func storeEditsCarryTheOrder() {
        let shopping = makeShopping(makeStorage())
        shopping.addStore("Market")
        shopping.learnAisleOrder(from: ticks([grains, produce], every: 90), store: "Market")
        shopping.renameStore("Market", to: "Farmers market")
        #expect(shopping.aisleOrder.arranged([produce, grains], at: "Farmers market") == [grains, produce])
        shopping.deleteStore("Farmers market")
        #expect(shopping.aisleOrder == AisleOrder())
    }
}
