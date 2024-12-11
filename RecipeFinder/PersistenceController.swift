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
    let ingredients: [String]
    let instructions: String
}

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "RecipeModel")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    func saveRecipe(name: String, prepTime: String, ingredients: [String], instructions: String) {
        let context = container.viewContext
        let entity = NSEntityDescription.insertNewObject(forEntityName: "Recipe", into: context)
        
        entity.setValue(name, forKey: "name")
        entity.setValue(prepTime, forKey: "prepTime")
        entity.setValue(ingredients, forKey: "ingredients")
        entity.setValue(instructions, forKey: "instructions")
        
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
                    ingredients: result.value(forKey: "ingredients") as? [String] ?? [],
                    instructions: result.value(forKey: "instructions") as? String ?? ""
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
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Recipe")
        
        do {
            let count = try context.count(for: fetchRequest)
            if count == 0 {
                saveRecipe(
                    name: "Spaghetti",
                    prepTime: "30 min",
                    ingredients: ["Pasta", "Tomato Sauce"],
                    instructions: "Boil pasta, add sauce."
                )
                saveRecipe(
                    name: "Pancakes",
                    prepTime: "20 min",
                    ingredients: ["Flour", "Milk", "Eggs"],
                    instructions: "Mix ingredients and fry."
                )
                saveRecipe(
                    name: "Salad",
                    prepTime: "15 min",
                    ingredients: ["Lettuce", "Tomatoes", "Cucumber"],
                    instructions: "Chop ingredients and mix."
                )
                print("Default recipes added!")
            }
        } catch {
            print("Failed to check database state: \(error)")
        }
    }
}
