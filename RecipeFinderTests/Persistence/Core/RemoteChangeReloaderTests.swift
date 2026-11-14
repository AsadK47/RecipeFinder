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
