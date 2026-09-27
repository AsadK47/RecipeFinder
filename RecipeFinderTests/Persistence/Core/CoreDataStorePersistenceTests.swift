import Testing
import Foundation
import CoreData
@testable import RecipeFinder

/// On-disk Core Data guard: a recipe written by one container reloads from a fresh container at the same file — the real-SQLite "relaunch after upgrade" path (with lightweight migration) that `/dev/null` tests can't reach.
@MainActor
@Suite struct CoreDataStorePersistenceTests {

    private func makeContainer(at url: URL) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "RecipeModel")
        let description = NSPersistentStoreDescription(url: url)
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }
        return container
    }

    @Test func recipeSurvivesStoreReopen() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
        defer {
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + suffix))
            }
        }

        let recipeId = UUID()
        let ingredientData = try JSONEncoder().encode([Ingredient(baseQuantity: 2, unit: "cup", name: "flour")])

        // First launch: write and save, then release the store.
        let first = try makeContainer(at: storeURL)
        let context = first.viewContext
        let entity = try #require(NSEntityDescription.entity(forEntityName: "Recipe", in: context))
        let object = NSManagedObject(entity: entity, insertInto: context)
        object.setValue(recipeId, forKey: "id")
        object.setValue("Pancakes", forKey: "name")
        object.setValue(ingredientData, forKey: "ingredients")
        object.setValue("userA", forKey: "userId")
        try context.save()
        if let store = first.persistentStoreCoordinator.persistentStores.first {
            try first.persistentStoreCoordinator.remove(store)
        }

        // Second launch: a fresh container at the same file must see the recipe.
        let second = try makeContainer(at: storeURL)
        let request = NSFetchRequest<NSManagedObject>(entityName: "Recipe")
        request.predicate = NSPredicate(format: "id == %@", recipeId as CVarArg)
        let results = try second.viewContext.fetch(request)

        #expect(results.count == 1)
        #expect(results.first?.value(forKey: "name") as? String == "Pancakes")
        let reloaded = try #require(results.first?.value(forKey: "ingredients") as? Data)
        let decoded = try JSONDecoder().decode([Ingredient].self, from: reloaded)
        #expect(decoded.first?.name == "Flour")  // Ingredient capitalises on construction.
    }
}
