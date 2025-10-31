//
//  IngredientNormalizer.swift
//  RecipeFinder
//
//  Normalizes recipe ingredients 

import Foundation

struct IngredientNormalizer {
    
    // MARK: - Normalization Mappings
    
    /// Maps common ingredient variations
    private static let normalizationMap: [String: String] = [
        // Beef variations
        "beef slices": "Beef Steak",
        "beef strips": "Beef Steak",
        "sliced beef": "Beef Steak",
        "beef steak slices": "Beef Steak",
        "beef sirloin slices": "Sirloin Steak",
        "beef tenderloin slices": "Beef Tenderloin",
        "ground beef meat": "Ground Beef",
        "minced beef": "Ground Beef",
        "beef mince": "Ground Beef",
        
        // Chicken variations
        "chicken breast slices": "Chicken Breast",
        "sliced chicken breast": "Chicken Breast",
        "chicken breast strips": "Chicken Breast",
        "boneless skinless chicken breast": "Boneless Chicken Breast",
        "boneless chicken breast halves": "Boneless Chicken Breast",
        "chicken thigh fillets": "Chicken Thigh",
        "skinless chicken thighs": "Boneless Chicken Thigh",
        "ground chicken meat": "Ground Chicken",
        "minced chicken": "Ground Chicken",
        
        // Pork variations
        "pork chop slices": "Pork Chop",
        "sliced pork chop": "Pork Chop",
        "pork tenderloin slices": "Pork Tenderloin",
        "pork loin slices": "Pork Loin",
        "ground pork meat": "Ground Pork",
        "minced pork": "Ground Pork",
        "pork mince": "Ground Pork",
        
        // Turkey variations
        "turkey breast slices": "Turkey Breast",
        "sliced turkey breast": "Turkey Breast",
        "ground turkey meat": "Ground Turkey",
        "minced turkey": "Ground Turkey",
        
        // Seafood variations
        "salmon fillet": "Salmon",
        "salmon filet": "Salmon",
        "tuna fillet": "Tuna",
        "cod fillet": "Cod",
        "tilapia fillet": "Tilapia",
        "halibut fillet": "Halibut",
        "mahi mahi fillet": "Mahi Mahi",
        "shrimp peeled": "Shrimp",
        "deveined shrimp": "Shrimp",
        "peeled and deveined shrimp": "Shrimp",
        "jumbo shrimp": "Shrimp",
        "large shrimp": "Shrimp",
        "medium shrimp": "Shrimp",
        
        // Vegetables variations
        "cherry tomatoes halved": "Cherry Tomatoes",
        "grape tomatoes halved": "Cherry Tomatoes",
        "roma tomatoes diced": "Tomato",
        "beefsteak tomato sliced": "Tomato",
        "yellow onion diced": "Onion",
        "white onion diced": "Onion",
        "red onion sliced": "Red Onion",
        "green bell pepper diced": "Bell Pepper",
        "red bell pepper diced": "Bell Pepper",
        "yellow bell pepper diced": "Bell Pepper",
        "minced garlic": "Garlic",
        "garlic cloves minced": "Garlic",
        "fresh ginger grated": "Ginger",
        "ginger root grated": "Ginger",
        
        // Cheese variations
        "shredded cheddar cheese": "Cheddar Cheese",
        "grated cheddar cheese": "Cheddar Cheese",
        "shredded mozzarella cheese": "Mozzarella Cheese",
        "grated mozzarella cheese": "Mozzarella Cheese",
        "shredded parmesan cheese": "Parmesan Cheese",
        "grated parmesan cheese": "Parmesan Cheese",
        "freshly grated parmesan": "Parmesan Cheese",
        "shredded mexican cheese blend": "Mexican Cheese Blend",
        "shredded monterey jack": "Monterey Jack",
        
        // Herbs variations
        "fresh basil leaves": "Fresh Basil",
        "fresh cilantro leaves": "Fresh Cilantro",
        "fresh parsley leaves": "Fresh Parsley",
        "fresh thyme leaves": "Fresh Thyme",
        "fresh rosemary leaves": "Fresh Rosemary",
        "fresh oregano leaves": "Fresh Oregano",
        "fresh mint leaves": "Fresh Mint",
        "fresh dill leaves": "Fresh Dill",
        
        // Dairy variations
        "heavy whipping cream": "Heavy Cream",
        "sour cream full fat": "Sour Cream",
        "plain greek yogurt": "Greek Yogurt",
        "unsweetened almond milk": "Almond Milk",
        "unsweetened coconut milk": "Coconut Milk",
        "full fat coconut milk": "Coconut Milk",
        
        // Legumes variations
        "black beans drained": "Black Beans",
        "kidney beans drained": "Kidney Beans",
        "chickpeas drained": "Chickpeas",
        "canned chickpeas": "Chickpeas",
        "garbanzo beans": "Chickpeas",
        "white beans drained": "White Beans",
        "cannellini beans": "White Beans",
        
        // Grains variations
        "long grain white rice": "White Rice",
        "jasmine rice uncooked": "Jasmine Rice",
        "basmati rice uncooked": "Basmati Rice",
        "brown rice uncooked": "Brown Rice",
        "quinoa uncooked": "Quinoa",
        "couscous uncooked": "Couscous",
        
        // Pasta variations
        "spaghetti noodles": "Spaghetti",
        "penne pasta": "Penne",
        "fettuccine noodles": "Fettuccine",
        "linguine noodles": "Linguine",
        "rigatoni pasta": "Rigatoni",
        
        // Oils variations
        "extra virgin olive oil": "Olive Oil",
        "evoo": "Olive Oil",
        "vegetable oil": "Vegetable Oil",
        "canola oil": "Canola Oil",
        "coconut oil": "Coconut Oil",
        "avocado oil": "Avocado Oil",
        
        // Condiments variations
        "low sodium soy sauce": "Soy Sauce",
        "light soy sauce": "Soy Sauce",
        "dark soy sauce": "Soy Sauce",
        "worcestershire sauce": "Worcestershire Sauce",
        "hot sauce": "Hot Sauce",
        "sriracha sauce": "Sriracha",
        "fish sauce": "Fish Sauce",
        
        // Spices variations
        "ground black pepper": "Black Pepper",
        "freshly ground black pepper": "Black Pepper",
        "kosher salt": "Salt",
        "sea salt": "Salt",
        "table salt": "Salt",
        "garlic powder": "Garlic Powder",
        "onion powder": "Onion Powder",
        "chili powder": "Chili Powder",
        "cayenne pepper": "Cayenne",
        "red pepper flakes": "Red Pepper Flakes",
        "crushed red pepper": "Red Pepper Flakes",
        
        // Canned goods variations
        "canned diced tomatoes": "Diced Tomatoes",
        "canned crushed tomatoes": "Crushed Tomatoes",
        "tomato sauce canned": "Tomato Sauce",
        "tomato paste canned": "Tomato Paste",
        "canned coconut milk": "Coconut Milk"
    ]
    
