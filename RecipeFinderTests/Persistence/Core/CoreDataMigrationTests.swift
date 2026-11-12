import Testing
import CoreData
import Foundation
@testable import RecipeFinder

/// Migration-safety guard: the modern baseline (v9, all-Binary `ingredients`) must lightweight-migrate to the current model with no data loss.
/// v1/v3/v4/v5 don't migrate (`ingredients` oscillated Transformable↔Binary before the v6+ baseline); app is unreleased so none shipped — this pins the supported v6→current range.
@MainActor
@Suite struct CoreDataMigrationTests {
    private typealias RecipeKey = PersistenceController.RecipeKey

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

    /// Every RecipeKey constant must map to a real attribute on the current Recipe entity — fails fast if .xccurrentversion points at the wrong model version, before a runtime KVC crash.
    @Test func currentModelContainsAllRecipeKeys() throws {
        let momd = try #require(Bundle(for: PersistenceController.self).url(forResource: "RecipeModel", withExtension: "momd"))
        let model = try #require(NSManagedObjectModel(contentsOf: momd))
        let entity = try #require(model.entitiesByName["Recipe"])
        let attributeNames = Set(entity.attributesByName.keys)

        let expectedKeys = [
            RecipeKey.id, RecipeKey.name, RecipeKey.category, RecipeKey.difficulty,
            RecipeKey.prepTime, RecipeKey.cookingTime, RecipeKey.baseServings,
            RecipeKey.currentServings, RecipeKey.ingredients, RecipeKey.prePrepInstructions,
            RecipeKey.instructions, RecipeKey.notes, RecipeKey.imageName,
            RecipeKey.isFavorite, RecipeKey.isSampleRecipe, RecipeKey.dietaryInfo,
            RecipeKey.tags, RecipeKey.cookCount,
            RecipeKey.lastCookedAt, RecipeKey.rating, RecipeKey.cuisine,
            RecipeKey.photoNames, RecipeKey.sourceText,
        ]

        for key in expectedKeys {
            #expect(attributeNames.contains(key), "Recipe entity is missing attribute '\(key)'")
        }
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

    /// Pins the v13→v14 upgrade path (v14 drops the accounts-era `userId` column): a store whose rows carry a
    /// `userId` must lightweight-migrate cleanly and keep every recipe.
    @Test func v13StoreWithUserIdMigratesKeepingRecipes() throws {
        let momd = try #require(Bundle(for: PersistenceController.self).url(forResource: "RecipeModel", withExtension: "momd"))
        let source = try #require(NSManagedObjectModel(contentsOf: momd.appendingPathComponent("RecipeModel 13.mom")))
        let current = try #require(NSManagedObjectModel(contentsOf: momd))
        #expect(current.entitiesByName["Recipe"]?.attributesByName["userId"] == nil)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString).appendingPathExtension("sqlite")
        defer { for s in ["", "-wal", "-shm"] { try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + s)) } }

        let ids = [UUID(), UUID()]
        let sourceCoordinator = NSPersistentStoreCoordinator(managedObjectModel: source)
        try sourceCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        let writeContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        writeContext.persistentStoreCoordinator = sourceCoordinator
        let entity = try #require(NSEntityDescription.entity(forEntityName: "Recipe", in: writeContext))
        for (index, (id, owner)) in zip(ids, ["userA", nil] as [String?]).enumerated() {
            let obj = NSManagedObject(entity: entity, insertInto: writeContext)
            obj.setValue(id, forKey: "id")
            obj.setValue("Dish \(index)", forKey: "name")
            obj.setValue(owner, forKey: "userId")
        }
        try writeContext.save()
        try sourceCoordinator.remove(try #require(sourceCoordinator.persistentStores.first))

        let currentCoordinator = NSPersistentStoreCoordinator(managedObjectModel: current)
        try currentCoordinator.addPersistentStore(
            ofType: NSSQLiteStoreType, configurationName: nil, at: url,
            options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        )
        let readContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        readContext.persistentStoreCoordinator = currentCoordinator
        let rows = try readContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Recipe"))

        #expect(Set(rows.compactMap { $0.value(forKey: "id") as? UUID }) == Set(ids))
        #expect(Set(rows.compactMap { $0.value(forKey: "name") as? String }) == ["Dish 0", "Dish 1"])
    }

