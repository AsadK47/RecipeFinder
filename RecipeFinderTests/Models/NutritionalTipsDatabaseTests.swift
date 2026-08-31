import Testing
import Foundation
@testable import RecipeFinder

@Suite struct NutritionalTipsDatabaseTests {

    // MARK: - allTips

    @Test func allTips_isNonEmpty() {
        #expect(!NutritionalTipsDatabase.allTips.isEmpty)
    }

    @Test func allTips_haveUniqueIDs() {
        let ids = NutritionalTipsDatabase.allTips.map(\.id)
        #expect(ids.count == Set(ids).count)
    }

    // MARK: - tips(forCategory:)

    @Test(arguments: NutritionalTipCategory.allCases)
    func tipsForCategory_onlyReturnsMatchingCategory(_ category: NutritionalTipCategory) {
        let tips = NutritionalTipsDatabase.tips(forCategory: category)
        #expect(tips.allSatisfy { $0.category == category })
    }

    @Test func tipsForCategory_matchesManualFilter() {
        for category in NutritionalTipCategory.allCases {
            let expected = NutritionalTipsDatabase.allTips.filter { $0.category == category }
            let actual = NutritionalTipsDatabase.tips(forCategory: category)
            #expect(actual.map(\.id) == expected.map(\.id))
        }
    }

    // MARK: - tipOfTheDay()

    @Test func tipOfTheDay_matchesDayOfYearIndex() {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let expected = NutritionalTipsDatabase.allTips[(dayOfYear - 1) % NutritionalTipsDatabase.allTips.count]
        #expect(NutritionalTipsDatabase.tipOfTheDay().id == expected.id)
    }

    // MARK: - randomTips(count:)

    @Test(arguments: [0, 1, 3, 5])
    func randomTips_returnsRequestedCount(_ count: Int) {
        #expect(NutritionalTipsDatabase.randomTips(count: count).count == count)
    }

    @Test func randomTips_countExceedingTotal_clampsToTotal() {
        let total = NutritionalTipsDatabase.allTips.count
        #expect(NutritionalTipsDatabase.randomTips(count: total + 10).count == total)
    }

    @Test func randomTips_onlyReturnsKnownTips() {
        let knownIDs = Set(NutritionalTipsDatabase.allTips.map(\.id))
        let picked = NutritionalTipsDatabase.randomTips(count: 5)
        #expect(picked.allSatisfy { knownIDs.contains($0.id) })
    }

    // MARK: - essentialTips()

    @Test func essentialTips_allStrongEvidence() {
        #expect(NutritionalTipsDatabase.essentialTips().allSatisfy { $0.evidenceLevel == .strong })
    }

    @Test func essentialTips_returnsAtMostFive() {
        #expect(NutritionalTipsDatabase.essentialTips().count <= 5)
    }
}
