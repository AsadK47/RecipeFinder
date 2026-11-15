import Testing
import CoreData
import Foundation
@testable import RecipeFinder

/// Data safety 2/4 slice 3b: lists re-read the store when another device's edits arrive through iCloud.
@MainActor
@Suite struct RemoteChangeReloaderTests {
    /// Counts reloads per list so a test can see every list was re-read, and how often.
    @MainActor final class Lists {
        var recipes = 0
        var plans = 0
        var checks = 0

        var reloads: [@MainActor () async -> Void] {
            [{ self.recipes += 1 }, { self.plans += 1 }]
        }
    }

    /// Holds the outside-change check open until the test answers it.
    @MainActor final class Gate {
        private var continuation: CheckedContinuation<Bool, Never>?
        var isWaiting: Bool { continuation != nil }

        func answer() async -> Bool {
            await withCheckedContinuation { continuation = $0 }
        }

        func open(with answer: Bool) {
            continuation?.resume(returning: answer)
            continuation = nil
        }
    }

    @Test func anotherDevicesEditReloadsEveryList() async {
        let lists = Lists()
        let reloader = RemoteChangeReloader(delay: .zero, hasOutsideChanges: { true }, reloads: lists.reloads)

        reloader.storeChanged()
        await reloader.waitUntilIdle()

        #expect(lists.recipes == 1)
        #expect(lists.plans == 1)
    }

    @Test func thisDevicesOwnSaveReloadsNothing() async {
        let lists = Lists()
        let reloader = RemoteChangeReloader(delay: .zero, hasOutsideChanges: { false }, reloads: lists.reloads)

        reloader.storeChanged()
        await reloader.waitUntilIdle()

        #expect(lists.recipes == 0)
        #expect(lists.plans == 0)
    }

    @Test func aBurstOfStoreChangesReloadsOnce() async {
        let lists = Lists()
        let reloader = RemoteChangeReloader(
            delay: .milliseconds(50),
            hasOutsideChanges: { lists.checks += 1; return true },
            reloads: lists.reloads
        )

        reloader.storeChanged()
        reloader.storeChanged()
        reloader.storeChanged()
        await reloader.waitUntilIdle()

        #expect(lists.checks == 1)
        #expect(lists.recipes == 1)
    }

    @Test func aChangeAfterAReloadGetsItsOwnReload() async {
        let lists = Lists()
        let reloader = RemoteChangeReloader(delay: .zero, hasOutsideChanges: { true }, reloads: lists.reloads)

        reloader.storeChanged()
        await reloader.waitUntilIdle()
        reloader.storeChanged()
        await reloader.waitUntilIdle()

        #expect(lists.recipes == 2)
    }

    /// Issue #16: reading the store's history after an iCloud import burst held the main thread, freezing the
    /// screen (a badge reveal stuck mid-flip). The check is awaited, so the main actor keeps running meanwhile.
    @Test func theMainActorStaysFreeWhileTheCheckRuns() async throws {
        let lists = Lists()
        let gate = Gate()
        let reloader = RemoteChangeReloader(
            delay: .zero, hasOutsideChanges: { await gate.answer() }, reloads: lists.reloads
        )

        reloader.storeChanged()
        try await Self.waitFor { gate.isWaiting }
        let reloadedDuringTheCheck = lists.recipes
        gate.open(with: true)
        try await Self.waitFor { lists.recipes == 1 }

        #expect(reloadedDuringTheCheck == 0)
        #expect(lists.recipes == 1)
    }

    @Test func theStoresRemoteChangeNotificationSchedulesAReload() async throws {
        let center = NotificationCenter()
        let persistence = PersistenceController(inMemory: true)
        let coordinator = persistence.container.persistentStoreCoordinator
        let lists = Lists()
        let reloader = RemoteChangeReloader(delay: .zero, hasOutsideChanges: { true }, reloads: lists.reloads)
        reloader.observe(coordinator, in: center)

        center.post(name: .NSPersistentStoreRemoteChange, object: coordinator)
        try await Self.waitFor { lists.recipes == 1 }

        #expect(lists.recipes == 1)
    }