    /// Pins the v14→v15 upgrade path (v15 adds the optional `sourceText`): existing recipes survive and read nil.
    @Test func v14StoreMigratesWithNilSourceText() throws {
        let momd = try #require(Bundle(for: PersistenceController.self).url(forResource: "RecipeModel", withExtension: "momd"))
        let source = try #require(NSManagedObjectModel(contentsOf: momd.appendingPathComponent("RecipeModel 14.mom")))
        let current = try #require(NSManagedObjectModel(contentsOf: momd))
        #expect(current.entitiesByName["Recipe"]?.attributesByName["sourceText"] != nil)

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
        obj.setValue(3, forKey: "cookCount")
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
        let row = try #require(try readContext.fetch(request).first)

        #expect(row.value(forKey: "name") as? String == "Legacy Dish")
        #expect(row.value(forKey: "cookCount") as? Int == 3)
        #expect(row.value(forKey: "sourceText") as? String == nil)
    }

    /// Pins the v15→v16 upgrade (v16 adds the entities that replace the UserDefaults blobs): recipes survive and the
    /// new entities can be written straight away.
    @Test func v15StoreMigratesAndGainsTheNewEntities() throws {
        let momd = try #require(Bundle(for: PersistenceController.self).url(forResource: "RecipeModel", withExtension: "momd"))
        let source = try #require(NSManagedObjectModel(contentsOf: momd.appendingPathComponent("RecipeModel 15.mom")))
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
        obj.setValue("Pasted text", forKey: "sourceText")
        try writeContext.save()
        try sourceCoordinator.remove(try #require(sourceCoordinator.persistentStores.first))

        let currentCoordinator = NSPersistentStoreCoordinator(managedObjectModel: current)
        try currentCoordinator.addPersistentStore(
            ofType: NSSQLiteStoreType, configurationName: nil, at: url,
            options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        )
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = currentCoordinator
        let row = try #require(try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "Recipe")).first)
        #expect(row.value(forKey: "id") as? UUID == recipeId)
        #expect(row.value(forKey: "sourceText") as? String == "Pasted text")

        let planId = UUID()
        let plan = NSManagedObject(
            entity: try #require(NSEntityDescription.entity(forEntityName: "MealPlanEntity", in: context)),
            insertInto: context
        )
        plan.setValue(planId, forKey: "id")
        plan.setValue(recipeId, forKey: "recipeId")
        try context.save()
        let plans = try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "MealPlanEntity"))
        #expect(plans.compactMap { $0.value(forKey: "id") as? UUID } == [planId])
        #expect(plans.first?.value(forKey: "servings") as? Int == 4)
        #expect(source.entitiesByName["Recipe"]?.versionHash == current.entitiesByName["Recipe"]?.versionHash)
    }

    /// Every field of every UserDefaults blob has a typed home (Data safety 1/4); a dropped or mistyped attribute
    /// fails here, not as silently lost data in the migration slice. Array fields are JSON-encoded `Binary`.
    @Test(arguments: [
        ("MealPlanEntity", ["id": .UUIDAttributeType, "recipeId": .UUIDAttributeType, "recipeName": .stringAttributeType,
                            "date": .dateAttributeType, "mealTime": .stringAttributeType, "servings": .integer64AttributeType,
                            "notes": .stringAttributeType, "isCompleted": .booleanAttributeType,
                            "isRecurring": .booleanAttributeType, "createdDate": .dateAttributeType,
                            "reminderTime": .dateAttributeType, "sortOrder": .integer32AttributeType]),
        ("ShoppingItemEntity", ["id": .UUIDAttributeType, "name": .stringAttributeType, "quantity": .integer64AttributeType,
                                "unit": .stringAttributeType, "isChecked": .booleanAttributeType,
                                "isCompleted": .booleanAttributeType, "category": .stringAttributeType,
                                "dateAdded": .dateAttributeType, "stores": .binaryDataAttributeType,
                                "isRecurring": .booleanAttributeType, "sortOrder": .integer32AttributeType]),
        ("ShoppingStoreEntity", ["id": .UUIDAttributeType, "name": .stringAttributeType, "sortOrder": .integer32AttributeType]),
        ("KitchenItemEntity", ["id": .UUIDAttributeType, "name": .stringAttributeType, "category": .stringAttributeType,
                               "quantity": .doubleAttributeType, "unit": .stringAttributeType,
                               "dateAdded": .dateAttributeType, "sortOrder": .integer32AttributeType]),
        ("InventoryItemEntity", ["id": .UUIDAttributeType, "name": .stringAttributeType, "category": .stringAttributeType,
                                 "quantity": .doubleAttributeType, "unit": .stringAttributeType,
                                 "storageLocation": .stringAttributeType, "purchaseDate": .dateAttributeType,
                                 "expiryDate": .dateAttributeType, "notes": .stringAttributeType,
                                 "isLowStock": .booleanAttributeType, "minimumQuantity": .doubleAttributeType,
                                 "sortOrder": .integer32AttributeType]),
        ("CollectionEntity", ["id": .UUIDAttributeType, "name": .stringAttributeType, "colorName": .stringAttributeType,
                              "recipeIDs": .binaryDataAttributeType, "createdAt": .dateAttributeType,
                              "sortOrder": .integer32AttributeType]),
        ("EarnedBadgeEntity", ["id": .UUIDAttributeType, "badgeId": .stringAttributeType, "dateEarned": .dateAttributeType,
                               "isUnlocked": .booleanAttributeType, "celebrationShown": .booleanAttributeType]),
        ("CookDateEntity", ["id": .UUIDAttributeType, "date": .dateAttributeType]),
        ("ProfileEntity", ["id": .UUIDAttributeType, "uuid": .stringAttributeType, "firstName": .stringAttributeType,
                           "lastName": .stringAttributeType, "chefType": .stringAttributeType,
                           "imageData": .binaryDataAttributeType, "createdDate": .dateAttributeType]),
    ] as [(String, [String: NSAttributeType])])
    func currentModelHasATypedHomeForEachBlobField(entityName: String, attributes: [String: NSAttributeType]) throws {
        let momd = try #require(Bundle(for: PersistenceController.self).url(forResource: "RecipeModel", withExtension: "momd"))
        let current = try #require(NSManagedObjectModel(contentsOf: momd))
        let entity = try #require(current.entitiesByName[entityName])
        #expect(entity.attributesByName.mapValues(\.attributeType) == attributes)
    }

    /// CloudKit (Data safety 2/4) refuses a model with required attributes lacking defaults, unique constraints, or
    /// required / one-way relationships — catch that here, not when sync first switches on.
    @Test func currentModelIsCloudKitReady() throws {
        let momd = try #require(Bundle(for: PersistenceController.self).url(forResource: "RecipeModel", withExtension: "momd"))
        let current = try #require(NSManagedObjectModel(contentsOf: momd))
        for entity in current.entities {
            let name = entity.name ?? "?"
            #expect(entity.uniquenessConstraints.isEmpty, "\(name) has unique constraints")
            for attribute in entity.attributesByName.values {
                #expect(attribute.isOptional || attribute.defaultValue != nil, "\(name).\(attribute.name) is required")
            }
            // No relationships yet (v16 stores links as ids); this guards the first one added.
            for relationship in entity.relationshipsByName.values {
                #expect(relationship.isOptional, "\(name).\(relationship.name) is required")
                #expect(relationship.inverseRelationship != nil, "\(name).\(relationship.name) has no inverse")
                #expect(relationship.deleteRule != .denyDeleteRule, "\(name).\(relationship.name) denies delete")
            }
        }
    }
}
