import Testing
import CoreData
import Foundation
@testable import RecipeFinder

/// Cook-date fake: an array, with switches to make reads or writes fail like a broken store.
@MainActor
final class InMemoryCookDateStore: CookDateStoring {
    var dates: [Date]
    var failWrites = false
    var failReads = false
    /// Accepts writes but silently keeps nothing, so the migration's re-read check is what catches it.
    var dropWrites = false

    init(_ dates: [Date] = []) { self.dates = dates }

    func fetchCookDates() throws -> [Date] {
        if failReads { throw CookDateStoreError.storeUnavailable }
        return dates.sorted()
    }

    func addCookDates(_ added: [Date]) throws {
        if failWrites { throw CookDateStoreError.storeUnavailable }
        if !dropWrites { dates += added }
    }

    func deleteAllCookDates() throws {
        if failWrites { throw CookDateStoreError.storeUnavailable }
        dates = []
    }
}

/// Moving the cook-date blob out of `LocalStore` into `CookDateEntity` (Data safety 1/4, slice 3).
@MainActor
@Suite struct CookDateMigrationTests {
    private let blobKey = "cookDatesLog"
    private let storage = LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    private let day: TimeInterval = 86_400
    private var cooks: [Date] {
        [Date(timeIntervalSinceReferenceDate: 800_000_000),
         Date(timeIntervalSinceReferenceDate: 800_000_000 + 8 * day),
         Date(timeIntervalSinceReferenceDate: 800_000_000 + 8 * day)]   // same instant twice = two cooks
    }

    private func writeBlob(_ dates: [Date]) {
        storage.setEncodable(dates, forKey: blobKey)
    }

    private func migrated() -> Bool {
        storage.bool(forKey: LegacyBlobMigration.flagKey(for: blobKey))
    }

    private func manager(_ store: any CookDateStoring) -> CookingStreakManager {
        CookingStreakManager(storage: storage, cookDateStore: store,
                             reminders: CookingStreakManagerTests.FakeStreakReminderScheduler())
    }

    // MARK: - Migration

    @Test func everyBlobCookBecomesARowAndTheKeyIsMarked() {
        writeBlob(cooks)
        let store = InMemoryCookDateStore()
        let sut = manager(store)
        #expect(store.dates.sorted() == cooks.sorted())
        #expect(sut.recordedCookDates.count == 3)
        #expect(migrated())
    }

    @Test func theOldBlobIsKeptForOneRelease() {
        writeBlob(cooks)
        _ = manager(InMemoryCookDateStore())
        #expect(storage.decodable([Date].self, forKey: blobKey) == cooks)
    }

    @Test func aRetryAfterAHalfFinishedRunWritesOnlyWhatIsMissing() {
        writeBlob(cooks)
        let store = InMemoryCookDateStore([cooks[0]])   // first run saved one row, then the app died
        _ = manager(store)
        #expect(store.dates.sorted() == cooks.sorted())
    }

    @Test func aMigratedKeyIsNotMigratedAgain() {
        writeBlob(cooks)
        let store = InMemoryCookDateStore()
        _ = manager(store)
        store.dates = []   // e.g. cleared since; the blob must not resurrect it
        let again = manager(store)
        #expect(again.recordedCookDates.isEmpty)
    }

    @Test func noBlobMeansNothingToMoveAndIsMarked() {
        let result = LegacyBlobMigration.run(blobKey: blobKey, as: Date.self, storage: storage,
                                             fetch: { [] }, insert: { _ in Issue.record("nothing to insert") })
        #expect(result == .nothingToMigrate)
        #expect(migrated())
    }

    @Test func aCorruptBlobIsKeptAsideAndNotMigrated() {
        storage.set(Data("not json".utf8), forKey: blobKey)
        let store = InMemoryCookDateStore()
        let sut = manager(store)
        #expect(sut.recordedCookDates.isEmpty)
        #expect(store.dates.isEmpty)
        #expect(storage.data(forKey: blobKey + ".corrupt") == Data("not json".utf8))
    }

    @Test func aFailedWriteLeavesTheKeyUnmarkedAndTheCookKeepsTheirStreak() {
        writeBlob(cooks)
        let store = InMemoryCookDateStore()
        store.failWrites = true
        let sut = manager(store)
        #expect(!migrated())
        #expect(sut.recordedCookDates == cooks)   // fell back to the blob
    }

    @Test func aWriteThatDoesNotStickFailsTheCountCheck() {
        writeBlob(cooks)
        let store = InMemoryCookDateStore()
        store.dropWrites = true
        let result = LegacyBlobMigration.run(blobKey: blobKey, as: Date.self, storage: storage,
                                             fetch: { try store.fetchCookDates() },
                                             insert: { try store.addCookDates($0) })
        #expect(result == .failed)
        #expect(!migrated())
    }

