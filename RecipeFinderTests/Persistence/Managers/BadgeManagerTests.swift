import Testing
import Foundation
@testable import RecipeFinder

@MainActor
@Suite("BadgeManager")
struct BadgeManagerTests {

    private func makeSUT() -> BadgeManager {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        return BadgeManager(storage: LocalStore(userDefaults: defaults))
    }

    // MARK: - Initial state

    @Test func initialState_noBadgesUnlocked() {
        let sut = makeSUT()
        #expect(sut.unlockedBadges.isEmpty)
    }

    @Test func initialState_noPendingCelebration() {
        let sut = makeSUT()
        #expect(sut.pendingCelebration == nil)
    }

    // MARK: - isBadgeUnlocked

    @Test func isBadgeUnlocked_falseWhenNotUnlocked() {
        let sut = makeSUT()
        #expect(!sut.isBadgeUnlocked(BadgeType.firstRecipe.rawValue))
    }

    @Test func isBadgeUnlocked_trueAfterUnlock() {
        let sut = makeSUT()
        sut.unlockBadge(.firstRecipe)
        #expect(sut.isBadgeUnlocked(BadgeType.firstRecipe.rawValue))
    }

    // MARK: - unlockBadge

    @Test func unlockBadge_addsBadgeToUnlockedBadges() {
        let sut = makeSUT()
        sut.unlockBadge(.tenRecipes)
        #expect(sut.unlockedBadges[BadgeType.tenRecipes.rawValue] != nil)
    }

    @Test func unlockBadge_setsIsUnlockedTrue() {
        let sut = makeSUT()
        sut.unlockBadge(.fiveRecipes)
        #expect(sut.unlockedBadges[BadgeType.fiveRecipes.rawValue]?.isUnlocked == true)
    }

    @Test func unlockBadge_usesCustomDate() {
        let sut = makeSUT()
        let customDate = Date(timeIntervalSince1970: 1_000_000)
        sut.unlockBadge(.firstRecipe, customDate: customDate)
        #expect(sut.unlockedBadges[BadgeType.firstRecipe.rawValue]?.dateEarned == customDate)
    }

    @Test func unlockBadge_isIdempotent_datePreservedOnSecondCall() {
        let sut = makeSUT()
        let customDate = Date(timeIntervalSince1970: 1_000_000)
        sut.unlockBadge(.firstRecipe, customDate: customDate)
        sut.unlockBadge(.firstRecipe)  // second call ignored
        #expect(sut.unlockedBadges[BadgeType.firstRecipe.rawValue]?.dateEarned == customDate)
    }

    // MARK: - Celebration queue

    @Test func unlockBadge_setsPendingCelebration() {
        let sut = makeSUT()
        sut.unlockBadge(.firstRecipe)
        #expect(sut.pendingCelebration == .firstRecipe)
    }

    @Test func unlockBadge_silent_doesNotSetPendingCelebration() {
        let sut = makeSUT()
        sut.unlockBadge(.firstRecipe, silent: true)
        #expect(sut.pendingCelebration == nil)
        #expect(sut.isBadgeUnlocked(BadgeType.firstRecipe.rawValue))
    }

    @Test func dismissCelebration_clearsCurrentCelebration() {
        let sut = makeSUT()
        sut.unlockBadge(.firstRecipe)
        sut.dismissCelebration()
        #expect(sut.pendingCelebration == nil)
    }

    @Test func queuedBadges_appearInOrder() {
        let sut = makeSUT()
        sut.unlockBadge(.firstRecipe)
        sut.unlockBadge(.fiveRecipes)  // queued while firstRecipe is showing
        #expect(sut.pendingCelebration == .firstRecipe)
        sut.dismissCelebration()
        #expect(sut.pendingCelebration == .fiveRecipes)
        sut.dismissCelebration()
        #expect(sut.pendingCelebration == nil)
    }

    @Test func badgesEarnedDuringARevealEachRevealOnceInEarnOrder() {
        let sut = makeSUT()
        let earned: [BadgeType] = [.headChef, .mealPlanner, .shoppingExpert]
        earned.forEach { sut.unlockBadge($0) }
        var revealed: [BadgeType] = []
        while let next = sut.pendingCelebration {
            revealed.append(next)
            sut.dismissCelebration()
        }
        #expect(revealed == earned)
    }

