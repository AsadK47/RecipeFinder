import Testing
import Foundation
@testable import RecipeFinder

/// Cook dates with iCloud sync on (Data safety 2/4): a Reset on another device must stay a Reset here, while a store
/// emptied by recovery still gets this device's kept copy back.
@MainActor
@Suite struct CookDateSyncTests {
    private let blobKey = "cookDatesLog"
    private let storage = LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
    private let cooks = [Date(timeIntervalSinceReferenceDate: 800_000_000),
                         Date(timeIntervalSinceReferenceDate: 800_691_200)]

    private func manager(_ store: InMemoryCookDateStore, syncOn: Bool = true) -> CookingStreakManager {
        storage.set(syncOn, forKey: SyncPreference.key)
        return CookingStreakManager(storage: storage, cookDateStore: store,
                                    reminders: CookingStreakManagerTests.FakeStreakReminderScheduler())
    }

    private var keptCopy: [Date]? { storage.decodable([Date].self, forKey: blobKey) }

    @Test func aResetOnAnotherDeviceStaysGoneWhenThisDeviceReloads() {
        storage.setEncodable(cooks, forKey: blobKey)
        let store = InMemoryCookDateStore(cooks)
        store.storeFileID = "file-1"
        let sut = manager(store)
        #expect(sut.recordedCookDates == cooks)

        store.dates = []   // the other device's Reset arrives from iCloud
        sut.reload()

        #expect(sut.recordedCookDates.isEmpty)
        #expect(store.dates.isEmpty)
        #expect(keptCopy == nil)
    }

    @Test func aResetOnAnotherDeviceWhileThisAppWasClosedStaysGone() {
        storage.setEncodable(cooks, forKey: blobKey)
        let store = InMemoryCookDateStore(cooks)
        store.storeFileID = "file-1"
        _ = manager(store)

        store.dates = []
        let nextLaunch = manager(store)

        #expect(nextLaunch.recordedCookDates.isEmpty)
        #expect(store.dates.isEmpty)
    }

    @Test func aFreshStoreFileGetsTheKeptCopyBackAtLaunch() {
        storage.setEncodable(cooks, forKey: blobKey)
        let store = InMemoryCookDateStore(cooks)
        store.storeFileID = "file-1"
        _ = manager(store)

        store.dates = []              // recovery replaced an unreadable store with a new, empty file
        store.storeFileID = "file-2"
        let nextLaunch = manager(store)

        #expect(nextLaunch.recordedCookDates == cooks)
        #expect(store.dates.sorted() == cooks)
    }

    @Test func anUnknownStoreFileGetsTheKeptCopyBackAtLaunch() {
        storage.setEncodable(cooks, forKey: blobKey)
        let store = InMemoryCookDateStore(cooks)
        _ = manager(store)

        store.dates = []
        let nextLaunch = manager(store)

        #expect(nextLaunch.recordedCookDates == cooks)
    }

    @Test func aStoreFileSeenOnlyWithSyncOffStillGetsTheKeptCopyBack() {
        storage.setEncodable(cooks, forKey: blobKey)
        let store = InMemoryCookDateStore(cooks)
        store.storeFileID = "file-1"
        _ = manager(store, syncOn: false)

        store.dates = []
        let nextLaunch = manager(store)

        #expect(nextLaunch.recordedCookDates == cooks)
    }

    @Test func cooksRecordedAfterFollowingAResetAreKept() {
        storage.setEncodable(cooks, forKey: blobKey)
        let store = InMemoryCookDateStore(cooks)
        store.storeFileID = "file-1"
        let sut = manager(store)
        store.dates = []
        sut.reload()

        let tonight = Date(timeIntervalSinceReferenceDate: 801_000_000)
        sut.recordCook(on: tonight)

        #expect(store.dates == [tonight])
        #expect(keptCopy == [tonight])
        #expect(manager(store).recordedCookDates == [tonight])
    }

    @Test func aResetElsewhereIsFollowedOnReloadEvenWhenTheStoreFileIsUnknown() {
        storage.setEncodable(cooks, forKey: blobKey)
        let store = InMemoryCookDateStore(cooks)   // storeFileID nil: only this launch's own load proves it's shared
        let sut = manager(store)

        store.dates = []
        sut.reload()

        #expect(sut.recordedCookDates.isEmpty)
        #expect(keptCopy == nil)
    }

    @Test func theKeptCopyFollowsAStorePartlyErasedElsewhere() {
        storage.setEncodable(cooks, forKey: blobKey)
        let store = InMemoryCookDateStore(cooks)
        store.storeFileID = "file-1"
        let sut = manager(store)

        let tonight = Date(timeIntervalSinceReferenceDate: 801_000_000)
        store.dates = [tonight]   // Reset elsewhere, then a new cook there
        sut.reload()
        #expect(keptCopy == [tonight])

        store.dates = []          // recovery: a fresh, empty file
        store.storeFileID = "file-2"
        #expect(manager(store).recordedCookDates == [tonight])
    }

    @Test func otherDevicesCooksReachTheKeptCopy() {
        let store = InMemoryCookDateStore(cooks)
        store.storeFileID = "file-1"
        _ = manager(store)
        #expect(keptCopy == cooks)
    }
}
