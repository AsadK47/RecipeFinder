import Foundation
import SwiftUI

enum CategoryClassifier {

    // Memoize categorize(): runs per-item during shopping-list rendering and scans all rules. MemoCache is Swift 6 concurrency-safe.
    private static let categoryCache = MemoCache<String, String>(maxSize: 500)

    static let categoryOrder = [
        "Produce", "Meat", "Poultry", "Seafood", "Dairy & Eggs",
        "Bakery", "Grains & Pasta", "Legumes & Pulses", "Nuts & Seeds",
        "Herbs & Fresh Spices", "Dried Spices & Seasonings",
        "Oils & Fats", "Sauces & Condiments", "Canned & Jarred",
        "Frozen", "Beverages", "Sweeteners", "Baking Supplies", "Snacks", "Other"
    ]
    
    static let kitchenCategories = [
        "Meat", "Poultry", "Seafood", "Vegetables", "Fruits",
        "Grains & Pasta", "Legumes & Pulses", "Nuts & Seeds",
        "Dairy & Eggs", "Herbs & Fresh Spices", "Dried Spices & Seasonings",
        "Oils & Fats", "Sauces & Condiments", "Sweeteners"
    ]
    
    static let descriptorWords = [
        "large", "small", "medium", "fresh", "dried", "frozen", "canned",
        "chopped", "sliced", "diced", "minced", "whole", "ground", "raw", "cooked",
        "boneless", "skinless", "organic", "wild", "caught", "grass-fed", "free-range",
        "peeled", "shredded", "grated", "crushed", "toasted", "roasted", "smoked"
    ]
    
