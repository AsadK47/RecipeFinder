import Foundation
import SwiftUI

/// Comprehensive World Food Classification System
/// Based on research from food, culinary standards, and international cuisine analysis
/// Sources: Bon Appétit, Serious Eats, Food Network, USDA Food Categories
enum CategoryClassifier {
    
    // Shopping List Categories
    
    /// Complete shopping list categorization covering all known food types
    static let categoryOrder = [
        "Produce", "Meat", "Poultry", "Seafood", "Dairy & Eggs",
        "Bakery", "Grains & Pasta", "Legumes & Pulses", "Nuts & Seeds",
        "Herbs & Fresh Spices", "Dried Spices & Seasonings",
        "Oils & Fats", "Sauces & Condiments", "Canned & Jarred",
        "Frozen", "Beverages", "Sweeteners", "Baking Supplies", "Snacks", "Other"
    ]
    
    // MARK: - Kitchen Inventory Categories
    
    /// Optimized categories for recipe ingredient tracking
    static let kitchenCategories = [
        "Meat", "Poultry", "Seafood", "Vegetables", "Fruits",
        "Grains & Pasta", "Legumes & Pulses", "Nuts & Seeds",
        "Dairy & Eggs", "Herbs & Fresh Spices", "Dried Spices & Seasonings",
        "Oils & Fats", "Sauces & Condiments", "Sweeteners"
    ]
    
    
    // MARK: - Descriptor Words
    
    /// Words to exclude from ingredient matching (qualifiers, not ingredients)
    static let descriptorWords = [
        "large", "small", "medium", "fresh", "dried", "frozen", "canned",
        "chopped", "sliced", "diced", "minced", "whole", "ground", "raw", "cooked",
        "boneless", "skinless", "organic", "wild", "caught", "grass-fed", "free-range",
        "peeled", "shredded", "grated", "crushed", "toasted", "roasted", "smoked"
    ]
    
    
    // MARK: - Comprehensive Ingredient Keywords
    
