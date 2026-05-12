import XCTest
@testable import RecipeFinder

final class KitchenInventoryModelTests: XCTestCase {

    // MARK: - daysUntilExpiry

    func testDaysUntilExpiry_nilWhenNoExpiryDate() {
        let item = makeItem(expiryDate: nil)
        XCTAssertNil(item.daysUntilExpiry)
    }

    func testDaysUntilExpiry_positiveForFutureDate() {
        let item = makeItem(expiryDate: daysFromNow(5))
        XCTAssertEqual(item.daysUntilExpiry, 5)
    }

    func testDaysUntilExpiry_negativeForPastDate() {
        let item = makeItem(expiryDate: daysFromNow(-3))
        XCTAssertEqual(item.daysUntilExpiry, -3)
    }

    // MARK: - isExpired

    func testIsExpired_falseWhenNoExpiryDate() {
        XCTAssertFalse(makeItem(expiryDate: nil).isExpired)
    }

    func testIsExpired_trueForPastDate() {
        XCTAssertTrue(makeItem(expiryDate: daysFromNow(-1)).isExpired)
    }

    func testIsExpired_falseForFutureDate() {
        XCTAssertFalse(makeItem(expiryDate: daysFromNow(1)).isExpired)
    }

    // MARK: - isExpiringSoon

    func testIsExpiringSoon_falseWhenNoExpiryDate() {
        XCTAssertFalse(makeItem(expiryDate: nil).isExpiringSoon)
    }

    func testIsExpiringSoon_trueWithin3Days() {
        XCTAssertTrue(makeItem(expiryDate: daysFromNow(2)).isExpiringSoon)
    }

    func testIsExpiringSoon_trueAtExactly3Days() {
        XCTAssertTrue(makeItem(expiryDate: daysFromNow(3)).isExpiringSoon)
    }

    func testIsExpiringSoon_falseAt4Days() {
        XCTAssertFalse(makeItem(expiryDate: daysFromNow(4)).isExpiringSoon)
    }

    func testIsExpiringSoon_falseForExpiredItem() {
        XCTAssertFalse(makeItem(expiryDate: daysFromNow(-1)).isExpiringSoon)
    }

    // MARK: - expiryStatusText

    func testExpiryStatusText_noExpiryDate() {
        XCTAssertEqual(makeItem(expiryDate: nil).expiryStatusText, "No expiry date")
    }

    func testExpiryStatusText_expiredOneDayAgo() {
        XCTAssertEqual(makeItem(expiryDate: daysFromNow(-1)).expiryStatusText, "Expired 1 day ago")
    }

    func testExpiryStatusText_expiredMultipleDaysAgo() {
        XCTAssertEqual(makeItem(expiryDate: daysFromNow(-3)).expiryStatusText, "Expired 3 days ago")
    }

    func testExpiryStatusText_expiresToday() {
        XCTAssertEqual(makeItem(expiryDate: daysFromNow(0)).expiryStatusText, "Expires today")
    }

    func testExpiryStatusText_expiresTomorrow() {
        XCTAssertEqual(makeItem(expiryDate: daysFromNow(1)).expiryStatusText, "Expires tomorrow")
    }

    func testExpiryStatusText_expiresInSeveralDays() {
        XCTAssertEqual(makeItem(expiryDate: daysFromNow(5)).expiryStatusText, "Expires in 5 days")
    }

    // MARK: - needsRestock

    func testNeedsRestock_noMinimum_usesIsLowStock_true() {
        XCTAssertTrue(makeItem(isLowStock: true, minimumQuantity: nil).needsRestock)
    }

    func testNeedsRestock_noMinimum_usesIsLowStock_false() {
        XCTAssertFalse(makeItem(isLowStock: false, minimumQuantity: nil).needsRestock)
    }

    func testNeedsRestock_withMinimum_quantityAtMinimum() {
        XCTAssertTrue(makeItem(quantity: 2.0, isLowStock: false, minimumQuantity: 2.0).needsRestock)
    }

    func testNeedsRestock_withMinimum_quantityBelowMinimum() {
        XCTAssertTrue(makeItem(quantity: 1.0, isLowStock: false, minimumQuantity: 2.0).needsRestock)
    }

    func testNeedsRestock_withMinimum_quantityAboveMinimum() {
        XCTAssertFalse(makeItem(quantity: 5.0, isLowStock: false, minimumQuantity: 2.0).needsRestock)
    }

    // MARK: - Helpers

    private func makeItem(
        quantity: Double = 1.0,
        expiryDate: Date? = nil,
        isLowStock: Bool = false,
        minimumQuantity: Double? = nil
    ) -> KitchenInventoryModel {
        KitchenInventoryModel(
            name: "Test Item",
            category: .produce,
            quantity: quantity,
            unit: "kg",
            expiryDate: expiryDate,
            isLowStock: isLowStock,
            minimumQuantity: minimumQuantity
        )
    }

    private func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date())!
    }
}