    static let kitchenIngredientKeywords: [String: [String]] = [
        
        "Meat": [
            "beef", "steak", "sirloin", "ribeye", "t-bone", "filet mignon",
            "tenderloin", "ground beef", "chuck", "brisket", "short rib", "oxtail",
            "flank", "skirt steak", "rump", "topside", "mince", "minced beef",
            "pork", "bacon", "ham", "pork chop", "pork belly", "pancetta", "prosciutto",
            "sausage", "chorizo", "salami", "pepperoni", "guanciale",
            "pork loin", "pork shoulder", "ground pork", "italian sausage",
            "gammon", "pork mince",
            "lamb", "mutton", "lamb chop", "lamb shank", "rack of lamb",
            "goat", "lamb leg", "ground lamb", "lamb mince",
            "veal", "venison", "bison", "rabbit", "wild boar"
        ],
        
        "Poultry": [
            "chicken", "chicken breast", "chicken thigh", "chicken wing", "drumstick",
            "whole chicken", "ground chicken", "chicken tender",
            "turkey", "turkey breast", "ground turkey",
            "duck", "duck breast", "duck leg", "duck confit", "goose", "quail"
        ],
        
        "Seafood": [
            "fish", "salmon", "tuna", "cod", "halibut", "tilapia", "mahi mahi",
            "sea bass", "seabass", "branzino", "striped bass",
            "haddock", "pollock", "sole", "flounder", "trout", "mackerel",
            "sardine", "anchovy", "snapper", "catfish", "monkfish",
            "shrimp", "prawn", "lobster", "crab", "crayfish", "crawfish",
            "scallop", "mussel", "clam", "oyster", "squid", "octopus", "calamari",
            "caviar", "roe", "fish eggs", "seafood", "fish sauce"
        ],
        
        "Vegetables": [
            "onion", "onions", "red onion", "white onion", "yellow onion", "sweet onion",
            "shallot", "shallots", "scallion", "scallions", "green onion", "spring onion", "leek", "leeks", "ramp",
            "garlic", "garlic clove", "clove of garlic", "chive", "chives",
            "tomato", "cherry tomato", "grape tomato", "roma tomato",
            "bell pepper", "red pepper", "green pepper", "yellow pepper",
            "capsicum", "chili", "chile", "jalapeño", "serrano", "habanero",
            "poblano", "thai chili",
            "potato", "russet potato", "sweet potato", "yam", "carrot", "parsnip",
            "turnip", "beetroot", "beet", "radish", "daikon", "horseradish",
            "ginger root", "turmeric root", "galangal", "cassava", "yucca", "taro",
            "jicama", "celeriac", "lotus root",
            "broccoli", "cauliflower", "cabbage", "red cabbage", "napa cabbage",
            "brussels sprout", "kale", "collard green", "bok choy", "pak choi",
            "gai lan", "chinese broccoli", "kohlrabi",
            "spinach", "lettuce", "romaine", "arugula", "rocket", "swiss chard",
            "watercress", "endive", "radicchio",
            "zucchini", "courgette", "yellow squash", "butternut squash",
            "acorn squash", "spaghetti squash", "pumpkin", "eggplant", "aubergine",
            "celery", "asparagus", "artichoke", "fennel", "bamboo shoot",
            "green bean", "snap pea", "snow pea", "pea", "okra", "corn", "sweet corn",
            "mushroom", "button mushroom", "cremini", "portobello", "shiitake",
            "oyster mushroom", "enoki", "maitake", "chanterelle", "porcini",
            "water chestnut", "bean sprout", "seaweed", "nori", "wakame", "kombu",
            "cucumber", "pickle"
        ],
        
        "Fruits": [
            "apple", "pear", "peach", "nectarine", "plum", "apricot", "cherry",
            "lemon", "lime", "orange", "blood orange", "mandarin", "tangerine",
            "grapefruit", "yuzu", "kumquat",
            "strawberry", "blueberry", "raspberry", "blackberry", "cranberry",
            "mango", "pineapple", "papaya", "passion fruit", "dragon fruit",
            "lychee", "longan", "guava", "star fruit", "persimmon", "pomegranate",
            "fig", "kiwi", "tamarind",
            "watermelon", "cantaloupe", "honeydew", "melon",
            "banana", "plantain", "coconut", "avocado", "grape", "raisin", "date"
        ],
        
        "Grains & Pasta": [
            "rice", "white rice", "brown rice", "basmati", "jasmine", "arborio",
            "sushi rice", "sticky rice", "wild rice", "black rice", "long grain", "short grain",
            "rice noodle", "rice noodles", "rice paper", "rice flour",
            "bread", "white bread", "whole wheat bread", "sourdough", "baguette",
            "ciabatta", "focaccia", "pita", "naan", "roti", "chapati", "paratha",
            "tortilla", "flatbread", "lavash",
            "flour", "all-purpose flour", "bread flour", "cake flour",
            "whole wheat flour", "00 flour", "semolina", "rye flour",
            "pasta", "spaghetti", "linguine", "fettuccine", "penne", "rigatoni",
            "fusilli", "farfalle", "macaroni", "shells", "ziti", "orecchiette",
            "lasagna", "ravioli", "tortellini", "gnocchi", "orzo",
            "noodle", "ramen", "udon", "soba", "lo mein", "chow mein",
            "egg noodle", "glass noodle",
            "quinoa", "couscous", "bulgur", "farro", "barley", "millet",
            "polenta", "cornmeal", "grits", "oats", "oatmeal", "cereal", "granola"
        ],
        
        "Legumes & Pulses": [
            "bean", "black bean", "kidney bean", "pinto bean", "white bean",
            "cannellini", "navy bean", "lima bean", "fava bean", "chickpea",
            "garbanzo", "lentil", "red lentil", "green lentil", "split pea",
            "tofu", "tempeh", "edamame", "soybean", "mung bean",
            "peanut", "peanut butter"
        ],
        
        "Nuts & Seeds": [
            "almond", "walnut", "pecan", "cashew", "pistachio", "hazelnut",
            "macadamia", "chestnut", "pine nut", "brazil nut",
            "almond butter", "cashew butter", "nutella",
            "sesame", "tahini", "sunflower seed", "pumpkin seed", "chia seed",
            "flax seed", "poppy seed", "hemp seed"
        ],
        
        "Dairy & Eggs": [
            "milk", "whole milk", "skim milk", "buttermilk", "evaporated milk",
            "condensed milk", "powdered milk",
            "almond milk", "soy milk", "oat milk", "rice milk",
            "cream", "heavy cream", "whipping cream", "half and half",
            "sour cream", "crème fraîche", "whipped cream",
            "cheese", "ricotta", "cottage cheese", "cream cheese", "mascarpone",
            "mozzarella", "burrata", "paneer", "queso fresco",
            "brie", "camembert", "fontina", "havarti",
            "cheddar", "colby", "gouda", "gruyère", "swiss", "provolone",
            "parmesan", "parmigiano reggiano", "pecorino", "grana padano",
            "blue cheese", "gorgonzola", "roquefort", "stilton",
            "goat cheese", "chèvre", "feta", "halloumi",
            "yogurt", "greek yogurt", "kefir", "labneh",
            "egg", "eggs", "egg white", "egg yolk"
        ],
        
        "Herbs & Fresh Spices": [
            "basil", "thai basil", "parsley", "cilantro", "oregano", "thyme",
            "rosemary", "sage", "bay leaf", "tarragon", "mint", "dill",
            "lemongrass", "kaffir lime", "curry leaf", "shiso",
            "fresh ginger", "fresh turmeric", "galangal", "horseradish", "wasabi"
        ],
        
        "Dried Spices & Seasonings": [
            "cumin", "coriander", "turmeric", "paprika", "smoked paprika",
            "cayenne", "chili powder", "ginger powder", "garlic powder",
            "onion powder", "mustard powder", "celery seed",
            "cinnamon", "nutmeg", "mace", "clove", "allspice", "cardamom",
            "peppercorn", "black pepper", "white pepper", "szechuan pepper",
            "star anise", "fennel seed", "caraway", "anise seed", "mustard seed",
            "fenugreek", "nigella", "saffron", "vanilla bean", "cinnamon stick",
            "dried chili", "ancho", "chipotle", "guajillo", "chile de arbol",
            "garam masala", "curry powder", "tikka masala", "tandoori masala",
            "za'atar", "ras el hanout", "baharat", "berbere", "dukkah", "sumac",
            "chinese five spice", "shichimi togarashi", "furikake",
            "jerk seasoning", "cajun seasoning", "old bay", "italian seasoning",
            "herbes de provence",
            "salt", "sea salt", "kosher salt", "himalayan salt", "black salt",
            "pepper", "red pepper flake", "chile flake", "aleppo pepper"
        ],
        
        "Oils & Fats": [
            "olive oil", "extra virgin olive oil",
            "vegetable oil", "canola oil", "sunflower oil", "corn oil",
            "peanut oil", "sesame oil", "toasted sesame oil", "walnut oil",
            "coconut oil", "avocado oil", "truffle oil", "chili oil",
            "butter", "unsalted butter", "salted butter",
            "lard", "duck fat", "chicken fat", "schmaltz", "tallow",
            "shortening", "ghee", "clarified butter", "margarine", "cooking spray"
        ],
        
        "Sauces & Condiments": [
            "soy sauce", "tamari", "fish sauce", "oyster sauce", "hoisin sauce",
            "teriyaki", "ponzu", "sambal", "sriracha", "sweet chili sauce",
            "gochujang", "doenjang", "miso", "xo sauce",
            "ketchup", "mustard", "dijon mustard", "mayo", "mayonnaise",
            "worcestershire", "hot sauce", "tabasco", "bbq sauce",
            "pesto", "marinara", "tomato sauce", "alfredo",
            "tahini", "hummus", "harissa", "pomegranate molasses", "tamarind",
            "curry paste", "chutney", "pickle", "raita",
            "vinegar", "white vinegar", "red wine vinegar", "balsamic vinegar",
            "rice vinegar", "apple cider vinegar", "sherry vinegar",
            "tomato paste", "tomato puree", "curry paste", "ginger paste",
            "stock", "broth", "chicken stock", "beef stock", "vegetable stock",
            "dashi", "bouillon",
            "olive", "kalamata", "green olive", "black olive",
            "relish", "capers", "kimchi", "sauerkraut", "pickled ginger",
            "wasabi", "horseradish",
            "coconut milk", "coconut cream"
        ],
        
        "Sweeteners": [
            "sugar", "white sugar", "brown sugar", "raw sugar", "powdered sugar",
            "honey", "maple syrup", "agave", "corn syrup", "molasses",
            "stevia", "monk fruit"
        ]
    ]

