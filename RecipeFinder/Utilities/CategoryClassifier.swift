import Foundation
import SwiftUI

enum CategoryClassifier {
    
    // Shopping List Categories
    static let categoryOrder = ["Produce", "Meat & Seafood", "Dairy & Eggs", "Bakery", "Kitchen", "Frozen", "Beverages", "Spices & Seasonings", "Other"]
    
    // Kitchen Inventory Categories
    static let kitchenCategories = ["Proteins", "Vegetables", "Grains & Noodles", "Dairy & Eggs", "Spices & Herbs", "Sauces & Condiments"]
    
    // Kitchen Ingredient Keywords (for matching ingredients to kitchen categories)
    static let kitchenIngredientKeywords: [String: [String]] = [
        "Proteins": ["chicken", "beef", "lamb", "mutton", "pork", "fish", "cod", "eggs", "tofu"],
        "Vegetables": ["onion", "tomato", "carrot", "cabbage", "potato", "bell pepper", "capsicum", "cucumber", "eggplant", "bok choy"],
        "Spices & Herbs": ["cumin", "coriander", "turmeric", "paprika", "ginger", "garlic", "chili", "cinnamon", "cardamom", "garam masala", "cilantro", "parsley", "mint", "basil"],
        "Dairy & Eggs": ["milk", "butter", "yogurt", "cream", "cheese", "egg"],
        "Grains & Noodles": ["rice", "flour", "noodles", "pasta", "bread", "oats"],
        "Sauces & Condiments": ["soy sauce", "oyster sauce", "vinegar", "ketchup", "mustard", "mayo"]
    ]
    
    // Category Helpers
    static func categoryIcon(for category: String) -> String {
        switch category {
        case "Produce": return "leaf.fill"
        case "Meat & Seafood": return "fish.fill"
        case "Dairy & Eggs": return "drop.fill"
        case "Bakery": return "birthday.cake.fill"
        case "Kitchen": return "cabinet.fill"
        case "Frozen": return "snowflake"
        case "Beverages": return "cup.and.saucer.fill"
        case "Spices & Seasonings": return "sparkles"
        // Kitchen categories
        case "Proteins": return "fork.knife"
        case "Vegetables": return "carrot.fill"
        case "Spices & Herbs": return "leaf.fill"
        case "Grains & Noodles": return "takeoutbag.and.cup.and.straw.fill"
        case "Sauces & Condiments": return "drop.fill"
        default: return "basket.fill"
        }
    }
    
    static func categoryColor(for category: String) -> Color {
        switch category {
        case "Produce": return .green
        case "Meat & Seafood": return .red
        case "Dairy & Eggs": return .blue
        case "Bakery": return .orange
        case "Kitchen": return .brown
        case "Frozen": return .cyan
        case "Beverages": return .purple
        case "Spices & Seasonings": return .yellow
        // Kitchen categories  
        case "Proteins": return .red
        case "Vegetables": return .green
        case "Spices & Herbs": return .orange
        case "Grains & Noodles": return .yellow
        case "Sauces & Condiments": return .purple
        default: return .gray
        }
    }
    