    @Test func anotherStoresNotificationIsIgnored() async throws {
        let center = NotificationCenter()
        let watched = PersistenceController(inMemory: true).container.persistentStoreCoordinator
        let other = PersistenceController(inMemory: true).container.persistentStoreCoordinator
        let lists = Lists()
        let reloader = RemoteChangeReloader(delay: .zero, hasOutsideChanges: { true }, reloads: lists.reloads)
        reloader.observe(watched, in: center)

        center.post(name: .NSPersistentStoreRemoteChange, object: other)
        try await Task.sleep(for: .milliseconds(200))
        await reloader.waitUntilIdle()

        #expect(lists.recipes == 0)
        #expect(!reloader.isReloadPending)
    }

    /// Polls for a condition the notification's main-actor hop makes true a moment after posting (2 s cap).
    private static func waitFor(_ condition: @MainActor () -> Bool) async throws {
        for _ in 0..<200 where !condition() {
            try await Task.sleep(for: .milliseconds(10))
        }
    }
}

/// Telling another device's edits (CloudKit's importer names its writes) from this app's own (never named).
@MainActor
@Suite struct OutsideChangeHistoryTests {
    private static let importer = "NSCloudKitMirroringDelegate.import"

    private static func addRecipe(named name: String, to persistence: PersistenceController, author: String?) throws {
        let context = persistence.container.viewContext
        context.transactionAuthor = author
        defer { context.transactionAuthor = nil }
        let recipe = NSEntityDescription.insertNewObject(forEntityName: "Recipe", into: context)
        recipe.setValue(name, forKey: "name")
        recipe.setValue(UUID(), forKey: "id")
        try context.save()
    }

    @Test func anICloudImportIsAnOutsideChange() async throws {
        let persistence = PersistenceController(inMemory: true)
        persistence.startTrackingOutsideChanges()

        try Self.addRecipe(named: "Soup from the iPad", to: persistence, author: Self.importer)

        #expect(await persistence.takeOutsideChanges())
    }

    @Test func thisAppsOwnSaveIsNotAnOutsideChange() async throws {
        let persistence = PersistenceController(inMemory: true)
        persistence.startTrackingOutsideChanges()

        try Self.addRecipe(named: "Soup from here", to: persistence, author: nil)

        #expect(await !persistence.takeOutsideChanges())
    }

    @Test func anOutsideChangeIsReportedOnce() async throws {
        let persistence = PersistenceController(inMemory: true)
        persistence.startTrackingOutsideChanges()
        try Self.addRecipe(named: "Soup from the iPad", to: persistence, author: Self.importer)

        #expect(await persistence.takeOutsideChanges())
        #expect(await !persistence.takeOutsideChanges())
    }

    @Test func importsBeforeTrackingStartedAreNotReported() async throws {
        let persistence = PersistenceController(inMemory: true)
        try Self.addRecipe(named: "Soup already on screen", to: persistence, author: Self.importer)

        persistence.startTrackingOutsideChanges()

        #expect(await !persistence.takeOutsideChanges())
    }

    @Test func anImportAfterThisAppsOwnSaveIsStillSeen() async throws {
        let persistence = PersistenceController(inMemory: true)
        persistence.startTrackingOutsideChanges()
        try Self.addRecipe(named: "Soup from here", to: persistence, author: nil)
        try Self.addRecipe(named: "Soup from the iPad", to: persistence, author: Self.importer)

        #expect(await persistence.takeOutsideChanges())
    }

    /// Checks run one after another (the history is read off the main thread now), so two at once report an import
    /// once and the checkpoint never moves back.
    @Test func twoChecksAtOnceReportAnImportOnce() async throws {
        let persistence = PersistenceController(inMemory: true)
        persistence.startTrackingOutsideChanges()
        try Self.addRecipe(named: "Soup from the iPad", to: persistence, author: Self.importer)

        async let first = persistence.takeOutsideChanges()
        async let second = persistence.takeOutsideChanges()
        let results = await [first, second]

        #expect(results.filter { $0 }.count == 1)
        #expect(await !persistence.takeOutsideChanges())
    }