    /// World-class ingredient categorization covering international cuisines
    static let kitchenIngredientKeywords: [String: [String]] = [
        
        // MARK: Proteins - Meat
        "Meat": [
            // Beef
            "beef", "steak", "sirloin", "ribeye", "t-bone", "filet mignon",
            "tenderloin", "ground beef", "chuck", "brisket", "short rib", "oxtail",
            "flank", "skirt steak",
            // Pork
            "pork", "bacon", "ham", "pork chop", "pork belly", "pancetta", "prosciutto",
            "sausage", "chorizo", "salami", "pepperoni", "guanciale",
            "pork loin", "pork shoulder", "ground pork", "italian sausage",
            // Lamb & Goat
            "lamb", "mutton", "lamb chop", "lamb shank", "rack of lamb",
            "goat", "lamb leg", "ground lamb",
            // Game & Specialty
            "veal", "venison", "bison", "rabbit", "wild boar"
        ],
        
        // MARK: Proteins - Poultry
        "Poultry": [
            "chicken", "chicken breast", "chicken thigh", "chicken wing", "drumstick",
            "whole chicken", "ground chicken", "chicken tender",
            "turkey", "turkey breast", "ground turkey",
            "duck", "duck breast", "duck leg", "duck confit", "goose", "quail"
        ],
        
        // MARK: Proteins - Seafood
        "Seafood": [
            "fish", "salmon", "tuna", "cod", "halibut", "tilapia", "mahi mahi",
            "sea bass", "seabass", "branzino", "striped bass",
            "haddock", "pollock", "sole", "flounder", "trout", "mackerel",
            "sardine", "anchovy", "snapper", "catfish", "monkfish",
            "shrimp", "prawn", "lobster", "crab", "crayfish", "crawfish",
            "scallop", "mussel", "clam", "oyster", "squid", "octopus", "calamari",
            "caviar", "roe", "fish eggs", "seafood", "fish sauce"
        ],
        
        // MARK: Vegetables
        "Vegetables": [
            // Alliums
            "onion", "red onion", "white onion", "yellow onion", "sweet onion",
            "shallot", "scallion", "green onion", "spring onion", "leek", "ramp",
            "garlic", "chive",
            // Nightshades
            "tomato", "cherry tomato", "grape tomato", "roma tomato",
            "bell pepper", "red pepper", "green pepper", "yellow pepper",
            "capsicum", "chili", "chile", "jalapeño", "serrano", "habanero",
            "poblano", "thai chili",
            // Root Vegetables
            "potato", "russet potato", "sweet potato", "yam", "carrot", "parsnip",
            "turnip", "beetroot", "beet", "radish", "daikon", "horseradish",
            "ginger root", "turmeric root", "galangal", "cassava", "yucca", "taro",
            "jicama", "celeriac", "lotus root",
            // Brassicas
            "broccoli", "cauliflower", "cabbage", "red cabbage", "napa cabbage",
            "brussels sprout", "kale", "collard green", "bok choy", "pak choi",
            "gai lan", "chinese broccoli", "kohlrabi",
            // Leafy Greens
            "spinach", "lettuce", "romaine", "arugula", "rocket", "swiss chard",
            "watercress", "endive", "radicchio",
            // Squashes
            "zucchini", "courgette", "yellow squash", "butternut squash",
            "acorn squash", "spaghetti squash", "pumpkin", "eggplant", "aubergine",
            // Stalks & Shoots
            "celery", "asparagus", "artichoke", "fennel", "bamboo shoot",
            // Pods & Seeds
            "green bean", "snap pea", "snow pea", "pea", "okra", "corn", "sweet corn",
            // Mushrooms
            "mushroom", "button mushroom", "cremini", "portobello", "shiitake",
            "oyster mushroom", "enoki", "maitake", "chanterelle", "porcini",
            // Asian Vegetables
            "water chestnut", "bean sprout", "seaweed", "nori", "wakame", "kombu",
            // Others
            "cucumber", "pickle"
        ],
        
        // MARK: Fruits
        "Fruits": [
            // Pome & Stone
            "apple", "pear", "peach", "nectarine", "plum", "apricot", "cherry",
            // Citrus
            "lemon", "lime", "orange", "blood orange", "mandarin", "tangerine",
            "grapefruit", "yuzu", "kumquat",
            // Berries
            "strawberry", "blueberry", "raspberry", "blackberry", "cranberry",
            // Tropical
            "mango", "pineapple", "papaya", "passion fruit", "dragon fruit",
            "lychee", "longan", "guava", "star fruit", "persimmon", "pomegranate",
            "fig", "kiwi", "tamarind",
            // Melons
            "watermelon", "cantaloupe", "honeydew", "melon",
            // Others
            "banana", "plantain", "coconut", "avocado", "grape", "raisin", "date"
        ],
        
        // MARK: Grains & Carbohydrates
        "Grains & Pasta": [
            // Rice
            "rice", "white rice", "brown rice", "basmati", "jasmine", "arborio",
            "sushi rice", "sticky rice", "wild rice", "black rice",
            "rice noodle", "rice paper", "rice flour",
            // Bread
            "bread", "white bread", "whole wheat bread", "sourdough", "baguette",
            "ciabatta", "focaccia", "pita", "naan", "roti", "chapati", "paratha",
            "tortilla", "flatbread", "lavash",
            // Flour
            "flour", "all-purpose flour", "bread flour", "cake flour",
            "whole wheat flour", "00 flour", "semolina", "rye flour",
            // Pasta
            "pasta", "spaghetti", "linguine", "fettuccine", "penne", "rigatoni",
            "fusilli", "farfalle", "macaroni", "shells", "ziti", "orecchiette",
            "lasagna", "ravioli", "tortellini", "gnocchi", "orzo",
            // Asian Noodles
            "noodle", "ramen", "udon", "soba", "lo mein", "chow mein",
            "egg noodle", "glass noodle",
            // Other Grains
            "quinoa", "couscous", "bulgur", "farro", "barley", "millet",
            "polenta", "cornmeal", "grits", "oats", "oatmeal", "cereal", "granola"
        ],
        
        // MARK: Legumes & Pulses
        "Legumes & Pulses": [
            "bean", "black bean", "kidney bean", "pinto bean", "white bean",
            "cannellini", "navy bean", "lima bean", "fava bean", "chickpea",
            "garbanzo", "lentil", "red lentil", "green lentil", "split pea",
            "tofu", "tempeh", "edamame", "soybean", "mung bean",
            "peanut", "peanut butter"
        ],
        
        // MARK: Nuts & Seeds
        "Nuts & Seeds": [
            "almond", "walnut", "pecan", "cashew", "pistachio", "hazelnut",
            "macadamia", "chestnut", "pine nut", "brazil nut",
            "almond butter", "cashew butter", "nutella",
            "sesame", "tahini", "sunflower seed", "pumpkin seed", "chia seed",
            "flax seed", "poppy seed", "hemp seed"
        ],
        
        // MARK: Dairy & Eggs
        "Dairy & Eggs": [
            // Milk & Cream
            "milk", "whole milk", "skim milk", "buttermilk", "evaporated milk",
            "condensed milk", "powdered milk",
            "almond milk", "soy milk", "oat milk", "rice milk",
            "cream", "heavy cream", "whipping cream", "half and half",
            "sour cream", "crème fraîche", "whipped cream",
            // Butter
            "butter", "unsalted butter", "salted butter",
            // Cheese
            "cheese", "ricotta", "cottage cheese", "cream cheese", "mascarpone",
            "mozzarella", "burrata", "paneer", "queso fresco",
            "brie", "camembert", "fontina", "havarti",
            "cheddar", "colby", "gouda", "gruyère", "swiss", "provolone",
            "parmesan", "parmigiano reggiano", "pecorino", "grana padano",
            "blue cheese", "gorgonzola", "roquefort", "stilton",
            "goat cheese", "chèvre", "feta", "halloumi",
            // Yogurt & Eggs
            "yogurt", "greek yogurt", "kefir", "labneh",
            "egg", "eggs", "egg white", "egg yolk"
        ],
        
        // MARK: Herbs & Fresh Spices
        "Herbs & Fresh Spices": [
            "basil", "thai basil", "parsley", "cilantro", "oregano", "thyme",
            "rosemary", "sage", "bay leaf", "tarragon", "mint", "dill",
            "lemongrass", "kaffir lime", "curry leaf", "shiso",
            "fresh ginger", "fresh turmeric", "galangal", "horseradish", "wasabi"
        ],
        
        // MARK: Dried Spices & Seasonings
        "Dried Spices & Seasonings": [
            // Ground Spices
            "cumin", "coriander", "turmeric", "paprika", "smoked paprika",
            "cayenne", "chili powder", "ginger powder", "garlic powder",
            "onion powder", "mustard powder", "celery seed",
            "cinnamon", "nutmeg", "mace", "clove", "allspice", "cardamom",
            // Whole Spices
            "peppercorn", "black pepper", "white pepper", "szechuan pepper",
            "star anise", "fennel seed", "caraway", "anise seed", "mustard seed",
            "fenugreek", "nigella", "saffron", "vanilla bean", "cinnamon stick",
            // Chiles
            "dried chili", "ancho", "chipotle", "guajillo", "chile de arbol",
            // Spice Blends
            "garam masala", "curry powder", "tikka masala", "tandoori masala",
            "za'atar", "ras el hanout", "baharat", "berbere", "dukkah", "sumac",
            "chinese five spice", "shichimi togarashi", "furikake",
            "jerk seasoning", "cajun seasoning", "old bay", "italian seasoning",
            "herbes de provence",
            // Salts & Peppers
            "salt", "sea salt", "kosher salt", "himalayan salt", "black salt",
            "pepper", "red pepper flake", "chile flake", "aleppo pepper"
        ],
        
        // MARK: Oils & Fats
        "Oils & Fats": [
            "olive oil", "extra virgin olive oil",
            "vegetable oil", "canola oil", "sunflower oil", "corn oil",
            "peanut oil", "sesame oil", "toasted sesame oil", "walnut oil",
            "coconut oil", "avocado oil", "truffle oil", "chili oil",
            "lard", "duck fat", "chicken fat", "schmaltz", "tallow",
            "shortening", "ghee", "clarified butter", "margarine", "cooking spray"
        ],
        
        // MARK: Sauces & Condiments
        "Sauces & Condiments": [
            // Asian Sauces
            "soy sauce", "tamari", "fish sauce", "oyster sauce", "hoisin sauce",
            "teriyaki", "ponzu", "sambal", "sriracha", "sweet chili sauce",
            "gochujang", "doenjang", "miso", "xo sauce",
            // Western Condiments
            "ketchup", "mustard", "dijon mustard", "mayo", "mayonnaise",
            "worcestershire", "hot sauce", "tabasco", "bbq sauce",
            // European Sauces
            "pesto", "marinara", "tomato sauce", "alfredo",
            // Middle Eastern
            "tahini", "hummus", "harissa", "pomegranate molasses", "tamarind",
            // Indian
            "curry paste", "chutney", "pickle", "raita",
            // Vinegars
            "vinegar", "white vinegar", "red wine vinegar", "balsamic vinegar",
            "rice vinegar", "apple cider vinegar", "sherry vinegar",
            // Pastes & Stocks
            "tomato paste", "tomato puree", "curry paste", "ginger paste",
            "stock", "broth", "chicken stock", "beef stock", "vegetable stock",
            "dashi", "bouillon",
            // Brined/Pickled Items
            "olive", "kalamata", "green olive", "black olive",
            "relish", "capers", "kimchi", "sauerkraut", "pickled ginger",
            "wasabi", "horseradish",
            // Coconut Products (cooking liquids)
            "coconut milk", "coconut cream"
        ],
        
        // MARK: Sweeteners
        "Sweeteners": [
            "sugar", "white sugar", "brown sugar", "raw sugar", "powdered sugar",
            "honey", "maple syrup", "agave", "corn syrup", "molasses",
            "stevia", "monk fruit"
        ]
    ]

    
    // MARK: - Category Helpers
    
