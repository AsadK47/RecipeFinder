import XCTest
@testable import RecipeFinder

@MainActor
final class BadgeManagerTests: XCTestCase {

    private var storage: UserScopedStorage!
    private var sut: BadgeManager!

    override func setUp() async throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        storage = UserScopedStorage(userDefaults: defaults)
        sut = BadgeManager(storage: storage)
    }

    override func tearDown() async throws {
        sut = nil
        storage = nil
    }

    // MARK: - Initial state

    func testInitialState_noBadgesUnlocked() {
        XCTAssertTrue(sut.unlockedBadges.isEmpty)
    }

    // MARK: - isBadgeUnlocked

    func testIsBadgeUnlocked_falseWhenNotUnlocked() {
        XCTAssertFalse(sut.isBadgeUnlocked(BadgeType.firstRecipe.rawValue))
    }

    func testIsBadgeUnlocked_trueAfterUnlock() {
        sut.unlockBadge(.firstRecipe)
        XCTAssertTrue(sut.isBadgeUnlocked(BadgeType.firstRecipe.rawValue))
    }

    // MARK: - unlockBadge

    func testUnlockBadge_addsBadgeToUnlockedBadges() {
        sut.unlockBadge(.tenRecipes)
        XCTAssertNotNil(sut.unlockedBadges[BadgeType.tenRecipes.rawValue])
    }

    func testUnlockBadge_setsIsUnlockedTrue() {
        sut.unlockBadge(.fiveRecipes)
        XCTAssertTrue(sut.unlockedBadges[BadgeType.fiveRecipes.rawValue]!.isUnlocked)
    }

    func testUnlockBadge_usesCustomDate() {
        let customDate = Date(timeIntervalSince1970: 1_000_000)
        sut.unlockBadge(.firstRecipe, customDate: customDate)
        XCTAssertEqual(sut.unlockedBadges[BadgeType.firstRecipe.rawValue]?.dateEarned, customDate)
    }

    // MARK: - checkAndUnlockBadges

    func testCheckAndUnlock_unlocksFirstRecipeBadgeAtCount1() {
        sut.checkAndUnlockBadges(recipeCount: 1)
        XCTAssertTrue(sut.isBadgeUnlocked(BadgeType.firstRecipe.rawValue))
    }

    func testCheckAndUnlock_doesNotUnlockHigherBadgesAtLowCount() {
        sut.checkAndUnlockBadges(recipeCount: 1)
        XCTAssertFalse(sut.isBadgeUnlocked(BadgeType.tenRecipes.rawValue))
    }

    func testCheckAndUnlock_unlocksMultipleBadgesAtOnce() {
        sut.checkAndUnlockBadges(recipeCount: 10)
        XCTAssertTrue(sut.isBadgeUnlocked(BadgeType.firstRecipe.rawValue))
        XCTAssertTrue(sut.isBadgeUnlocked(BadgeType.fiveRecipes.rawValue))
        XCTAssertTrue(sut.isBadgeUnlocked(BadgeType.tenRecipes.rawValue))
        XCTAssertFalse(sut.isBadgeUnlocked(BadgeType.twentyFiveRecipes.rawValue))
    }

    func testCheckAndUnlock_doesNotDuplicateAlreadyUnlockedBadge() {
        sut.checkAndUnlockBadges(recipeCount: 5)
        let firstUnlockDate = sut.unlockedBadges[BadgeType.fiveRecipes.rawValue]!.dateEarned

        Thread.sleep(forTimeInterval: 0.05)
        sut.checkAndUnlockBadges(recipeCount: 5)
        let secondUnlockDate = sut.unlockedBadges[BadgeType.fiveRecipes.rawValue]!.dateEarned

        XCTAssertEqual(firstUnlockDate, secondUnlockDate)
    }

    func testCheckAndUnlock_zeroCount_unlocksWelcomeAboard() {
        sut.checkAndUnlockBadges(recipeCount: 0)
        XCTAssertTrue(sut.isBadgeUnlocked(BadgeType.welcomeAboard.rawValue))
    }

    // MARK: - getAllBadges

    func testGetAllBadges_returnsAllBadgeTypes() {
        let badges = sut.getAllBadges(recipeCount: 0)
        XCTAssertEqual(badges.count, BadgeType.allCases.count)
    }

    func testGetAllBadges_unlockedBadgesHaveIsUnlockedTrue() {
        sut.unlockBadge(.firstRecipe)
        let badges = sut.getAllBadges(recipeCount: 1)
        let firstRecipeBadge = badges.first { $0.id == BadgeType.firstRecipe.rawValue }
        XCTAssertTrue(firstRecipeBadge!.isUnlocked)
    }

    func testGetAllBadges_lockedBadgesHaveIsUnlockedFalse() {
        let badges = sut.getAllBadges(recipeCount: 0)
        let hundredRecipesBadge = badges.first { $0.id == BadgeType.hundredRecipes.rawValue }
        XCTAssertFalse(hundredRecipesBadge!.isUnlocked)
    }

    // MARK: - Persistence

    func testPersistence_acrossReload() {
        sut.unlockBadge(.firstRecipe)
        let sut2 = BadgeManager(storage: storage)
        XCTAssertTrue(sut2.isBadgeUnlocked(BadgeType.firstRecipe.rawValue))
    }
}