    @Test func syncIsOffForAStoreOpenedWithoutICloud() {
        #expect(!PersistenceController(inMemory: true).isSyncing)
    }
}

/// Old store history is purged at launch so it can't grow forever (Data safety 2/4 slice 4a).
@MainActor
@Suite struct StoreHistoryPurgeTests {
    private static let importer = "NSCloudKitMirroringDelegate.import"

    private static func addRecipe(named name: String, to persistence: PersistenceController, author: String?) throws {
        let context = persistence.container.viewContext
        context.transactionAuthor = author
        defer { context.transactionAuthor = nil }
        let recipe = NSEntityDescription.insertNewObject(forEntityName: "Recipe", into: context)
        recipe.setValue(name, forKey: "name")
        recipe.setValue(UUID(), forKey: "id")
        try context.save()
    }

    private static func historyCount(in persistence: PersistenceController) throws -> Int {
        let request = NSPersistentHistoryChangeRequest.fetchHistory(after: Date.distantPast)
        let result = try persistence.container.viewContext.execute(request) as? NSPersistentHistoryResult
        return (result?.result as? [NSPersistentHistoryTransaction])?.count ?? 0
    }

    private static func recipeCount(in persistence: PersistenceController) throws -> Int {
        try persistence.container.viewContext.count(for: NSFetchRequest<NSManagedObject>(entityName: "Recipe"))
    }

    @Test func historyIsKeptForAWeek() {
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

        #expect(PersistenceController.historyPurgeCutoff(now: now) == now.addingTimeInterval(-7 * 24 * 60 * 60))
    }

    @Test func historyBeforeTheCutoffIsRemoved() async throws {
        let persistence = PersistenceController(inMemory: true)
        try Self.addRecipe(named: "Old soup", to: persistence, author: nil)
        #expect(try Self.historyCount(in: persistence) > 0)

        let purged = await persistence.purgeHistory(before: Date().addingTimeInterval(60))

        #expect(purged)
        #expect(try Self.historyCount(in: persistence) == 0)
    }

    @Test func historyAfterTheCutoffIsKept() async throws {
        let persistence = PersistenceController(inMemory: true)
        try Self.addRecipe(named: "Fresh soup", to: persistence, author: nil)
        let before = try Self.historyCount(in: persistence)

        await persistence.purgeHistory(before: Date().addingTimeInterval(-60))

        #expect(before > 0)
        #expect(try Self.historyCount(in: persistence) == before)
    }

    @Test func purgingHistoryKeepsTheRecipes() async throws {
        let persistence = PersistenceController(inMemory: true)
        try Self.addRecipe(named: "Soup", to: persistence, author: nil)
        try Self.addRecipe(named: "Stew", to: persistence, author: nil)

        await persistence.purgeHistory(before: Date().addingTimeInterval(60))

        #expect(try Self.recipeCount(in: persistence) == 2)
    }

    @Test func anImportAfterAPurgeThatKeptTheCheckpointIsSeen() async throws {
        let persistence = PersistenceController(inMemory: true)
        try Self.addRecipe(named: "Old soup", to: persistence, author: nil)
        try await Task.sleep(for: .milliseconds(50))
        let cutoff = Date()
        try await Task.sleep(for: .milliseconds(50))
        try Self.addRecipe(named: "Soup from here", to: persistence, author: nil)
        persistence.startTrackingOutsideChanges()

        await persistence.purgeHistory(before: cutoff)
        try Self.addRecipe(named: "Soup from the iPad", to: persistence, author: Self.importer)

        #expect(await persistence.takeOutsideChanges())
        #expect(await !persistence.takeOutsideChanges())
    }

    @Test func aPurgedCheckpointReloadsOnceThenReadsOn() async throws {
        let persistence = PersistenceController(inMemory: true)
        persistence.startTrackingOutsideChanges()
        try Self.addRecipe(named: "Soup from here", to: persistence, author: nil)
        #expect(await !persistence.takeOutsideChanges())

        await persistence.purgeHistory(before: Date().addingTimeInterval(60))
        try Self.addRecipe(named: "Soup from the iPad", to: persistence, author: Self.importer)

        #expect(await persistence.takeOutsideChanges())
        #expect(await !persistence.takeOutsideChanges())
    }
}