    static func categoryIcon(for category: String) -> String {
        switch category {
        // Shopping Categories
        case "Produce": return "leaf.fill"
        case "Meat": return "fork.knife.circle.fill"
        case "Poultry": return "bird.fill"
        case "Seafood": return "fish.fill"
        case "Dairy & Eggs": return "drop.fill"
        case "Bakery": return "birthday.cake.fill"
        case "Grains & Pasta": return "takeoutbag.and.cup.and.straw.fill"
        case "Legumes & Pulses": return "circle.grid.cross.fill"
        case "Nuts & Seeds": return "leaf.circle.fill"
        case "Herbs & Fresh Spices": return "leaf.fill"
        case "Dried Spices & Seasonings": return "sparkles"
        case "Oils & Fats": return "drop.circle.fill"
        case "Sauces & Condiments": return "bottle.fill"
        case "Canned & Jarred": return "cylinder.fill"
        case "Frozen": return "snowflake"
        case "Beverages": return "cup.and.saucer.fill"
        case "Sweeteners": return "star.fill"
        case "Baking Supplies": return "scalemass.fill"
        case "Snacks": return "camera.macro"
        // Kitchen Categories (some overlap with shopping)
        case "Vegetables": return "carrot.fill"
        case "Fruits": return "apple.logo"
        // Legacy support
        case "Meat & Seafood": return "fish.fill"
        case "Proteins": return "fork.knife"
        case "Kitchen": return "cabinet.fill"
        case "Grains & Noodles": return "takeoutbag.and.cup.and.straw.fill"
        case "Spices & Herbs": return "leaf.fill"
        default: return "shippingbox.fill"
        }
    }
    
    
    static func categoryColor(for category: String) -> Color {
        switch category {
        // Shopping Categories
        case "Produce": return .green
        case "Meat": return .red
        case "Poultry": return .orange
        case "Seafood": return .blue
        case "Dairy & Eggs": return .cyan
        case "Bakery": return .brown
        case "Grains & Pasta": return .yellow
        case "Legumes & Pulses": return .green
        case "Nuts & Seeds": return .brown
        case "Herbs & Fresh Spices": return .green
        case "Dried Spices & Seasonings": return .orange
        case "Oils & Fats": return .yellow
        case "Sauces & Condiments": return .purple
        case "Canned & Jarred": return .gray
        case "Frozen": return .cyan
        case "Beverages": return .blue
        case "Sweeteners": return .pink
        case "Baking Supplies": return .brown
        case "Snacks": return .orange
        // Kitchen Categories
        case "Vegetables": return .green
        case "Fruits": return .red
        // Legacy support
        case "Meat & Seafood": return .red
        case "Proteins": return .red
        case "Kitchen": return .brown
        case "Grains & Noodles": return .yellow
        case "Spices & Herbs": return .orange
        default: return .gray
        }
    }
    
    
    // MARK: - Categorization Logic
    
