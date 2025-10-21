import Foundation

enum CategoryClassifier {
    
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
        
        // Pantry
        let pantryKeywords = ["flour", "sugar", "salt", "pepper", "oil", "olive oil", "vegetable oil", "canola oil",
                             "rice", "pasta", "noodle", "spaghetti", "macaroni", "quinoa", "couscous", "beans",
                             "lentil", "chickpea", "peanut butter", "jam", "jelly", "honey", "maple syrup",
                             "vinegar", "soy sauce", "worcestershire", "hot sauce", "ketchup", "mustard", "mayo",
                             "mayonnaise", "salsa", "sauce", "broth", "stock", "bouillon", "cereal", "oats",
                             "granola", "cornmeal", "baking powder", "baking soda", "yeast", "vanilla", "extract",
                             "cocoa", "chocolate chip", "nut", "almond", "walnut", "pecan", "cashew", "pistachio",
                             "can", "canned", "jar", "dried", "powder"]
        if pantryKeywords.contains(where: { lowercased.contains($0) }) {
            return "Pantry"
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
}
