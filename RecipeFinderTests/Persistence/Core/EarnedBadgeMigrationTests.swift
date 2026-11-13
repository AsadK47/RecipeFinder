import Testing
import CoreData
import Foundation
@testable import RecipeFinder

/// Badge fake: rows in an array, with switches to make reads or writes fail like a broken store.
@MainActor
final class InMemoryEarnedBadgeStore: EarnedBadgeStoring {
    var records: [EarnedBadgeRecord]
    var failWrites = false
    var failReads = false
    private(set) var writeCount = 0

    init(_ records: [EarnedBadgeRecord] = []) {
        self.records = records
    }

    func fetchBadges() throws -> [EarnedBadgeRecord] {
        if failReads { throw EarnedBadgeStoreError.storeUnavailable }
        return records
    }

    func replaceBadges(with replacement: [EarnedBadgeRecord]) throws {
        if failWrites { throw EarnedBadgeStoreError.storeUnavailable }
        writeCount += 1
        records = replacement
    }
}

/// Moving earned badges and shown celebrations out of their two `LocalStore` keys into `EarnedBadgeEntity`
/// (Data safety 1/4, slice 3f). The shared copy/fallback rules are covered by `CollectionMigrationTests` (same
/// `MirroredSnapshot`); these pin the badge wiring, the old two-key shape and the Core Data mapping.
@MainActor
@Suite struct EarnedBadgeMigrationTests {
    private let badgesKey = BadgeManager.badgesBlobKey
    private let shownKey = BadgeManager.shownCelebrationsBlobKey
    private let storage = LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    private let headChefDate = Date(timeIntervalSinceReferenceDate: 815_000_000.25)
    private let firstRecipeDate = Date(timeIntervalSinceReferenceDate: 815_100_000)

    private func earned(_ type: BadgeType, on date: Date) -> Badge {
        let template = type.badge
        return Badge(
            id: template.id, title: template.title, description: template.description, icon: template.icon,
            color: template.color, dateEarned: date, isUnlocked: true, howToEarn: template.howToEarn
        )
    }

    /// What a build before this slice left behind: earned badges keyed by id, plus shown celebration ids.
    private func writeOldKeys(_ badges: [Badge], shown: [String]) {
        storage.setEncodable(Dictionary(uniqueKeysWithValues: badges.map { ($0.id, $0) }), forKey: badgesKey)
        storage.set(shown, forKey: shownKey)
    }

    private func keptBadgeIDs() -> Set<String>? {
        storage.decodable([String: Badge].self, forKey: badgesKey).map { Set($0.keys) }
    }

    private func keptShown() -> Set<String>? {
        (storage.object(forKey: shownKey) as? [String]).map(Set.init)
    }

    private var migrated: Bool {
        storage.bool(forKey: MirroredSnapshot<EarnedBadgeRecord>.flagKey(for: badgesKey))
    }

    private func manager(_ store: any EarnedBadgeStoring) -> BadgeManager {
        BadgeManager(storage: storage, badgeStore: store)
    }

    private var headChef: String { BadgeType.headChef.rawValue }
    private var firstRecipe: String { BadgeType.firstRecipe.rawValue }

    // MARK: - iCloud sync (Data safety 2/4)

    @Test func withSyncOnABadgeEarnedOnAnotherDeviceIsKept() {
        writeOldKeys([earned(.firstRecipe, on: firstRecipeDate)], shown: [firstRecipe])
        let store = InMemoryEarnedBadgeStore()
        _ = manager(store)
        // Earned and celebrated on another device.
        store.records.append(
            EarnedBadgeRecord(badgeId: headChef, isEarned: true, dateEarned: headChefDate, celebrationShown: true))
        storage.set(true, forKey: SyncPreference.key)
        let sut = manager(store)
        #expect(Set(sut.unlockedBadges.keys) == [headChef, firstRecipe])
        #expect(store.records.count == 2)
        #expect(keptBadgeIDs() == [headChef, firstRecipe])
        #expect(keptShown() == [headChef, firstRecipe])
    }

    // MARK: - Migration

