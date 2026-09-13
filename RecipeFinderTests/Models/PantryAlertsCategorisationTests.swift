import Testing
import Foundation
@testable import RecipeFinder

/// Tests the categorisation and de-duplication logic used by PantryAlertsSectionContent.
///
/// The view computes three buckets:
///   expired      = items where isExpired
///   expiringSoon = items where isExpiringSoon
///   lowStockOnly = items where needsRestock && !isExpired && !isExpiringSoon
///
/// The critical property under test is that no item appears in more than one bucket.
@Suite("PantryAlertsCategorisation")
struct PantryAlertsCategorisationTests {

    // MARK: - Helpers

    private func makeItem(
        name: String = "Item",
        daysUntilExpiry: Int? = nil,
        quantity: Double = 5,
        minimumQuantity: Double? = nil,
        isLowStock: Bool = false
    ) -> KitchenInventoryModel {
        let expiry: Date? = daysUntilExpiry.map {
            Calendar.current.date(byAdding: .day, value: $0, to: Date())!
        }
        return KitchenInventoryModel(
            name: name,
            category: .produce,
            quantity: quantity,
            unit: "pcs",
            expiryDate: expiry,
            isLowStock: isLowStock,
            minimumQuantity: minimumQuantity
        )
    }

    // Mirrors PantryAlertsSectionContent.lowStockOnly
    private func lowStockOnly(from items: [KitchenInventoryModel]) -> [KitchenInventoryModel] {
        items.filter { $0.needsRestock && !$0.isExpired && !$0.isExpiringSoon }
    }

    // MARK: - isExpired

    @Test("item with past expiry is expired")
    func expiredItem() {
        let item = makeItem(daysUntilExpiry: -1)
        #expect(item.isExpired)
        #expect(!item.isExpiringSoon)
    }

    @Test("item with no expiry date is never expired or expiring soon")
    func noExpiryDate() {
        let item = makeItem(daysUntilExpiry: nil)
        #expect(!item.isExpired)
        #expect(!item.isExpiringSoon)
    }

    // MARK: - isExpiringSoon boundary

    @Test("expiringSoon boundary: 0, 1, 2, 3 days are soon; 4+ are not",
         arguments: [(0, true), (1, true), (2, true), (3, true), (4, false), (10, false)])
    func expiringSoonBoundary(days: Int, expectedSoon: Bool) {
        let item = makeItem(daysUntilExpiry: days)
        #expect(item.isExpiringSoon == expectedSoon)
        #expect(!item.isExpired)
    }

    // MARK: - De-duplication

    @Test("expired item that also needs restock is excluded from lowStockOnly")
    func expiredAndLowStockIsNotInLowStockOnly() {
        // expired AND below minimum quantity
        let item = makeItem(daysUntilExpiry: -2, quantity: 1, minimumQuantity: 3)
        #expect(item.isExpired)
        #expect(item.needsRestock)
        #expect(lowStockOnly(from: [item]).isEmpty)
    }

    @Test("expiring-soon item that also needs restock is excluded from lowStockOnly")
    func expiringSoonAndLowStockIsNotInLowStockOnly() {
        let item = makeItem(daysUntilExpiry: 2, quantity: 1, minimumQuantity: 3)
        #expect(item.isExpiringSoon)
        #expect(item.needsRestock)
        #expect(lowStockOnly(from: [item]).isEmpty)
    }

    @Test("item that only needs restock (not expired, not expiring soon) appears in lowStockOnly")
    func pureLowStockAppearsInLowStockOnly() {
        let item = makeItem(daysUntilExpiry: 30, quantity: 1, minimumQuantity: 3)
        #expect(!item.isExpired)
        #expect(!item.isExpiringSoon)
        #expect(item.needsRestock)
        #expect(lowStockOnly(from: [item]).count == 1)
    }

    @Test("item without expiry that needs restock appears in lowStockOnly")
    func noExpiryLowStockAppearsInLowStockOnly() {
        let item = makeItem(daysUntilExpiry: nil, quantity: 0, minimumQuantity: 2)
        #expect(!item.isExpired)
        #expect(!item.isExpiringSoon)
        #expect(item.needsRestock)
        #expect(lowStockOnly(from: [item]).count == 1)
    }

    @Test("mixed inventory: each item appears in exactly one bucket")
    func noDuplicatesAcrossBuckets() {
        let expired     = makeItem(name: "Milk",   daysUntilExpiry: -1, quantity: 1, minimumQuantity: 3)
        let soonAndLow  = makeItem(name: "Cheese", daysUntilExpiry: 1,  quantity: 1, minimumQuantity: 3)
        let justLow     = makeItem(name: "Eggs",   daysUntilExpiry: 30, quantity: 1, minimumQuantity: 3)
        let fine        = makeItem(name: "Butter", daysUntilExpiry: 14, quantity: 5)

        let items = [expired, soonAndLow, justLow, fine]

        let expiredBucket     = items.filter { $0.isExpired }
        let expiringSoonBucket = items.filter { $0.isExpiringSoon }
        let lowBucket         = lowStockOnly(from: items)

        // Correct assignment
        #expect(expiredBucket.map(\.name) == ["Milk"])
        #expect(expiringSoonBucket.map(\.name) == ["Cheese"])
        #expect(lowBucket.map(\.name) == ["Eggs"])

        // No item appears in multiple buckets
        let allBucketIDs = expiredBucket.map(\.id)
            + expiringSoonBucket.map(\.id)
            + lowBucket.map(\.id)
        #expect(Set(allBucketIDs).count == allBucketIDs.count)

        // Fine item appears in no bucket
        #expect(!allBucketIDs.contains(fine.id))
    }
}
