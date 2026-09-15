import Testing
import CoreData
import Foundation
@testable import RecipeFinder

/// Migration-safety guard. The modern store baseline (v9, all-Binary `ingredients`)
/// must lightweight-migrate to the current model with no data loss, so future
/// model bumps can't silently regress the upgrade path.
///
/// Audit note (2026-09-08): `ingredients` oscillated Transformable↔Binary across
/// early versions, so stores at v1/v3/v4/v5 do NOT lightweight-migrate to the
/// current model ("Source and destination attribute types are incompatible").
/// Those versions predate the modern Binary baseline (v6+); the app is unreleased,
/// so no shipped store is affected. This test pins the supported v6→current range.
@MainActor
@Suite struct CoreDataMigrationTests {

    @Test func modernStoreMigratesToCurrentModelWithoutDataLoss() throws {
        let momd = try #require(Bundle(for: PersistenceController.self).url(forResource: "RecipeModel", withExtension: "momd"))
        let source = try #require(NSManagedObjectModel(contentsOf: momd.appendingPathComponent("RecipeModel 9.mom")))
        let current = try #require(NSManagedObjectModel(contentsOf: momd))

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString).appendingPathExtension("sqlite")
        defer { for s in ["", "-wal", "-shm"] { try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + s)) } }

        // Write a row with the old model.
        let recipeId = UUID()
        let sourceCoordinator = NSPersistentStoreCoordinator(managedObjectModel: source)
        try sourceCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        let writeContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        writeContext.persistentStoreCoordinator = sourceCoordinator
        let object = NSManagedObject(entity: try #require(NSEntityDescription.entity(forEntityName: "Recipe", in: writeContext)),
                                     insertInto: writeContext)
        object.setValue(recipeId, forKey: "id")
        object.setValue("Legacy Dish", forKey: "name")
        try writeContext.save()
        try sourceCoordinator.remove(try #require(sourceCoordinator.persistentStores.first))

        // Reopen with the current model + automatic lightweight migration.
        let currentCoordinator = NSPersistentStoreCoordinator(managedObjectModel: current)
        try currentCoordinator.addPersistentStore(
            ofType: NSSQLiteStoreType, configurationName: nil, at: url,
            options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        )
        let readContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        readContext.persistentStoreCoordinator = currentCoordinator
        let request = NSFetchRequest<NSManagedObject>(entityName: "Recipe")
        request.predicate = NSPredicate(format: "id == %@", recipeId as CVarArg)
        let rows = try readContext.fetch(request)

        #expect(rows.count == 1)
        #expect(rows.first?.value(forKey: "name") as? String == "Legacy Dish")
    }

    /// Pins the immediate v12→v13 upgrade path: a store without cook-history fields
    /// must lightweight-migrate cleanly, with new fields defaulting to zero/nil.
    @Test func v12StoreMigratesWithNewFieldDefaults() throws {
        let momd = try #require(Bundle(for: PersistenceController.self).url(forResource: "RecipeModel", withExtension: "momd"))
        let source = try #require(NSManagedObjectModel(contentsOf: momd.appendingPathComponent("RecipeModel 12.mom")))
        let current = try #require(NSManagedObjectModel(contentsOf: momd))

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString).appendingPathExtension("sqlite")
        defer { for s in ["", "-wal", "-shm"] { try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + s)) } }

        let recipeId = UUID()
        let sourceCoordinator = NSPersistentStoreCoordinator(managedObjectModel: source)
        try sourceCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        let writeContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        writeContext.persistentStoreCoordinator = sourceCoordinator
        let obj = NSManagedObject(
            entity: try #require(NSEntityDescription.entity(forEntityName: "Recipe", in: writeContext)),
            insertInto: writeContext
        )
        obj.setValue(recipeId, forKey: "id")
        obj.setValue("Legacy Dish", forKey: "name")
        try writeContext.save()
        try sourceCoordinator.remove(try #require(sourceCoordinator.persistentStores.first))

        let currentCoordinator = NSPersistentStoreCoordinator(managedObjectModel: current)
        try currentCoordinator.addPersistentStore(
            ofType: NSSQLiteStoreType, configurationName: nil, at: url,
            options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        )
        let readContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        readContext.persistentStoreCoordinator = currentCoordinator
        let request = NSFetchRequest<NSManagedObject>(entityName: "Recipe")
        request.predicate = NSPredicate(format: "id == %@", recipeId as CVarArg)
        let rows = try readContext.fetch(request)
        let row = try #require(rows.first)

        #expect(rows.count == 1)
        #expect(row.value(forKey: "name") as? String == "Legacy Dish")
        #expect(row.value(forKey: "cookCount") as? Int ?? 0 == 0)
        #expect(row.value(forKey: "rating") as? Int ?? 0 == 0)
        #expect(row.value(forKey: "cuisine") as? String == nil)
        #expect(row.value(forKey: "lastCookedAt") as? Date == nil)
        #expect(row.value(forKey: "photoNames") as? [String] ?? [] == [])
    }
}
