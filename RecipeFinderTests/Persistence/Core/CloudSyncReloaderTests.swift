import CoreData
import Foundation
import Testing
@testable import RecipeFinder

/// Data safety 2/4 slice 3a: the store is CloudKit-ready (history + remote-change notifications) and every list
/// reloads when iCloud imports another device's changes — but never for this device's own saves.
@MainActor
@Suite struct CloudSyncReloaderTests {

    /// File-backed store: persistent history needs a real SQLite file to read back transactions.
    private func makeController() throws -> (PersistenceController, URL) {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("CloudSyncReloaderTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let controller = PersistenceController(storeURL: folder.appendingPathComponent("Store.sqlite"))
        #expect(controller.isStoreLoaded)
        return (controller, folder)
    }

    /// Saves one recipe row the way `author` would (CloudKit's importer, or this app when nil).
    private func saveRecipe(in controller: PersistenceController, author: String?) throws {
        let context = controller.container.newBackgroundContext()
        context.transactionAuthor = author
        try context.performAndWait {
            let row = NSEntityDescription.insertNewObject(forEntityName: PersistenceController.Entity.recipe, into: context)
            row.setValue(UUID(), forKey: PersistenceController.RecipeKey.id)
            row.setValue("Tomato Soup", forKey: PersistenceController.RecipeKey.name)
            try context.save()
        }
    }

    private final class Counter { var reloads = 0 }

    private func makeReloader(_ controller: PersistenceController, _ counter: Counter) -> CloudSyncReloader {
        CloudSyncReloader(container: controller.container, settleDelay: .zero) { counter.reloads += 1 }
    }

    // MARK: - Store options

    @Test func theStoreTracksHistoryAndPostsRemoteChanges() {
        let controller = PersistenceController(inMemory: true)
        let options = controller.container.persistentStoreDescriptions.first?.options
        #expect((options?[NSPersistentHistoryTrackingKey] as? NSNumber)?.boolValue == true)
        #expect((options?[NSPersistentStoreRemoteChangeNotificationPostOptionKey] as? NSNumber)?.boolValue == true)
    }

    @Test func iCloudMirroringIsOffWhileTheSyncSwitchIsOff() {
        #expect(PersistenceController.cloudKitOptions(syncOn: false, isAppStore: true) == nil)
        let controller = PersistenceController(inMemory: true)
        #expect(controller.container.persistentStoreDescriptions.first?.cloudKitContainerOptions == nil)
    }

    @Test func iCloudMirroringUsesTheAppsPrivateContainerWhenSyncIsOn() {
        let options = PersistenceController.cloudKitOptions(syncOn: true, isAppStore: true)
        #expect(options?.containerIdentifier == "iCloud.com.asadkhan.recipefinder")
        #expect(options?.databaseScope == .private)
    }

    /// Test and preview stores never talk to iCloud, even with the switch on.
    @Test func storesForTestsNeverMirrorToICloud() {
        #expect(PersistenceController.cloudKitOptions(syncOn: true, isAppStore: false) == nil)
    }

    // MARK: - Reload on import

    @Test func onlyCloudKitImportsCountAsAnotherDevicesChange() {
        #expect(CloudSyncReloader.containsCloudImport(authors: [nil, "NSCloudKitMirroringDelegate.import"]))
        #expect(!CloudSyncReloader.containsCloudImport(authors: [nil, "NSCloudKitMirroringDelegate.export", "app"]))
        #expect(!CloudSyncReloader.containsCloudImport(authors: []))
    }

    @Test func aChangeImportedFromICloudReloadsTheLists() throws {
        let (controller, folder) = try makeController()
        defer { try? FileManager.default.removeItem(at: folder) }
        let counter = Counter()
        let reloader = makeReloader(controller, counter)

        try saveRecipe(in: controller, author: CloudSyncReloader.importAuthorPrefix)
        reloader.checkForCloudChanges()

        #expect(counter.reloads == 1)
    }

    @Test func thisDevicesOwnSaveDoesNotReload() throws {
        let (controller, folder) = try makeController()
        defer { try? FileManager.default.removeItem(at: folder) }
        let counter = Counter()
        let reloader = makeReloader(controller, counter)

        try saveRecipe(in: controller, author: nil)
        reloader.checkForCloudChanges()

        #expect(counter.reloads == 0)
    }

    /// Changes from before the app started are already on screen from launch — no reload for them.
    @Test func anImportFromBeforeLaunchDoesNotReload() throws {
        let (controller, folder) = try makeController()
        defer { try? FileManager.default.removeItem(at: folder) }
        try saveRecipe(in: controller, author: CloudSyncReloader.importAuthorPrefix)
        let counter = Counter()
        let reloader = makeReloader(controller, counter)

        reloader.checkForCloudChanges()

        #expect(counter.reloads == 0)
    }

    @Test func eachImportReloadsOnce() throws {
        let (controller, folder) = try makeController()
        defer { try? FileManager.default.removeItem(at: folder) }
        let counter = Counter()
        let reloader = makeReloader(controller, counter)

        try saveRecipe(in: controller, author: CloudSyncReloader.importAuthorPrefix)
        reloader.checkForCloudChanges()
        reloader.checkForCloudChanges()
        try saveRecipe(in: controller, author: nil)
        reloader.checkForCloudChanges()

        #expect(counter.reloads == 1)
    }

    @Test func theStoresRemoteChangeNotificationTriggersTheCheck() async throws {
        let (controller, folder) = try makeController()
        defer { try? FileManager.default.removeItem(at: folder) }
        let counter = Counter()
        let reloader = makeReloader(controller, counter)
        reloader.start()

        try saveRecipe(in: controller, author: CloudSyncReloader.importAuthorPrefix)
        NotificationCenter.default.post(
            name: .NSPersistentStoreRemoteChange, object: controller.container.persistentStoreCoordinator
        )
        for _ in 0..<40 where counter.reloads == 0 {
            try await Task.sleep(for: .milliseconds(50))
        }

        #expect(counter.reloads >= 1)
        reloader.stop()
    }
}