    static func categoryIcon(for category: String) -> String {
        switch category {
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
        case "Sauces & Condiments", "Condiments & Sauces": return "drop.fill"
        case "Canned & Jarred": return "cylinder.fill"
        case "Frozen": return "snowflake"
        case "Beverages": return "cup.and.saucer.fill"
        case "Sweeteners": return "star.fill"
        case "Baking Supplies": return "scalemass.fill"
        case "Snacks": return "camera.macro"
        case "Vegetables": return "carrot.fill"
        case "Fruits": return "apple.logo"
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
        case "Sauces & Condiments", "Condiments & Sauces": return .purple
        case "Canned & Jarred": return .gray
        case "Frozen": return .cyan
        case "Beverages": return .blue
        case "Sweeteners": return .pink
        case "Baking Supplies": return .brown
        case "Snacks": return .orange
        case "Vegetables": return .green
        case "Fruits": return .red
        case "Meat & Seafood": return .red
        case "Proteins": return .red
        case "Kitchen": return .brown
        case "Grains & Noodles": return .yellow
        case "Spices & Herbs": return .orange
        default: return .gray
        }
    }
    
    // Built once — avoids rebuilding on every categorize() call
    private static let categorizationRules: [(String, [String])] = [
        ("Frozen",                    ["frozen", "ice cream"]),
        ("Bakery",                    ["bread", "baguette", "croissant", "bagel", "muffin", "donut",
                                       "pastry", "cake", "cookie", "pie", "tart", "scone"]),
        ("Sweeteners",                kitchenIngredientKeywords["Sweeteners"]               ?? []),
        ("Poultry",                   kitchenIngredientKeywords["Poultry"]                  ?? []),
        ("Seafood",                   kitchenIngredientKeywords["Seafood"]                  ?? []),
        ("Meat",                      kitchenIngredientKeywords["Meat"]                     ?? []),
        ("Herbs & Fresh Spices",      kitchenIngredientKeywords["Herbs & Fresh Spices"]     ?? []),
        ("Dried Spices & Seasonings", kitchenIngredientKeywords["Dried Spices & Seasonings"] ?? []),
        ("Nuts & Seeds",              kitchenIngredientKeywords["Nuts & Seeds"]             ?? []),
        ("Legumes & Pulses",          kitchenIngredientKeywords["Legumes & Pulses"]         ?? []),
        ("Canned & Jarred",           ["canned", "jarred"]),
        // Cooking citrus juice is bought as fruit, not as a drink — must precede the generic "juice" rule.
        ("Produce",                   ["lemon juice", "lime juice"]),
        ("Beverages",                 ["juice", "water", "soda", "coffee", "tea", "beer", "wine",
                                       "vodka", "whiskey", "rum", "lemonade", "smoothie"]),
        ("Produce",                   (kitchenIngredientKeywords["Fruits"]     ?? []) +
                                      (kitchenIngredientKeywords["Vegetables"] ?? [])),
        ("Oils & Fats",               kitchenIngredientKeywords["Oils & Fats"]              ?? []),
        ("Dairy & Eggs",              kitchenIngredientKeywords["Dairy & Eggs"]             ?? []),
        ("Sauces & Condiments",       kitchenIngredientKeywords["Sauces & Condiments"]      ?? []),
        ("Grains & Pasta",            kitchenIngredientKeywords["Grains & Pasta"]           ?? []),
        ("Baking Supplies",           ["baking powder", "baking soda", "yeast", "cornstarch",
                                       "gelatin", "cocoa powder"]),
    ]