/// Once sync has been on, CloudKit sends changes from the store's history, so the launch purge keeps everything it
/// hasn't sent yet: sync off, paused or failing to export for weeks loses nothing (Inbox 🔴 2026-11-14).
@MainActor
@Suite struct HistoryPurgeRuleTests {
    private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
    private let week = PersistenceController.historyKeptFor
    private let day: TimeInterval = 24 * 60 * 60
    private func storage() -> LocalStore { LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!) }

    @Test func aDeviceThatNeverSyncedPurgesAfterAWeek() {
        #expect(HistoryPurgeRule.cutoff(now: now, everSynced: false, lastExportStart: nil) == now.addingTimeInterval(-week))
    }

    @Test func aDeviceThatSyncedButNeverExportedKeepsAllHistory() {
        #expect(HistoryPurgeRule.cutoff(now: now, everSynced: true, lastExportStart: nil) == nil)
    }

    @Test func syncOffForAMonthKeepsEverythingSinceTheLastExport() {
        let lastExport = now.addingTimeInterval(-30 * day)
        #expect(HistoryPurgeRule.cutoff(now: now, everSynced: true, lastExportStart: lastExport) == lastExport)
    }

    @Test func aRecentExportStillKeepsTheLastWeek() {
        let lastExport = now.addingTimeInterval(-60)
        let cutoff = HistoryPurgeRule.cutoff(now: now, everSynced: true, lastExportStart: lastExport)
        #expect(cutoff == now.addingTimeInterval(-week))
    }

    @Test func onlyAFinishedSuccessfulExportCountsAsSent() {
        let start = now.addingTimeInterval(-10)
        #expect(HistoryPurgeRule.sentUpTo(isExport: true, succeeded: true, startDate: start, endDate: now) == start)
        #expect(HistoryPurgeRule.sentUpTo(isExport: true, succeeded: false, startDate: start, endDate: now) == nil)
        #expect(HistoryPurgeRule.sentUpTo(isExport: true, succeeded: false, startDate: start, endDate: nil) == nil)
        #expect(HistoryPurgeRule.sentUpTo(isExport: false, succeeded: true, startDate: start, endDate: now) == nil)
    }

    @Test func anOlderExportReportedLateDoesNotMoveTheMarkBack() {
        let storage = storage()
        HistoryPurgeRule.recordExport(startedAt: now, in: storage)
        HistoryPurgeRule.recordExport(startedAt: now.addingTimeInterval(-day), in: storage)

        #expect(HistoryPurgeRule.lastExportStart(in: storage) == now)
    }

    @Test func aNewerExportMovesTheMarkOn() {
        let storage = storage()
        HistoryPurgeRule.recordExport(startedAt: now.addingTimeInterval(-day), in: storage)
        HistoryPurgeRule.recordExport(startedAt: now, in: storage)

        #expect(HistoryPurgeRule.lastExportStart(in: storage) == now)
    }

    @Test func aDeviceWithSyncTurnedOffAfterAnExportPurgesOnlyWhatWasSent() {
        let storage = storage()
        storage.set(true, forKey: SyncPreference.everSyncedKey)
        let lastExport = now.addingTimeInterval(-20 * day)
        HistoryPurgeRule.recordExport(startedAt: lastExport, in: storage)

        #expect(HistoryPurgeRule.cutoff(now: now, in: storage) == lastExport)
    }

    @Test func aDeviceThatNeverSyncedPurgesFromStorage() {
        #expect(HistoryPurgeRule.cutoff(now: now, in: storage()) == now.addingTimeInterval(-week))
    }

    @Test func syncOnWithNoExportYetKeepsAllHistory() {
        let storage = storage()
        storage.set(true, forKey: SyncPreference.key)

        #expect(HistoryPurgeRule.cutoff(now: now, in: storage) == nil)
    }
}