    // Categorization
    static func categorize(_ itemName: String) -> String {
        let lowercased = itemName.lowercased()
        
        // Produce
        let produceKeywords = ["apple", "banana", "orange", "lettuce", "tomato", "potato", "onion", "garlic", 
                               "carrot", "celery", "cucumber", "pepper", "spinach", "broccoli", "cauliflower",
                               "cabbage", "mushroom", "avocado", "lemon", "lime", "berry", "strawberry", "grape",
                               "melon", "watermelon", "pineapple", "mango", "peach", "pear", "cherry", "plum",
                               "kiwi", "papaya", "cantaloupe", "zucchini", "squash", "eggplant", "radish",
                               "turnip", "beet", "kale", "arugula", "basil", "cilantro", "parsley", "mint",
                               "thyme", "rosemary", "sage", "oregano", "dill", "chive", "ginger root", "vegetable"]
        if produceKeywords.contains(where: { lowercased.contains($0) }) {
            return "Produce"
        }
        
        // Meat & Seafood
        let meatKeywords = ["chicken", "beef", "pork", "lamb", "turkey", "duck", "bacon", "sausage", "ham",
                            "steak", "ground beef", "ground turkey", "ground chicken", "ribs", "brisket",
                            "fish", "salmon", "tuna", "cod", "tilapia", "shrimp", "prawn", "lobster", "crab",
                            "scallop", "mussel", "clam", "oyster", "seafood", "meat", "wing", "thigh", "breast"]
        if meatKeywords.contains(where: { lowercased.contains($0) }) {
            return "Meat & Seafood"
        }
        
        // Dairy & Eggs
        let dairyKeywords = ["milk", "cream", "butter", "cheese", "cheddar", "mozzarella", "parmesan", "feta",
                            "yogurt", "yoghurt", "sour cream", "cottage cheese", "cream cheese", "whipped cream",
                            "egg", "eggs", "half and half", "buttermilk", "ice cream", "gelato"]
        if dairyKeywords.contains(where: { lowercased.contains($0) }) {
            return "Dairy & Eggs"
        }
        
        // Bakery
        let bakeryKeywords = ["bread", "baguette", "roll", "bun", "croissant", "bagel", "muffin", "donut",
                             "pastry", "cake", "cookie", "pie", "tart", "biscuit", "scone", "cracker",
                             "tortilla", "pita", "naan", "flatbread", "sourdough", "ciabatta", "pretzel"]
        if bakeryKeywords.contains(where: { lowercased.contains($0) }) {
            return "Bakery"
        }
        
    // Kitchen
        let pantryKeywords = ["flour", "sugar", "salt", "pepper", "oil", "olive oil", "vegetable oil", "canola oil",
                             "rice", "pasta", "noodle", "spaghetti", "macaroni", "quinoa", "couscous", "beans",
                             "lentil", "chickpea", "peanut butter", "jam", "jelly", "honey", "maple syrup",
                             "vinegar", "soy sauce", "worcestershire", "hot sauce", "ketchup", "mustard", "mayo",
                             "mayonnaise", "salsa", "sauce", "broth", "stock", "bouillon", "cereal", "oats",
                             "granola", "cornmeal", "baking powder", "baking soda", "yeast", "vanilla", "extract",
                             "cocoa", "chocolate chip", "nut", "almond", "walnut", "pecan", "cashew", "pistachio",
                             "can", "canned", "jar", "dried", "powder"]
        if pantryKeywords.contains(where: { lowercased.contains($0) }) {
            return "Kitchen"
        }
        
        // Frozen
        let frozenKeywords = ["frozen", "ice", "popsicle", "ice cream", "frozen pizza", "frozen meal",
                             "frozen vegetable", "frozen fruit", "frozen berry", "frozen pea", "frozen corn"]
        if frozenKeywords.contains(where: { lowercased.contains($0) }) {
            return "Frozen"
        }
        
        // Beverages
        let beverageKeywords = ["water", "juice", "soda", "pop", "cola", "sprite", "coffee", "tea", "beer",
                               "wine", "vodka", "whiskey", "rum", "tequila", "gin", "champagne", "cider",
                               "lemonade", "smoothie", "shake", "milk", "almond milk", "soy milk", "oat milk",
                               "coconut milk", "energy drink", "sports drink", "tonic", "sparkling"]
        if beverageKeywords.contains(where: { lowercased.contains($0) }) {
            return "Beverages"
        }
        
        // Spices & Seasonings
        let spiceKeywords = ["cumin", "paprika", "turmeric", "coriander", "cardamom", "cinnamon", "nutmeg",
                            "clove", "ginger", "garlic powder", "onion powder", "chili powder", "cayenne",
                            "curry", "masala", "seasoning", "spice", "herb", "bay leaf", "peppercorn",
                            "fennel", "fenugreek", "mustard seed", "sesame seed", "poppy seed", "anise",
                            "allspice", "italian seasoning", "cajun", "adobo", "za'atar", "everything bagel"]
        if spiceKeywords.contains(where: { lowercased.contains($0) }) {
            return "Spices & Seasonings"
        }
        
        // Default to Other
        return "Other"
    }
    
    // Get suggested categories based on partial input (for autocomplete)
    static func suggestCategory(for partialInput: String) -> String {
        if partialInput.count < 3 {
            return "Other"
        }
        return categorize(partialInput)
    }
    
    // Group similar ingredients (e.g., "chicken breast", "chicken thighs" -> "Chicken")
    static func groupSimilarIngredients(_ ingredients: [String]) -> [String] {
        var mainIngredients = Set<String>()
        
        for ingredient in ingredients {
            // Clean up the ingredient name - remove quantities, parenthetical notes, and split by comma
            let cleaned = ingredient
                .components(separatedBy: ",").first ?? ingredient // Take first part before comma
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Extract the main ingredient name (first 1-2 words typically)
            let words = cleaned.split(separator: " ").map { String($0) }
            
            if words.count >= 2 {
                // For compound ingredients like "black pepper", "soy sauce", keep both words
                let firstTwo = words.prefix(2).joined(separator: " ")
                
                // Check if it's a common compound ingredient
                let compounds = ["black pepper", "soy sauce", "oyster sauce", "fish sauce", 
                               "olive oil", "sesame oil", "coconut milk", "bell pepper",
                               "green onion", "spring onion", "red onion", "white onion",
                               "black beans", "red beans", "green beans", "rice wine",
                               "brown sugar", "white sugar", "chicken breast", "chicken thigh",
                               "beef chuck", "pork belly", "rice vinegar", "white vinegar",
                               "black vinegar", "sesame seeds", "chili flakes", "curry powder"]
                
                if compounds.contains(firstTwo.lowercased()) {
                    mainIngredients.insert(firstTwo.capitalized)
                } else if let first = words.first {
                    mainIngredients.insert(first.capitalized)
                }
            } else if let first = words.first {
                mainIngredients.insert(first.capitalized)
            }
        }
        
        return Array(mainIngredients).sorted()
    }
}