    static func categorize(_ itemName: String) -> String {
        let lowercased = itemName.lowercased().trimmed

        return categoryCache.value(for: lowercased) { normalized in
            // Whole-word match so "graham" isn't Meat via "ham"
            let itemWords = IngredientWordMatcher.words(in: normalized)

            func matches(_ keywords: [String]) -> Bool {
                keywords.contains { IngredientWordMatcher.matches(textWords: itemWords, keyword: $0) }
            }

            return categorizationRules.first { matches($0.1) }?.0 ?? "Other"
        }
    }

    static func suggestCategory(for partialInput: String) -> String {
        if partialInput.count < 3 {
            return "Other"
        }
        return categorize(partialInput)
    }
    
    static func groupSimilarIngredients(_ ingredients: [String]) -> [String] {
        var mainIngredients = Set<String>()

        for ingredient in ingredients {
            // Part before first comma, then trim; parens needed or `.trimmingCharacters` binds to the `?? ingredient` fallback and leaves it untrimmed.
            let cleaned = (ingredient.components(separatedBy: ",").first ?? ingredient)
                .trimmed

            let words = cleaned.split(separator: " ").map { String($0) }
            
            let filteredWords = words.filter { word in
                !descriptorWords.contains(word.lowercased())
            }
            
            if filteredWords.isEmpty {
                continue
            }
            
            if filteredWords.count >= 2 {
                let firstTwo = filteredWords.prefix(2).joined(separator: " ")
                
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