    @Test func everyEarnedBadgeAndShownCelebrationBecomesARowAndTheKeyIsMarked() {
        writeOldKeys(
            [earned(.headChef, on: headChefDate), earned(.firstRecipe, on: firstRecipeDate)],
            shown: [headChef]
        )
        let store = InMemoryEarnedBadgeStore()
        let sut = manager(store)
        #expect(store.records == [
            EarnedBadgeRecord(badgeId: firstRecipe, isEarned: true, dateEarned: firstRecipeDate, celebrationShown: false),
            EarnedBadgeRecord(badgeId: headChef, isEarned: true, dateEarned: headChefDate, celebrationShown: true),
        ])
        #expect(Set(sut.unlockedBadges.keys) == [headChef, firstRecipe])
        #expect(sut.unlockedBadges[headChef]?.dateEarned == headChefDate)
        #expect(sut.unlockedBadges[headChef]?.title == BadgeType.headChef.badge.title)
        #expect(migrated)
        #expect(keptBadgeIDs() == [headChef, firstRecipe])
        #expect(keptShown() == [headChef])
    }

    @Test func aShownCelebrationForARevokedBadgeIsKeptSoItNeverPopsAgain() {
        writeOldKeys([earned(.headChef, on: headChefDate)], shown: [headChef, firstRecipe])
        let store = InMemoryEarnedBadgeStore()
        let sut = manager(store)
        #expect(store.records.first { $0.badgeId == firstRecipe }
            == EarnedBadgeRecord(badgeId: firstRecipe, isEarned: false, dateEarned: nil, celebrationShown: true))
        #expect(!sut.isBadgeUnlocked(firstRecipe))

        sut.unlockBadge(.firstRecipe)
        #expect(sut.isBadgeUnlocked(firstRecipe))
        #expect(sut.pendingCelebration == nil)
    }

    @Test func aBadgeThisBuildDoesNotKnowSurvivesTheMove() {
        let future = Badge(id: "future_badge", title: "Future", description: "", icon: "star", color: "blue",
                           dateEarned: headChefDate, isUnlocked: true)
        writeOldKeys([future], shown: [])
        let store = InMemoryEarnedBadgeStore()
        let sut = manager(store)
        #expect(store.records.map { $0.badgeId } == ["future_badge"])
        #expect(sut.unlockedBadges["future_badge"]?.dateEarned == headChefDate)
        #expect(manager(store).isBadgeUnlocked("future_badge"))
    }

    @Test func aFailedWriteLeavesTheKeyUnmarkedAndTheCookKeepsTheirBadges() {
        writeOldKeys([earned(.headChef, on: headChefDate)], shown: [headChef])
        let store = InMemoryEarnedBadgeStore()
        store.failWrites = true
        let sut = manager(store)
        #expect(!migrated)
        #expect(sut.isBadgeUnlocked(headChef))
    }

    @Test func aCorruptBadgesKeyIsKeptAsideAndTheStoreIsLeftAlone() {
        storage.set(Data("not json".utf8), forKey: badgesKey)
        storage.set([firstRecipe], forKey: shownKey)
        let row = EarnedBadgeRecord(badgeId: headChef, isEarned: true, dateEarned: headChefDate, celebrationShown: true)
        let store = InMemoryEarnedBadgeStore([row])
        let sut = manager(store)
        #expect(store.records == [row])
        #expect(sut.isBadgeUnlocked(headChef))
    }

    @Test func aCorruptBadgesKeyStillKeepsShownCelebrationsFromPoppingAgain() {
        storage.set(Data("not json".utf8), forKey: badgesKey)
        storage.set([headChef], forKey: shownKey)
        let store = InMemoryEarnedBadgeStore()
        let sut = manager(store)
        sut.unlockBadge(.headChef)
        #expect(sut.isBadgeUnlocked(headChef))
        #expect(sut.pendingCelebration == nil)
        #expect(store.records.first { $0.badgeId == headChef }?.celebrationShown == true)
    }

    @Test func anUnreadableStoreFallsBackToTheKeptCopy() {
        writeOldKeys([earned(.headChef, on: headChefDate)], shown: [headChef])
        let store = InMemoryEarnedBadgeStore()
        store.failReads = true
        let sut = manager(store)
        #expect(sut.isBadgeUnlocked(headChef))
        #expect(!migrated)
    }

    @Test func aBadgeEarnedWhileTheStoreFailsIsKeptNextLaunch() {
        let store = InMemoryEarnedBadgeStore()
        let sut = manager(store)
        store.failWrites = true
        sut.unlockBadge(.headChef, customDate: headChefDate)
        sut.dismissCelebration()

        store.failWrites = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.unlockedBadges[headChef]?.dateEarned == headChefDate)
        #expect(store.records == [
            EarnedBadgeRecord(badgeId: headChef, isEarned: true, dateEarned: headChefDate, celebrationShown: true),
        ])
    }

    // MARK: - Manager on entities

    @Test func unlocksCelebrationsAndRestoresGoToTheStoreAndTheKeptCopy() {
        let store = InMemoryEarnedBadgeStore()
        let sut = manager(store)
        sut.unlockBadge(.headChef, customDate: headChefDate)
        #expect(sut.pendingCelebration == .headChef)
        #expect(store.records == [
            EarnedBadgeRecord(badgeId: headChef, isEarned: true, dateEarned: headChefDate, celebrationShown: true),
        ])
        #expect(keptShown() == [headChef])

        sut.merge([firstRecipe: earned(.firstRecipe, on: firstRecipeDate)])
        #expect(store.records.map { $0.badgeId } == [firstRecipe, headChef])
        #expect(store.records.allSatisfy { $0.celebrationShown })
        #expect(keptBadgeIDs() == [headChef, firstRecipe])
    }

    @Test func aCelebrationShownBeforeARelaunchDoesNotShowAgain() {
        let store = InMemoryEarnedBadgeStore()
        manager(store).unlockBadge(.headChef)
        let nextLaunch = manager(store)
        nextLaunch.unlockBadge(.headChef)
        #expect(nextLaunch.pendingCelebration == nil)
    }

    @Test func aBadgeEarnedNowIsNotRewrittenOnRelaunch() {
        // Sub-second dates must survive the kept copy's JSON, or every launch would see "differs" and rewrite rows.
        let store = InMemoryEarnedBadgeStore()
        manager(store).unlockBadge(.headChef)
        let writes = store.writeCount
        _ = manager(store)
        #expect(store.writeCount == writes)
    }

    @Test func removeAllBadgesEmptiesTheStoreAndDropsAnOpenCelebration() {
        let store = InMemoryEarnedBadgeStore()
        let sut = manager(store)
        sut.unlockBadge(.headChef)
        sut.removeAllBadges()
        #expect(sut.unlockedBadges.isEmpty)
        #expect(sut.pendingCelebration == nil)
        #expect(store.records.isEmpty)
        #expect(manager(store).unlockedBadges.isEmpty)
    }

    @Test func resetDropsQueuedCelebrationsToo() {
        let store = InMemoryEarnedBadgeStore()
        let sut = manager(store)
        sut.unlockBadge(.headChef)
        sut.unlockBadge(.firstRecipe)   // queued behind the open sheet
        sut.removeAllBadges()
        sut.dismissCelebration()
        #expect(sut.pendingCelebration == nil)
    }

    @Test func aQuietUnlockSavesItsShownFlagWithTheBadge() {
        // A single quiet unlock used to save "shown" only in memory: revoked and re-earned later, it popped a sheet.
        let store = InMemoryEarnedBadgeStore()
        let first = manager(store)
        first.unlockBadge(.welcomeAboard, silent: true)
        first.checkAndUnlockBadges(recipeCount: 1, silent: true)   // exactly one badge crosses
        let nextLaunch = manager(store)
        nextLaunch.revokeUnearnedCollectionBadges(collectedCount: 0)
        #expect(!nextLaunch.isBadgeUnlocked(firstRecipe))
        nextLaunch.checkAndUnlockBadges(recipeCount: 1)
        #expect(nextLaunch.pendingCelebration == nil)
    }

    @Test func resetAsSettingsRunsItClearsBadges() {
        // DataManagementSettingsView: LocalStore.clearAll() (drops keys + flags), then removeAllBadges().
        writeOldKeys([earned(.headChef, on: headChefDate)], shown: [headChef])
        let store = InMemoryEarnedBadgeStore()
        let sut = manager(store)
        storage.clearAll()
        sut.removeAllBadges()
        #expect(sut.unlockedBadges.isEmpty)
        let nextLaunch = manager(store)
        #expect(nextLaunch.unlockedBadges.isEmpty)
        nextLaunch.unlockBadge(.headChef)
        #expect(nextLaunch.pendingCelebration == .headChef)
    }

    @Test func aResetWhoseDeleteFailsIsFinishedNextLaunch() {
        let row = EarnedBadgeRecord(badgeId: headChef, isEarned: true, dateEarned: headChefDate, celebrationShown: true)
        let store = InMemoryEarnedBadgeStore([row])
        let sut = manager(store)
        store.failWrites = true
        sut.removeAllBadges()
        #expect(sut.unlockedBadges.isEmpty)

        store.failWrites = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.unlockedBadges.isEmpty)
        #expect(store.records.isEmpty)
    }

    // MARK: - Core Data store (framework exemption: in-memory SQLite, like CoreDataStorePersistenceTests)

    private var rows: [EarnedBadgeRecord] {
        [
            EarnedBadgeRecord(badgeId: firstRecipe, isEarned: true, dateEarned: firstRecipeDate, celebrationShown: false),
            EarnedBadgeRecord(badgeId: headChef, isEarned: true, dateEarned: headChefDate, celebrationShown: true),
            EarnedBadgeRecord(badgeId: "zz_revoked", isEarned: false, dateEarned: nil, celebrationShown: true),
        ]
    }

    @Test func coreDataStoreRoundTripsEveryField() throws {
        let sut = CoreDataEarnedBadgeStore(persistence: PersistenceController(inMemory: true))
        try sut.replaceBadges(with: rows)
        #expect(try sut.fetchBadges() == rows)
    }

    @Test func coreDataStoreClearsADateAndFlags() throws {
        let sut = CoreDataEarnedBadgeStore(persistence: PersistenceController(inMemory: true))
        try sut.replaceBadges(with: rows)
        let cleared = [EarnedBadgeRecord(badgeId: headChef, isEarned: false, dateEarned: nil, celebrationShown: false)]
        try sut.replaceBadges(with: cleared)
        #expect(try sut.fetchBadges() == cleared)
    }

    @Test func coreDataStoreKeepsTodaysExactTimes() throws {
        let now = [EarnedBadgeRecord(badgeId: headChef, isEarned: true, dateEarned: Date(), celebrationShown: true)]
        let sut = CoreDataEarnedBadgeStore(persistence: PersistenceController(inMemory: true))
        try sut.replaceBadges(with: now)
        #expect(try sut.fetchBadges() == now)
    }

    @Test func coreDataStoreUpdatesExistingRowsAndGivesEachAnID() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sut = CoreDataEarnedBadgeStore(persistence: persistence)
        try sut.replaceBadges(with: rows)
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataEarnedBadgeStore.entityName)
        let before = try context.fetch(request)
        #expect(before.allSatisfy { $0.value(forKey: "id") is UUID })
        let idsBefore = Set(before.map(\.objectID))

        let updated = rows.map {
            EarnedBadgeRecord(badgeId: $0.badgeId, isEarned: true, dateEarned: headChefDate, celebrationShown: true)
        }
        try sut.replaceBadges(with: updated)
        #expect(Set(try context.fetch(request).map { $0.objectID }) == idsBefore)
        #expect(try sut.fetchBadges() == updated)

        try sut.replaceBadges(with: [rows[0]])
        #expect(try context.count(for: request) == 1)
    }

    @Test func coreDataStoreSkipsARowWithoutABadgeAndCleansUpDuplicates() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext
        let sut = CoreDataEarnedBadgeStore(persistence: persistence)
        try sut.replaceBadges(with: [rows[1]])
        let entity = try #require(NSEntityDescription.entity(
            forEntityName: CoreDataEarnedBadgeStore.entityName, in: context
        ))
        NSManagedObject(entity: entity, insertInto: context).setValue(UUID(), forKey: "id")   // no badge id
        let duplicate = NSManagedObject(entity: entity, insertInto: context)                  // a sync duplicate
        duplicate.setValue(UUID(), forKey: "id")
        duplicate.setValue(headChef, forKey: "badgeId")
        try context.save()
        #expect(try sut.fetchBadges().map { $0.badgeId } == [headChef])

        try sut.replaceBadges(with: [rows[1]])
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataEarnedBadgeStore.entityName)
        #expect(try context.count(for: request) == 1)
    }

    @Test func coreDataStoreReturnsMixedCaseIDsInTheKeptCopysOrder() throws {
        // Guard: the order must match `EarnedBadgeRecord.records`, or every launch would see "differs".
        let mixed = EarnedBadgeRecord.records(
            earned: [:], shown: ["b", "B", "a_b", "aB", "A"]
        )
        let sut = CoreDataEarnedBadgeStore(persistence: PersistenceController(inMemory: true))
        try sut.replaceBadges(with: mixed)
        #expect(try sut.fetchBadges() == mixed)
    }
}