    @Test func cooksRecordedWhileTheMoveFailedAreMovedNextLaunch() {
        writeBlob(cooks)
        let store = InMemoryCookDateStore()
        store.failWrites = true
        let firstLaunch = manager(store)
        let tonight = Date(timeIntervalSinceReferenceDate: 800_000_000 + 20 * day)
        firstLaunch.recordCook(on: tonight)

        store.failWrites = false
        let nextLaunch = manager(store)
        #expect(migrated())
        #expect(nextLaunch.recordedCookDates == (cooks + [tonight]).sorted())
    }

    @Test(arguments: [
        ([1, 2, 2], [3]),
        ([2], [1, 2, 3]),
        ([3, 9], [1, 2, 2]),
        ([], [1, 2, 2, 3]),
    ])
    func subtractingCountsDuplicates(present: [Int], expectedMissing: [Int]) {
        #expect(LegacyBlobMigration.subtracting(present, from: [1, 2, 2, 3]) == expectedMissing)
    }

    // MARK: - Manager on entities

    @Test func newCooksGoToTheStoreNotTheBlob() {
        let store = InMemoryCookDateStore()
        let sut = manager(store)
        sut.recordCook(on: cooks[0])
        #expect(store.dates == [cooks[0]])
        #expect(storage.data(forKey: blobKey) == nil)
    }

    @Test func mergeAddsOnlyNewCooks() {
        let store = InMemoryCookDateStore([cooks[0]])
        let sut = manager(store)
        sut.merge(cookDates: [cooks[0], cooks[1]])
        #expect(store.dates.sorted() == [cooks[0], cooks[1]])
        #expect(sut.recordedCookDates == [cooks[0], cooks[1]])
    }

    @Test func removeAllCookDatesEmptiesTheStoreAndTheStreak() {
        let store = InMemoryCookDateStore([Date()])
        let sut = manager(store)
        sut.removeAllCookDates()
        #expect(store.dates.isEmpty)
        #expect(sut.streak == .empty)
    }

    @Test func aCookRecordedWhileTheStoreCannotBeReadIsKeptNextLaunch() {
        let store = InMemoryCookDateStore([cooks[0]])
        _ = manager(store)                     // migrated, flag set
        store.failReads = true
        let brokenLaunch = manager(store)
        let tonight = Date(timeIntervalSinceReferenceDate: 800_000_000 + 20 * day)
        brokenLaunch.recordCook(on: tonight)

        store.failReads = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.recordedCookDates == [cooks[0], tonight])
    }

    @Test func aCookWhoseSaveFailsIsKeptNextLaunch() {
        let store = InMemoryCookDateStore([cooks[0]])
        let sut = manager(store)
        store.failWrites = true
        let tonight = Date(timeIntervalSinceReferenceDate: 800_000_000 + 20 * day)
        sut.recordCook(on: tonight)

        store.failWrites = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.recordedCookDates == [cooks[0], tonight])
        #expect(store.dates.sorted() == [cooks[0], tonight])
    }

    @Test func aResetWhoseDeleteFailsIsFinishedNextLaunch() {
        let store = InMemoryCookDateStore(cooks)
        let sut = manager(store)
        store.failWrites = true
        sut.removeAllCookDates()
        #expect(sut.streak == .empty)

        store.failWrites = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.recordedCookDates.isEmpty)
        #expect(store.dates.isEmpty)
    }

    @Test func cooksAfterAFailedResetSurviveTheRetriedWipe() {
        let store = InMemoryCookDateStore(cooks)
        let sut = manager(store)
        store.failWrites = true
        sut.removeAllCookDates()
        let tonight = Date(timeIntervalSinceReferenceDate: 800_000_000 + 20 * day)
        sut.recordCook(on: tonight)

        store.failWrites = false
        let nextLaunch = manager(store)
        #expect(nextLaunch.recordedCookDates == [tonight])
    }

    // MARK: - Core Data store (framework exemption: in-memory SQLite, like CoreDataStorePersistenceTests)

    @Test func coreDataStoreRoundTripsDatesOldestFirst() throws {
        let sut = CoreDataCookDateStore(persistence: PersistenceController(inMemory: true))
        try sut.addCookDates([cooks[1], cooks[0], cooks[2]])
        #expect(try sut.fetchCookDates() == cooks.sorted())
        try sut.deleteAllCookDates()
        #expect(try sut.fetchCookDates().isEmpty)
    }

    @Test func coreDataRowsGetAnIdForSync() throws {
        let persistence = PersistenceController(inMemory: true)
        try CoreDataCookDateStore(persistence: persistence).addCookDates([cooks[0]])
        let request = NSFetchRequest<NSManagedObject>(entityName: CoreDataCookDateStore.entityName)
        let rows = try persistence.container.viewContext.fetch(request)
        #expect(rows.count == 1)
        #expect(rows.first?.value(forKey: "id") is UUID)
    }

    @Test func blobMovesIntoARealStoreAndSurvivesARelaunch() {
        writeBlob(cooks)
        let persistence = PersistenceController(inMemory: true)
        _ = manager(CoreDataCookDateStore(persistence: persistence))
        let relaunch = manager(CoreDataCookDateStore(persistence: persistence))
        #expect(relaunch.recordedCookDates == cooks.sorted())
        #expect(migrated())
    }
}