    // swiftlint:disable cyclomatic_complexity function_body_length
    static func categorize(_ itemName: String) -> String {
        let lowercased = itemName.lowercased()
        
        // Helper function to check if lowercased contains any keyword
        func matchesCategory(_ keywords: [String]) -> Bool {
            keywords.contains { lowercased.contains($0.lowercased()) }
        }
        
        // Priority order matters! Check most specific categories first
        
        // 1. Frozen (check first to avoid conflicts)
        if lowercased.contains("frozen") || lowercased.contains("ice cream") {
            return "Frozen"
        }
        
        // 2. Bakery (before grains to catch bread products)
        let bakeryKeywords = ["bread", "baguette", "croissant", "bagel", "muffin", "donut",
                             "pastry", "cake", "cookie", "pie", "tart", "scone"]
        if matchesCategory(bakeryKeywords) {
            return "Bakery"
        }
        
        // 3. Sweeteners (before other categories that might contain sugar terms)
        if let keywords = kitchenIngredientKeywords["Sweeteners"], matchesCategory(keywords) {
            return "Sweeteners"
        }
        
        // 4. Poultry (before Meat to prioritize correctly)
        if let keywords = kitchenIngredientKeywords["Poultry"], matchesCategory(keywords) {
            return "Poultry"
        }
        
        // 5. Seafood (before general proteins)
        if let keywords = kitchenIngredientKeywords["Seafood"], matchesCategory(keywords) {
            return "Seafood"
        }
        
        // 6. Meat
        if let keywords = kitchenIngredientKeywords["Meat"], matchesCategory(keywords) {
            return "Meat"
        }
        
        // 7. Herbs & Fresh Spices (before Vegetables to catch fresh herbs)
        if let keywords = kitchenIngredientKeywords["Herbs & Fresh Spices"], matchesCategory(keywords) {
            return "Herbs & Fresh Spices"
        }
        
        // 8. Dried Spices & Seasonings
        if let keywords = kitchenIngredientKeywords["Dried Spices & Seasonings"], matchesCategory(keywords) {
            return "Dried Spices & Seasonings"
        }
        
        // 9. Nuts & Seeds (before legumes)
        if let keywords = kitchenIngredientKeywords["Nuts & Seeds"], matchesCategory(keywords) {
            return "Nuts & Seeds"
        }
        
        // 10. Legumes & Pulses
        if let keywords = kitchenIngredientKeywords["Legumes & Pulses"], matchesCategory(keywords) {
            return "Legumes & Pulses"
        }
        
        // 11. Fruits (map to Produce for shopping list)
        if let keywords = kitchenIngredientKeywords["Fruits"], matchesCategory(keywords) {
            return "Produce"  // Map fruits to Produce category for shopping
        }
        
        // 12. Vegetables / Produce
        if let keywords = kitchenIngredientKeywords["Vegetables"], matchesCategory(keywords) {
            return "Produce"  // Shopping category
        }
        
        // 13. Dairy & Eggs
        if let keywords = kitchenIngredientKeywords["Dairy & Eggs"], matchesCategory(keywords) {
            return "Dairy & Eggs"
        }
        
        // 14. Oils & Fats (before Sauces)
        if let keywords = kitchenIngredientKeywords["Oils & Fats"], matchesCategory(keywords) {
            return "Oils & Fats"
        }
        
        // 15. Sauces & Condiments
        if let keywords = kitchenIngredientKeywords["Sauces & Condiments"], matchesCategory(keywords) {
            return "Sauces & Condiments"
        }
        
        // 16. Grains & Pasta
        if let keywords = kitchenIngredientKeywords["Grains & Pasta"], matchesCategory(keywords) {
            return "Grains & Pasta"
        }
        
        // 17. Beverages
        let beverageKeywords = ["water", "juice", "soda", "coffee", "tea", "beer", "wine",
                               "vodka", "whiskey", "rum", "lemonade", "smoothie"]
        if matchesCategory(beverageKeywords) {
            return "Beverages"
        }
        
        // 18. Canned & Jarred
        if lowercased.contains("canned") || lowercased.contains("jar") {
            return "Canned & Jarred"
        }
        
        // 19. Baking Supplies
        let bakingKeywords = ["baking powder", "baking soda", "yeast", "cornstarch",
                             "gelatin", "cocoa powder"]
        if matchesCategory(bakingKeywords) {
            return "Baking Supplies"
        }
        
        // Default: Other
        return "Other"
    }
    // swiftlint:enable cyclomatic_complexity function_body_length
    
