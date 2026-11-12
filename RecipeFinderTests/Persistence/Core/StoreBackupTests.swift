import Testing
import CoreData
import Foundation
@testable import RecipeFinder

/// Store copies taken before Core Data migrates the recipe database. Uses real temp files and SQLite stores
/// (Core Data framework exemption — the metadata check and migration are Apple's).
@MainActor
@Suite struct StoreBackupTests {
    private let root = FileManager.default.temporaryDirectory.appendingPathComponent("StoreBackupTests-\(UUID().uuidString)")
    private var storeURL: URL { root.appendingPathComponent("Store/RecipeModel.sqlite") }
    private var backups: URL { root.appendingPathComponent("StoreBackups") }

    private func writeStoreFiles(_ sidecars: [String] = ["", "-wal", "-shm"]) throws {
        try FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        for sidecar in sidecars {
            try Data("store\(sidecar)".utf8).write(to: URL(fileURLWithPath: storeURL.path + sidecar))
        }
    }

    private func backupFolders() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: backups.path).filter { $0.hasPrefix(StoreBackup.folderPrefix) }.sorted()
    }

    private func cleanUp() { try? FileManager.default.removeItem(at: root) }

    // MARK: - Copying

    @Test func backupCopiesTheStoreAndItsSidecars() throws {
        defer { cleanUp() }
        try writeStoreFiles()

        let folder = try #require(try StoreBackup.backUp(storeURL: storeURL, into: backups))

        for sidecar in ["", "-wal", "-shm"] {
            let copy = folder.appendingPathComponent("RecipeModel.sqlite" + sidecar)
            #expect(try Data(contentsOf: copy) == Data("store\(sidecar)".utf8))
        }
    }

    @Test func missingSidecarsAreSkipped() throws {
        defer { cleanUp() }
        try writeStoreFiles([""])

        let folder = try #require(try StoreBackup.backUp(storeURL: storeURL, into: backups))

        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path) == ["RecipeModel.sqlite"])
    }

    @Test func noStoreMeansNoBackup() throws {
        defer { cleanUp() }

        #expect(try StoreBackup.backUp(storeURL: storeURL, into: backups) == nil)
        #expect(!FileManager.default.fileExists(atPath: backups.path))
    }

    @Test func theOriginalStoreIsLeftInPlace() throws {
        defer { cleanUp() }
        try writeStoreFiles()

        try StoreBackup.backUp(storeURL: storeURL, into: backups)

        #expect(try Data(contentsOf: storeURL) == Data("store".utf8))
    }

    // MARK: - Keeping the last three

    @Test func onlyTheNewestThreeBackupsAreKept() throws {
        defer { cleanUp() }
        try writeStoreFiles()
        let start = Date(timeIntervalSince1970: 1_800_000_000)

        var made: [String] = []
        for day in 0..<5 {
            let folder = try #require(try StoreBackup.backUp(storeURL: storeURL, into: backups, now: start.addingTimeInterval(Double(day) * 86_400)))
            made.append(folder.lastPathComponent)
        }

        #expect(try backupFolders() == Array(made.suffix(3)))
    }

    @Test func twoBackupsInTheSameMomentBothSurvive() throws {
        defer { cleanUp() }
        try writeStoreFiles()
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        try StoreBackup.backUp(storeURL: storeURL, into: backups, now: now)
        try StoreBackup.backUp(storeURL: storeURL, into: backups, now: now)

        #expect(try backupFolders().count == 2)
    }

    @Test func otherFilesInTheBackupFolderAreLeftAlone() throws {
        defer { cleanUp() }
        try writeStoreFiles()
        try FileManager.default.createDirectory(at: backups, withIntermediateDirectories: true)
        let note = backups.appendingPathComponent("keep-me.txt")
        try Data("hi".utf8).write(to: note)

        for second in 0..<4 {
            try StoreBackup.backUp(storeURL: storeURL, into: backups, now: Date(timeIntervalSince1970: Double(second)))
        }

        #expect(FileManager.default.fileExists(atPath: note.path))
        #expect(try backupFolders().count == 3)
    }

    @Test func backupsAreKeptOutOfTheDeviceBackup() throws {
        defer { cleanUp() }
        try writeStoreFiles()

        try StoreBackup.backUp(storeURL: storeURL, into: backups)

        #expect(try backups.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true)
    }

    @Test func oldCopiesMakeRoomBeforeTheNewOneIsWritten() throws {
        defer { cleanUp() }
        try writeStoreFiles()
        for second in 0..<3 {
            try StoreBackup.backUp(storeURL: storeURL, into: backups, now: Date(timeIntervalSince1970: Double(second)))
        }
        let before = try backupFolders()
        // A -wal that can't be read makes this copy fail part-way.
        let wal = URL(fileURLWithPath: storeURL.path + "-wal")
        try FileManager.default.removeItem(at: wal)
        try FileManager.default.createDirectory(at: wal, withIntermediateDirectories: false)
        let locked = wal.appendingPathComponent("locked")
        try Data("x".utf8).write(to: locked)
        try FileManager.default.setAttributes([.posixPermissions: 0], ofItemAtPath: locked.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: locked.path) }

        #expect(throws: (any Error).self) {
            try StoreBackup.backUp(storeURL: storeURL, into: backups, now: Date(timeIntervalSince1970: 9))
        }

        #expect(try backupFolders() == Array(before.suffix(2)))
    }

    @Test func folderNamesSortInTimeOrder() {
        let early = StoreBackup.folderName(for: Date(timeIntervalSince1970: 9))
        let late = StoreBackup.folderName(for: Date(timeIntervalSince1970: 10))
        #expect(early < late)
    }

    // MARK: - When a backup is needed

    @Test func aMissingStoreNeedsNoMigration() throws {
        let model = try currentModel()
        #expect(!StoreBackup.needsMigration(storeURL: storeURL, model: model))
    }

    @Test func aStoreFromTheCurrentModelNeedsNoMigration() throws {
        defer { cleanUp() }
        let model = try currentModel()
        try writeStore(with: model)

        #expect(!StoreBackup.needsMigration(storeURL: storeURL, model: model))
    }

    @Test func aStoreFromTheShippedOlderModelNeedsMigration() throws {
        defer { cleanUp() }
        try writeStore(with: try olderModel())

        #expect(StoreBackup.needsMigration(storeURL: storeURL, model: try currentModel()))
    }

    @Test func anUnreadableStoreIsTreatedAsNeedingMigration() throws {
        defer { cleanUp() }
        try writeStoreFiles([""])

        #expect(StoreBackup.needsMigration(storeURL: storeURL, model: try currentModel()))
    }

    // MARK: - Opening the app's store

    @Test func upgradingAnOlderStoreKeepsACopyAndTheRecipes() throws {
        defer { cleanUp() }
        let id = try writeStore(with: try olderModel(), recipeName: "Gran's Stew")

        let controller = PersistenceController(storeURL: storeURL, backupDirectory: backups)

        #expect(controller.isStoreLoaded)
        #expect(try backupFolders().count == 1)
        let request = NSFetchRequest<NSManagedObject>(entityName: "Recipe")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        #expect(try controller.container.viewContext.fetch(request).first?.value(forKey: "name") as? String == "Gran's Stew")
    }

    @Test func theBackupHoldsTheStoreAsItWasBeforeTheUpgrade() throws {
        defer { cleanUp() }
        let old = try olderModel()
        let id = try writeStore(with: old, recipeName: "Gran's Stew")

        _ = PersistenceController(storeURL: storeURL, backupDirectory: backups)

        let folder = backups.appendingPathComponent(try #require(try backupFolders().first))
        let copy = folder.appendingPathComponent(storeURL.lastPathComponent)
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: copy, options: nil)
        #expect(old.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata))
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: old)
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: copy, options: nil)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let request = NSFetchRequest<NSManagedObject>(entityName: "Recipe")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        #expect(try context.fetch(request).count == 1)
    }

    @Test func openingACurrentStoreMakesNoBackup() throws {
        defer { cleanUp() }
        try writeStore(with: try currentModel())

        let controller = PersistenceController(storeURL: storeURL, backupDirectory: backups)

        #expect(controller.isStoreLoaded)
        #expect(!FileManager.default.fileExists(atPath: backups.path))
    }

    @Test func aFreshInstallMakesNoBackup() throws {
        defer { cleanUp() }
        try FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        let controller = PersistenceController(storeURL: storeURL, backupDirectory: backups)

        #expect(controller.isStoreLoaded)
        #expect(!FileManager.default.fileExists(atPath: backups.path))
    }

    // MARK: - Helpers

    private func momd() throws -> URL {
        try #require(Bundle(for: PersistenceController.self).url(forResource: "RecipeModel", withExtension: "momd"))
    }

    private func currentModel() throws -> NSManagedObjectModel {
        try #require(NSManagedObjectModel(contentsOf: try momd()))
    }

    /// The model before the current one — what TestFlight users have on their phones when the next version ships.
    private func olderModel() throws -> NSManagedObjectModel {
        try #require(NSManagedObjectModel(contentsOf: try momd().appendingPathComponent("RecipeModel 15.mom")))
    }

    @discardableResult
    private func writeStore(with model: NSManagedObjectModel, recipeName: String = "Dish") throws -> UUID {
        try FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let object = NSManagedObject(
            entity: try #require(NSEntityDescription.entity(forEntityName: "Recipe", in: context)),
            insertInto: context
        )
        let id = UUID()
        object.setValue(id, forKey: "id")
        object.setValue(recipeName, forKey: "name")
        try context.save()
        try coordinator.remove(try #require(coordinator.persistentStores.first))
        return id
    }
}
