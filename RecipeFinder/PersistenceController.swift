//
//  PersistenceController.swift
//  RecipeFinder
//
//  Created by asad.e.khan on 11/12/2024.
//

import CoreData

struct RecipeModel: Identifiable {
    let id = UUID()
    let name: String
    let prepTime: String
    let cookingTime: String
    let ingredients: [String]
    let prePrepInstructions: [String]
    let instructions: [String]
    let notes: String
}

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "RecipeModel")
        
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        if let storeURL = container.persistentStoreDescriptions.first?.url {
            try? FileManager.default.removeItem(at: storeURL)
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Failed to load persistent store: \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    func clearDatabase() {
        if let storeURL = container.persistentStoreDescriptions.first?.url {
            do {
                try FileManager.default.removeItem(at: storeURL)
                print("Database cleared successfully.")
            } catch {
                print("Failed to clear database: \(error)")
            }
        }
    }
    
    func saveRecipe(name: String, prepTime: String, cookingTime: String, ingredients: [String], prePrepInstructions: [String], instructions: [String], notes: String) {
        let context = container.viewContext
        let entity = NSEntityDescription.insertNewObject(forEntityName: "Recipe", into: context)
        
        entity.setValue(name, forKey: "name")
        entity.setValue(prepTime, forKey: "prepTime")
        entity.setValue(cookingTime, forKey: "cookingTime")
        entity.setValue(ingredients, forKey: "ingredients")
        entity.setValue(prePrepInstructions, forKey: "prePrepInstructions")
        entity.setValue(instructions, forKey: "instructions")
        entity.setValue(notes, forKey: "notes")
        
        do {
            try context.save()
            print("Recipe saved successfully!")
        } catch {
            print("Failed to save recipe: \(error)")
        }
    }
    
    func fetchRecipes() -> [RecipeModel] {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Recipe")
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.map { result in
                RecipeModel(
                    name: result.value(forKey: "name") as? String ?? "",
                    prepTime: result.value(forKey: "prepTime") as? String ?? "",
                    cookingTime: result.value(forKey: "cookingTime") as? String ?? "",
                    ingredients: result.value(forKey: "ingredients") as? [String] ?? [],
                    prePrepInstructions: result.value(forKey: "prePrepInstructions") as? [String] ?? [],
                    instructions: result.value(forKey: "instructions") as? [String] ?? [],
                    notes: result.value(forKey: "notes") as? String ?? ""
                )
            }
        } catch {
            print("Failed to fetch recipes: \(error)")
            return []
        }
    }
}

extension PersistenceController {
    func populateDatabaseIfNeeded() {
        let context = container.viewContext
        
        let fetchRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Recipe")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("Failed to clear existing data: \(error)")
        }
        
        saveRecipe(
            name: "Spaghetti",
            prepTime: "30 min",
            cookingTime: "20 min",
            ingredients: ["Pasta", "Tomato Sauce"],
            prePrepInstructions: ["Chop onions and garlic"],
            instructions: [
                "Boil pasta, add sauce",
            ],
            notes: "Classic Italian dish."
        )
        saveRecipe(
            name: "Pancakes",
            prepTime: "20 min",
            cookingTime: "20 min",
            ingredients: ["Flour", "Milk", "Eggs"],
            prePrepInstructions: [
                "Chop onions and garlic"
            ],
            instructions: [
                "Mix ingredients and fry.",
            ],
            notes: "Classic Italian dish."
        )
        saveRecipe(
            name: "Salad",
            prepTime: "15 min",
            cookingTime: "20 min",
            ingredients: ["Lettuce", "Tomatoes", "Cucumber"],
            prePrepInstructions: [
                "Chop onions and garlic"
            ],
            instructions: [
                "Chop ingredients and mix",
            ],
            notes: "Classic Italian dish."
        )
        saveRecipe(
            name: "Instant Pot Achari Chicken Curry",
            prepTime: "20 minutes",
            cookingTime: "20 min",
            ingredients: [
                "3 tablespoons oil of choice",
                "1 teaspoon cumin seeds",
                "1 bay leaf",
                "1 onion, diced",
                "1 teaspoon minced garlic",
                "1 teaspoon minced ginger",
                "1 teaspoon coriander powder",
                "1 teaspoon fennel seeds",
                "1 teaspoon paprika",
                "1 teaspoon salt",
                "1 teaspoon turmeric",
                "½ teaspoon amchur (dried mango powder)",
                "½ teaspoon fenugreek (methi) seeds",
                "½ teaspoon garam masala",
                "½ teaspoon kalonji (nigella seeds)",
                "¼ teaspoon black pepper",
                "¼ teaspoon cayenne",
                "2 pounds skinless and boneless chicken thighs, cut into bite-sized pieces",
                "1 cup fresh tomato puree"
            ],
            prePrepInstructions: [
                "Chop onions and garlic"
            ],
            instructions: [
                "Press the sauté button on the Instant Pot, add the oil, and allow it to heat up for a minute.",
                "Once the oil is hot, add the cumin seeds and bay leaf.",
                "When the cumin seeds brown, add the diced onion and stir-fry for 6-7 minutes, or until the onions begin to brown.",
                "Add the minced garlic and ginger, stir, then add all the spices. Mix well.",
                "Add the chicken pieces and stir-fry for 5-6 minutes, or until the chicken is mostly cooked.",
                "Add the fresh tomato puree and mix well.",
                "Secure the lid, close the pressure valve, and cook for 5 minutes at high pressure.",
                "Naturally release pressure.",
                "Garnish with cilantro and serve."
            ],
            notes: "Classic Italian dish."
        )
        print("Default recipes added!")
    }
}