    @Test func aBadgeLostAndEarnedAgainDoesNotRevealTwice() {
        let sut = makeSUT()
        sut.unlockBadge(.fiveRecipes)
        sut.dismissCelebration()
        sut.revokeUnearnedCollectionBadges(collectedCount: 0)
        #expect(!sut.isBadgeUnlocked(BadgeType.fiveRecipes.rawValue))

        sut.unlockBadge(.fiveRecipes)
        #expect(sut.isBadgeUnlocked(BadgeType.fiveRecipes.rawValue))
        #expect(sut.pendingCelebration == nil)
    }

    // MARK: - Bulk import suppression (restore crosses count thresholds without a parade of sheets)

    @Test func bulkImporting_unlocksBadgeWithoutCelebration() {
        let sut = makeSUT()
        sut.isBulkImporting = true
        sut.unlockBadge(.firstRecipe)
        #expect(sut.isBadgeUnlocked(BadgeType.firstRecipe.rawValue))  // still persisted
        #expect(sut.pendingCelebration == nil)                        // but no sheet
    }

    @Test func bulkImporting_laterChecksDoNotRequeueSuppressedBadge() {
        let sut = makeSUT()
        sut.isBulkImporting = true
        sut.unlockBadge(.firstRecipe)
        sut.isBulkImporting = false
        // A normal (non-silent) unlock attempt for the already-held badge must not pop a late sheet.
        sut.unlockBadge(.firstRecipe)
        #expect(sut.pendingCelebration == nil)
    }

    @Test func alreadyUnlockedBadge_doesNotQueueCelebrationAgain() {
        let sut = makeSUT()
        sut.unlockBadge(.firstRecipe)
        sut.dismissCelebration()
        // Second unlock call for already-held badge does nothing.
        sut.unlockBadge(.firstRecipe)
        #expect(sut.pendingCelebration == nil)
    }

    @Test func shownCelebrationIds_persistAcrossReload() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let storage = LocalStore(userDefaults: defaults)
        let sut1 = BadgeManager(storage: storage)
        sut1.unlockBadge(.firstRecipe)
        sut1.dismissCelebration()

