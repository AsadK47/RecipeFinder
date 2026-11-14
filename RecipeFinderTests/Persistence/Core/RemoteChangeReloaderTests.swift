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

    @Test func anICloudImportIsAnOutsideChange() throws {
        let persistence = PersistenceController(inMemory: true)
        persistence.startTrackingOutsideChanges()

        try Self.addRecipe(named: "Soup from the iPad", to: persistence, author: Self.importer)

        #expect(persistence.takeOutsideChanges())
    }

    @Test func thisAppsOwnSaveIsNotAnOutsideChange() throws {
        let persistence = PersistenceController(inMemory: true)
        persistence.startTrackingOutsideChanges()

        try Self.addRecipe(named: "Soup from here", to: persistence, author: nil)

        #expect(!persistence.takeOutsideChanges())
    }

    @Test func anOutsideChangeIsReportedOnce() throws {
        let persistence = PersistenceController(inMemory: true)
        persistence.startTrackingOutsideChanges()
        try Self.addRecipe(named: "Soup from the iPad", to: persistence, author: Self.importer)

        #expect(persistence.takeOutsideChanges())
        #expect(!persistence.takeOutsideChanges())
    }

    @Test func importsBeforeTrackingStartedAreNotReported() throws {
        let persistence = PersistenceController(inMemory: true)
        try Self.addRecipe(named: "Soup already on screen", to: persistence, author: Self.importer)

        persistence.startTrackingOutsideChanges()

        #expect(!persistence.takeOutsideChanges())
    }

    @Test func anImportAfterThisAppsOwnSaveIsStillSeen() throws {
        let persistence = PersistenceController(inMemory: true)
        persistence.startTrackingOutsideChanges()
        try Self.addRecipe(named: "Soup from here", to: persistence, author: nil)
        try Self.addRecipe(named: "Soup from the iPad", to: persistence, author: Self.importer)

        #expect(persistence.takeOutsideChanges())
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

    @Test func anImportAfterThePurgeIsStillSeenOnce() async throws {
        let persistence = PersistenceController(inMemory: true)
        persistence.startTrackingOutsideChanges()
        try Self.addRecipe(named: "Soup from here", to: persistence, author: nil)
        #expect(!persistence.takeOutsideChanges())

        await persistence.purgeHistory(before: Date().addingTimeInterval(60))
        try Self.addRecipe(named: "Soup from the iPad", to: persistence, author: Self.importer)

        #expect(persistence.takeOutsideChanges())
        #expect(!persistence.takeOutsideChanges())
    }
}