    // MARK: - Public Methods
    
    /// Normalizes an ingredient name to a set standard
    /// - Parameter ingredient: Raw ingredient name from recipe
    /// - Returns: Normalized ingredient name
    static func normalize(_ ingredient: String) -> String {
        let cleaned = ingredient
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        // Remove common measurement words
        let measurementWords = ["cup", "cups", "tablespoon", "tablespoons", "tbsp", "teaspoon", "teaspoons", "tsp",
                               "ounce", "ounces", "oz", "pound", "pounds", "lb", "lbs", "gram", "grams", "g",
                               "kilogram", "kilograms", "kg", "milliliter", "milliliters", "ml", "liter", "liters", "l",
                               "pinch", "dash", "handful", "clove", "cloves", "piece", "pieces", "slice", "slices",
                               "can", "cans", "package", "packages", "bag", "bags", "box", "boxes",
                               "about", "approximately", "roughly", "around", "to taste", "as needed", "optional"]
        
        var normalized = cleaned
        for word in measurementWords {
            normalized = normalized.replacingOccurrences(of: " \(word) ", with: " ")
            normalized = normalized.replacingOccurrences(of: " \(word)s ", with: " ")
        }
        
        // Remove numbers and special characters at the beginning
        normalized = normalized.replacingOccurrences(of: "^[0-9\\/\\-.,\\s]+", with: "", options: .regularExpression)
        
        // Remove parenthetical notes like "(about 2 lbs)" or "(optional)"
        normalized = normalized.replacingOccurrences(of: "\\([^)]*\\)", with: "", options: .regularExpression)
        
        // Clean up extra spaces
        normalized = normalized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check direct mapping first
        if let standardName = normalizationMap[normalized] {
            return standardName
        }
        
        // Check if any mapping key is contained in the ingredient
        for (key, value) in normalizationMap {
            if normalized.contains(key) {
                return value
            }
        }
        
        // If no mapping found, capitalize properly and return
        return normalized.capitalized
    }
    
    /// Normalizes a list of ingredients
    /// - Parameter ingredients: Array of raw ingredient names
    /// - Returns: Array of normalized ingredient names
    static func normalize(_ ingredients: [String]) -> [String] {
        return ingredients.map { normalize($0) }
    }
}