    // Get suggested categories based on partial input (for autocomplete)
    static func suggestCategory(for partialInput: String) -> String {
        if partialInput.count < 3 {
            return "Other"
        }
        return categorize(partialInput)
    }
    
    // Check if an ingredient name is valid (not just a descriptor word)
    static func isValidIngredient(_ name: String) -> Bool {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Filter out pure descriptor words
        if descriptorWords.contains(cleaned) {
            return false
        }
        
        // Must have at least one actual ingredient keyword
        let hasIngredientKeyword = kitchenIngredientKeywords.values.flatMap { $0 }.contains { keyword in
            cleaned.localizedCaseInsensitiveContains(keyword)
        }
        
        return hasIngredientKeyword || cleaned.count > 15 // Allow longer names that might not match keywords
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
            
            // Filter out pure descriptor words at the start
            let filteredWords = words.filter { word in
                !descriptorWords.contains(word.lowercased())
            }
            
            if filteredWords.isEmpty {
                continue // Skip if only descriptors
            }
            
            if filteredWords.count >= 2 {
                // For compound ingredients like "black pepper", "soy sauce", keep both words
                let firstTwo = filteredWords.prefix(2).joined(separator: " ")
                
                // Check if it's a common compound ingredient
                let compounds = ["black pepper", "soy sauce", "oyster sauce", "fish sauce", 
                               "olive oil", "sesame oil", "coconut milk", "bell pepper",
                               "green onion", "spring onions", "spring onion", "red onion", "white onion",
                               "black beans", "red beans", "green beans", "rice wine",
                               "brown sugar", "white sugar", "chicken breast", "chicken thigh",
                               "beef chuck", "pork belly", "rice vinegar", "white vinegar",
                               "black vinegar", "sesame seeds", "chili flakes", "curry powder",
                               "chili powder", "garlic powder", "onion powder", "ginger paste",
                               "garlic paste", "tomato paste", "fish paste", "bok choy",
                               "red pepper", "green pepper", "yellow onion", "sweet potato",
                               "soy milk", "almond milk", "peanut butter", "tomato sauce",
                               "chicken stock", "beef stock", "vegetable stock", "fish stock",
                               "egg noodles", "tomato puree", "coconut cream", "heavy cream",
                               "sour cream", "cream cheese", "maple syrup", "corn starch",
                               "baking powder", "baking soda", "vanilla extract"]
                
                if compounds.contains(firstTwo.lowercased()) {
                    mainIngredients.insert(firstTwo.capitalized)
                } else if let first = filteredWords.first {
                    mainIngredients.insert(first.capitalized)
                }
            } else if let first = filteredWords.first {
                mainIngredients.insert(first.capitalized)
            }
        }
        
        return Array(mainIngredients).sorted()
    }
}