        // Fresh instance same storage — celebration must NOT re-queue.
        let sut2 = BadgeManager(storage: storage)
        sut2.unlockBadge(.firstRecipe)
        #expect(sut2.pendingCelebration == nil)
    }

    // MARK: - checkAndUnlockBadges

    @Test func checkAndUnlock_unlocksFirstRecipeBadgeAtCount1() {
        let sut = makeSUT()
        sut.checkAndUnlockBadges(recipeCount: 1)
        #expect(sut.isBadgeUnlocked(BadgeType.firstRecipe.rawValue))
    }

    @Test func checkAndUnlock_doesNotUnlockHigherBadgesAtLowCount() {
        let sut = makeSUT()
        sut.checkAndUnlockBadges(recipeCount: 1)
        #expect(!sut.isBadgeUnlocked(BadgeType.tenRecipes.rawValue))
    }

    @Test func checkAndUnlock_unlocksMultipleBadgesAtOnce() {
        let sut = makeSUT()
        sut.checkAndUnlockBadges(recipeCount: 10)
        #expect(sut.isBadgeUnlocked(BadgeType.firstRecipe.rawValue))
        #expect(sut.isBadgeUnlocked(BadgeType.fiveRecipes.rawValue))
        #expect(sut.isBadgeUnlocked(BadgeType.tenRecipes.rawValue))
        #expect(!sut.isBadgeUnlocked(BadgeType.twentyFiveRecipes.rawValue))
    }

    @Test func checkAndUnlock_doesNotDuplicateAlreadyUnlockedBadge() {
        let sut = makeSUT()
        sut.checkAndUnlockBadges(recipeCount: 5)
        let firstDate = sut.unlockedBadges[BadgeType.fiveRecipes.rawValue]?.dateEarned
        sut.checkAndUnlockBadges(recipeCount: 5)
        let secondDate = sut.unlockedBadges[BadgeType.fiveRecipes.rawValue]?.dateEarned
        #expect(firstDate == secondDate)
    }

    @Test func checkAndUnlock_welcomeAboardIsSilent() {
        let sut = makeSUT()
        sut.checkAndUnlockBadges(recipeCount: 0)
        #expect(sut.isBadgeUnlocked(BadgeType.welcomeAboard.rawValue))
        // welcomeAboard must never show a celebration sheet (confusing mid-session).
        #expect(sut.pendingCelebration != .welcomeAboard)
    }

    // MARK: - getAllBadges

    @Test func getAllBadges_returnsAllBadgeTypes() {
        let sut = makeSUT()
        #expect(sut.getAllBadges(recipeCount: 0).count == BadgeType.allCases.count)
    }

    @Test func getAllBadges_unlockedBadgesHaveIsUnlockedTrue() {
        let sut = makeSUT()
        sut.unlockBadge(.firstRecipe)
        let badge = sut.getAllBadges(recipeCount: 1).first { $0.id == BadgeType.firstRecipe.rawValue }
        #expect(badge?.isUnlocked == true)
    }

    @Test func getAllBadges_lockedBadgesHaveIsUnlockedFalse() {
        let sut = makeSUT()
        let badge = sut.getAllBadges(recipeCount: 0).first { $0.id == BadgeType.hundredRecipes.rawValue }
        #expect(badge?.isUnlocked == false)
    }

    // MARK: - Persistence (badges)

    @Test func persistence_badgesAcrossReload() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let storage = LocalStore(userDefaults: defaults)
        let sut1 = BadgeManager(storage: storage)
        sut1.unlockBadge(.firstRecipe)
        let sut2 = BadgeManager(storage: storage)
        #expect(sut2.isBadgeUnlocked(BadgeType.firstRecipe.rawValue))
    }

    // MARK: - merge

    @Test func merge_addsMissingBadges() {
        let sut = makeSUT()
        let incoming: [String: Badge] = [BadgeType.tenRecipes.rawValue: BadgeType.tenRecipes.badge]
        sut.merge(incoming)
        #expect(sut.isBadgeUnlocked(BadgeType.tenRecipes.rawValue))
    }

    @Test func merge_doesNotQueueCelebrationForRestoredBadges() {
        let sut = makeSUT()
        let incoming: [String: Badge] = [BadgeType.tenRecipes.rawValue: BadgeType.tenRecipes.badge]
        sut.merge(incoming)
        // Restored badges are silent — no celebration sheet for already-earned badges.
        #expect(sut.pendingCelebration == nil)
    }

    @Test func merge_existingBadgeDateIsPreserved() {
        let sut = makeSUT()
        let originalDate = Date(timeIntervalSince1970: 999)
        sut.unlockBadge(.firstRecipe, customDate: originalDate)

        var incomingBadge = BadgeType.firstRecipe.badge
        incomingBadge = Badge(
            id: incomingBadge.id, title: incomingBadge.title,
            description: incomingBadge.description, icon: incomingBadge.icon,
            color: incomingBadge.color, dateEarned: Date(), isUnlocked: true,
            howToEarn: incomingBadge.howToEarn
        )
        sut.merge([BadgeType.firstRecipe.rawValue: incomingBadge])
        #expect(sut.unlockedBadges[BadgeType.firstRecipe.rawValue]?.dateEarned == originalDate)
    }

    // MARK: - New badge types

    @Test(arguments: [BadgeType.firstImport, .firstPhotoImport, .headChef])
    func newBadgeTypes_unlockAndCelebrate(badgeType: BadgeType) {
        let sut = makeSUT()
        sut.unlockBadge(badgeType)
        #expect(sut.isBadgeUnlocked(badgeType.rawValue))
        #expect(sut.pendingCelebration == badgeType)
    }

    // MARK: - checkAndUnlockBadges(metrics:)

    @Test func metrics_unlocksHeadChefOnFirstCook() {
        let sut = makeSUT()
        var m = BadgeMetrics(); m.recipesCooked = 1
        sut.checkAndUnlockBadges(metrics: m)
        #expect(sut.isBadgeUnlocked(BadgeType.headChef.rawValue))
    }

    @Test func metrics_unlocksCookVolumeAtThreshold() {
        let sut = makeSUT()
        var m = BadgeMetrics(); m.recipesCooked = 25
        sut.checkAndUnlockBadges(metrics: m)
        #expect(sut.isBadgeUnlocked(BadgeType.cookedTen.rawValue))
        #expect(sut.isBadgeUnlocked(BadgeType.cookedTwentyFive.rawValue))
        #expect(!sut.isBadgeUnlocked(BadgeType.cookedFifty.rawValue))
    }

    @Test func metrics_unlocksStreakBadge() {
        let sut = makeSUT()
        var m = BadgeMetrics(); m.weeklyStreak = 2
        sut.checkAndUnlockBadges(metrics: m)
        #expect(sut.isBadgeUnlocked(BadgeType.streakTwoWeeks.rawValue))
        #expect(!sut.isBadgeUnlocked(BadgeType.streakFourWeeks.rawValue))
    }

    @Test func metrics_doesNotUnlockBelowThreshold() {
        let sut = makeSUT()
        var m = BadgeMetrics(); m.recipesCooked = 9
        sut.checkAndUnlockBadges(metrics: m)
        #expect(!sut.isBadgeUnlocked(BadgeType.cookedTen.rawValue))
    }

    @Test func metrics_breadthDepthQualityBadges() {
        let sut = makeSUT()
        var m = BadgeMetrics()
        m.cuisinesCooked = 5
        m.sameRecipeCooked = 5
        m.recipesRated = 10
        m.cookPhotos = 1
        sut.checkAndUnlockBadges(metrics: m)
        #expect(sut.isBadgeUnlocked(BadgeType.cuisinesFive.rawValue))
        #expect(sut.isBadgeUnlocked(BadgeType.sameRecipeFive.rawValue))
        #expect(sut.isBadgeUnlocked(BadgeType.ratedTen.rawValue))
        #expect(sut.isBadgeUnlocked(BadgeType.firstCookPhoto.rawValue))
    }

    @Test func metrics_silentBackfillUnlocksWithoutCelebration() {
        let sut = makeSUT()
        var m = BadgeMetrics(); m.recipesCooked = 25; m.weeklyStreak = 4
        sut.checkAndUnlockBadges(metrics: m, silent: true)
        #expect(sut.isBadgeUnlocked(BadgeType.cookedTwentyFive.rawValue))  // unlocked…
        #expect(sut.isBadgeUnlocked(BadgeType.streakFourWeeks.rawValue))
        #expect(sut.pendingCelebration == nil)                            // …but no launch parade
    }

    /// Regression guard: the library-size path must never unlock cooking badges (they default to 0 required).
    @Test func recipeCountPath_doesNotUnlockCookingBadges() {
        let sut = makeSUT()
        sut.checkAndUnlockBadges(recipeCount: 100)  // huge library, zero cooks
        #expect(!sut.isBadgeUnlocked(BadgeType.headChef.rawValue))
        #expect(!sut.isBadgeUnlocked(BadgeType.cookedTen.rawValue))
        #expect(!sut.isBadgeUnlocked(BadgeType.streakTwoWeeks.rawValue))
        #expect(sut.isBadgeUnlocked(BadgeType.hundredRecipes.rawValue))  // collection still unlocks
    }

    // MARK: - Batch unlocks celebrate once

    @Test func checkAndUnlock_manyAtOnce_celebratesOnlyTheHighest() {
        let sut = makeSUT()
        sut.checkAndUnlockBadges(recipeCount: 10)
        #expect(sut.pendingCelebration == .tenRecipes)
        sut.dismissCelebration()
        #expect(sut.pendingCelebration == nil)   // firstRecipe / fiveRecipes saved quietly, no parade
    }

    @Test func revokeUnearnedCollectionBadges_removesOnlyBadgesAboveTheCount() {
        let sut = makeSUT()
        sut.checkAndUnlockBadges(recipeCount: 10)
        sut.revokeUnearnedCollectionBadges(collectedCount: 1)
        #expect(sut.isBadgeUnlocked(BadgeType.firstRecipe.rawValue))
        #expect(!sut.isBadgeUnlocked(BadgeType.fiveRecipes.rawValue))
        #expect(!sut.isBadgeUnlocked(BadgeType.tenRecipes.rawValue))
        #expect(sut.isBadgeUnlocked(BadgeType.welcomeAboard.rawValue))
    }
}
