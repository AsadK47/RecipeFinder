import Foundation
import SwiftUI

/// Comprehensive World Food Classification System
/// Based on research from USDA, culinary standards, and international cuisine analysis
/// Sources: USDA Food Categories, Bon Appétit, Serious Eats, Food Network
enum CategoryClassifierComprehensive {
    
    // MARK: - Shopping List Categories
    
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
        "peeled", "shredded", "grated", "crushed", "toasted", "roasted"
    ]
    
    // MARK: - Comprehensive Ingredient Keywords
    
    /// World-class ingredient categorization covering international cuisines
    static let kitchenIngredientKeywords: [String: [String]] = [
        
        // MARK: Proteins - Meat
        "Meat": [
            // Beef
            "beef", "steak", "sirloin", "ribeye", "t-bone", "porterhouse", "filet mignon",
            "tenderloin", "ground beef", "chuck", "brisket", "short rib", "oxtail",
            "beef shank", "flank", "skirt steak", "hanger steak", "prime rib",
            // Pork
            "pork", "bacon", "ham", "pork chop", "pork belly", "pancetta", "prosciutto",
            "sausage", "chorizo", "salami", "pepperoni", "mortadella", "guanciale",
            "pork loin", "pork shoulder", "pork tenderloin", "ground pork", "italian sausage",
            "bratwurst", "kielbasa", "andouille", "lap cheong", "spam",
            // Lamb & Goat
            "lamb", "mutton", "lamb chop", "lamb shank", "lamb shoulder", "rack of lamb",
            "goat", "kid", "lamb leg", "ground lamb",
            // Game & Specialty
            "veal", "venison", "deer", "elk", "buffalo", "bison", "rabbit", "wild boar",
            "kangaroo", "ostrich", "alligator"
        ],
        
        // MARK: Proteins - Poultry
        "Poultry": [
            // Chicken
            "chicken", "chicken breast", "chicken thigh", "chicken wing", "drumstick",
            "chicken leg", "whole chicken", "ground chicken", "chicken tender",
            // Turkey
            "turkey", "turkey breast", "ground turkey", "turkey leg", "turkey wing",
            // Other Poultry
            "duck", "duck breast", "duck leg", "duck confit", "goose", "quail",
            "cornish hen", "pheasant", "guinea fowl", "squab", "pigeon"
        ],
        
        // MARK: Proteins - Seafood
        "Seafood": [
            // Popular Fish
            "fish", "salmon", "tuna", "cod", "halibut", "tilapia", "mahi mahi",
            "sea bass", "seabass", "branzino", "striped bass",
            // White Fish
            "haddock", "pollock", "sole", "flounder", "plaice", "turbot", "john dory",
            // Oily Fish
            "trout", "mackerel", "sardine", "anchovy", "herring", "swordfish",
            // Asian Fish
            "snapper", "grouper", "barramundi", "pomfret", "kingfish",
            // Other Fish
            "catfish", "perch", "pike", "carp", "eel", "monkfish",
            // Shellfish - Crustaceans
            "shrimp", "prawn", "lobster", "crab", "crayfish", "crawfish", "langoustine",
            "king crab", "snow crab", "blue crab", "dungeness crab",
            // Shellfish - Mollusks
            "scallop", "mussel", "clam", "oyster", "abalone", "whelk", "cockle",
            // Cephalopods
            "squid", "octopus", "calamari", "cuttlefish",
            // Roe & Others
            "caviar", "roe", "fish eggs", "uni", "sea urchin", "sea cucumber",
            "fish sauce", "seafood"
        ],
        
        // MARK: Vegetables - Comprehensive World Coverage
        "Vegetables": [
            // Alliums
            "onion", "red onion", "white onion", "yellow onion", "sweet onion",
            "shallot", "scallion", "green onion", "spring onion", "leek", "ramp",
            "garlic", "elephant garlic", "chive", "garlic chive",
            // Nightshades
            "tomato", "cherry tomato", "grape tomato", "roma tomato", "beefsteak",
            "heirloom tomato", "tomatillo", "bell pepper", "red pepper", "green pepper",
            "yellow pepper", "orange pepper", "capsicum", "chili", "chile", "jalapeño",
            "serrano", "habanero", "scotch bonnet", "poblano", "anaheim", "thai chili",
            "bird's eye", "ghost pepper", "carolina reaper",
            // Root Vegetables
            "potato", "russet potato", "yukon gold", "red potato", "fingerling",
            "sweet potato", "yam", "carrot", "parsnip", "turnip", "rutabaga", "swede",
            "beetroot", "beet", "radish", "daikon", "horseradish", "ginger root",
            "turmeric root", "galangal", "cassava", "yucca", "manioc", "taro", "malanga",
            "jicama", "celeriac", "celery root", "salsify", "burdock", "lotus root",
            // Brassicas
            "broccoli", "cauliflower", "romanesco", "cabbage", "red cabbage", "savoy cabbage",
            "napa cabbage", "chinese cabbage", "brussels sprout", "kale", "collard green",
            "mustard green", "turnip green", "bok choy", "pak choi", "baby bok choy",
            "choy sum", "gai lan", "chinese broccoli", "kohlrabi",
            // Leafy Greens
            "spinach", "lettuce", "romaine", "iceberg", "butter lettuce", "bibb lettuce",
            "arugula", "rocket", "swiss chard", "chard", "watercress", "endive",
            "radicchio", "frisée", "escarole", "sorrel", "dandelion green",
            // Squashes
            "zucchini", "courgette", "yellow squash", "pattypan", "butternut squash",
            "acorn squash", "spaghetti squash", "delicata squash", "kabocha", "pumpkin",
            "calabaza", "chayote", "eggplant", "aubergine", "japanese eggplant",
            // Stalks & Shoots
            "celery", "asparagus", "artichoke", "fennel", "bamboo shoot", "hearts of palm",
            "fiddlehead fern", "rhubarb",
            // Pods & Seeds
            "green bean", "string bean", "wax bean", "snap pea", "snow pea", "sugar snap",
            "pea", "garden pea", "english pea", "edamame", "lima bean", "fava bean",
            "broad bean", "okra", "corn", "baby corn", "sweet corn",
            // Mushrooms
            "mushroom", "button mushroom", "cremini", "portobello", "shiitake",
            "oyster mushroom", "enoki", "maitake", "hen of the woods", "chanterelle",
            "porcini", "morel", "truffle", "black truffle", "white truffle", "king oyster",
            // Asian Vegetables
            "water chestnut", "bean sprout", "mung bean sprout", "soy sprout",
            "seaweed", "nori", "wakame", "kombu", "kelp", "hijiki", "dulse",
            // Others
            "cucumber", "persian cucumber", "english cucumber", "pickle", "gherkin",
            "olive", "kalamata", "green olive", "black olive", "caper", "pickled pepper"
        ],
        
        // MARK: Fruits - Complete International Coverage
        "Fruits": [
            // Pome Fruits
            "apple", "granny smith", "gala", "honeycrisp", "fuji", "red delicious",
            "pear", "bosc pear", "anjou", "asian pear", "quince",
            // Citrus
            "lemon", "lime", "key lime", "orange", "blood orange", "navel orange",
            "mandarin", "tangerine", "clementine", "grapefruit", "pomelo", "yuzu",
            "kumquat", "bergamot", "citron", "finger lime",
            // Berries
            "strawberry", "blueberry", "raspberry", "blackberry", "cranberry",
            "gooseberry", "currant", "red currant", "black currant", "elderberry",
            "mulberry", "boysenberry", "loganberry", "açaí", "goji berry",
            "lingonberry", "cloudberry", "huckleberry",
            // Stone Fruits
            "peach", "nectarine", "plum", "apricot", "cherry", "bing cherry",
            "rainier cherry", "sour cherry", "date", "medjool date",
            // Tropical
            "mango", "pineapple", "papaya", "passion fruit", "dragon fruit", "pitaya",
            "lychee", "longan", "rambutan", "mangosteen", "durian", "jackfruit",
            "guava", "star fruit", "carambola", "persimmon", "pomegranate", "fig",
            "kiwi", "kiwifruit", "sapodilla", "soursop", "custard apple", "cherimoya",
            "tamarind", "breadfruit",
            // Melons
            "watermelon", "cantaloupe", "honeydew", "melon", "muskmelon", "casaba",
            "crenshaw", "santa claus melon",
            // Bananas & Plantains
            "banana", "plantain", "cooking banana",
            // Others
            "coconut", "avocado", "olive", "tomato", "grape", "red grape", "green grape",
            "raisin", "dried fruit", "prune"
        ],
        
        // MARK: Grains & Carbohydrates
        "Grains & Pasta": [
            // Rice Varieties
            "rice", "white rice", "brown rice", "basmati", "jasmine", "arborio",
            "sushi rice", "sticky rice", "glutinous rice", "wild rice", "black rice",
            "red rice", "bomba rice", "carnaroli", "calrose", "long grain", "short grain",
            // Rice Products
            "rice noodle", "rice vermicelli", "rice paper", "rice flour", "rice cake",
            // Wheat Products - Bread
            "bread", "white bread", "whole wheat bread", "multigrain", "sourdough",
            "rye bread", "pumpernickel", "baguette", "ciabatta", "focaccia",
            "pita", "flatbread", "naan", "roti", "chapati", "paratha", "puri",
            "tortilla", "corn tortilla", "flour tortilla", "wrap", "lavash",
            "injera", "arepa", "piadina",
            // Wheat Products - Flour
            "flour", "all-purpose flour", "bread flour", "cake flour", "pastry flour",
            "whole wheat flour", "self-rising flour", "00 flour", "semolina",
            "durum flour", "rye flour", "spelt flour",
            // Italian Pasta
            "pasta", "spaghetti", "linguine", "fettuccine", "penne", "rigatoni",
            "fusilli", "rotini", "farfalle", "bow tie", "macaroni", "shells", "conchiglie",
            "ziti", "mostaccioli", "orecchiette", "cavatappi", "bucatini", "angel hair",
            "capellini", "tagliatelle", "pappardelle", "lasagna", "cannelloni",
            "ravioli", "tortellini", "agnolotti", "gnocchi", "orzo", "acini di pepe",
            // Asian Noodles
            "noodle", "ramen", "udon", "soba", "somen", "lo mein", "chow mein",
            "pad thai noodle", "egg noodle", "wonton wrapper", "dumpling wrapper",
            "glass noodle", "cellophane noodle", "bean thread", "shirataki",
            // Other Grains
            "quinoa", "couscous", "israeli couscous", "pearl couscous", "bulgur",
            "cracked wheat", "farro", "spelt", "barley", "pearl barley", "millet",
            "amaranth", "teff", "buckwheat", "groats", "kasha", "polenta", "cornmeal",
            "grits", "hominy", "wheat berries", "freekeh", "kamut",
            // Oats
            "oats", "oatmeal", "rolled oats", "steel-cut oats", "quick oats", "oat bran",
            // Breakfast
            "cereal", "granola", "muesli", "corn flakes", "bran flakes",
            // Crackers
            "cracker", "saltine", "graham cracker", "water cracker", "matzo"
        ],
        
        // MARK: Legumes & Pulses
        "Legumes & Pulses": [
            // Beans
            "bean", "black bean", "kidney bean", "red kidney", "white kidney",
            "pinto bean", "white bean", "cannellini", "great northern", "navy bean",
            "lima bean", "butter bean", "fava bean", "broad bean", "cranberry bean",
            "borlotti", "adzuki", "anasazi", "mung bean", "black-eyed pea", "cowpea",
            // Lentils
            "lentil", "red lentil", "green lentil", "brown lentil", "black lentil",
            "yellow lentil", "french lentil", "puy lentil", "beluga lentil",
            // Chickpeas & Peas
            "chickpea", "garbanzo", "hummus", "split pea", "yellow split pea",
            "green split pea", "pea", "field pea", "pigeon pea",
            // Soy Products
            "soybean", "soy", "tofu", "firm tofu", "silken tofu", "tempeh", "edamame",
            "natto", "miso", "soy protein", "tvp", "textured vegetable protein",
            // Peanuts
            "peanut", "peanut butter", "groundnut"
        ],
        
        // MARK: Nuts & Seeds
        "Nuts & Seeds": [
            // Tree Nuts
            "almond", "walnut", "pecan", "cashew", "pistachio", "hazelnut", "filbert",
            "macadamia", "chestnut", "pine nut", "pignoli", "brazil nut", "hickory nut",
            // Nut Butters
            "almond butter", "cashew butter", "hazelnut spread", "nutella",
            // Seeds
            "sesame", "sesame seed", "tahini", "sunflower seed", "pumpkin seed",
            "pepita", "chia seed", "flax seed", "linseed", "poppy seed", "hemp seed",
            "hemp heart", "nigella", "black seed", "fennel seed", "anise seed",
            "caraway seed", "cumin seed", "coriander seed", "mustard seed", "fenugreek"
        ],
        
        // MARK: Dairy & Eggs
        "Dairy & Eggs": [
            // Milk
            "milk", "whole milk", "2% milk", "skim milk", "low-fat milk", "fat-free milk",
            "buttermilk", "evaporated milk", "condensed milk", "sweetened condensed milk",
            "powdered milk", "milk powder", "malted milk",
            // Plant Milks
            "almond milk", "soy milk", "oat milk", "coconut milk", "rice milk",
            "cashew milk", "hemp milk", "flax milk", "pea milk", "macadamia milk",
            // Cream
            "cream", "heavy cream", "whipping cream", "heavy whipping cream",
            "half and half", "light cream", "sour cream", "crème fraîche",
            "clotted cream", "coconut cream", "whipped cream",
            // Butter
            "butter", "unsalted butter", "salted butter", "cultured butter",
            "european butter", "ghee", "clarified butter", "brown butter",
            // Cheese - Fresh
            "cheese", "ricotta", "cottage cheese", "cream cheese", "mascarpone",
            "quark", "fromage blanc", "burrata", "stracciatella", "mozzarella",
            "fresh mozzarella", "buffalo mozzarella", "paneer", "queso fresco",
            "queso blanco",
            // Cheese - Soft
            "brie", "camembert", "taleggio", "fontina", "monterey jack", "havarti",
            // Cheese - Semi-Hard
            "cheddar", "colby", "gouda", "edam", "jarlsberg", "emmental", "gruyère",
            "comté", "manchego", "asiago", "provolone", "raclette",
            // Cheese - Hard
            "parmesan", "parmigiano reggiano", "pecorino", "pecorino romano",
            "grana padano", "aged cheddar", "aged gouda",
            // Cheese - Blue
            "blue cheese", "gorgonzola", "roquefort", "stilton", "danish blue",
            "maytag blue",
            // Cheese - Goat & Sheep
            "goat cheese", "chèvre", "feta", "halloumi", "ricotta salata",
            "manchego", "roquefort",
            // Cheese - Specialty
            "swiss cheese", "muenster", "limburger", "port salut", "boursin",
            "laughing cow", "velveeta", "american cheese",
            // Yogurt
            "yogurt", "yoghurt", "greek yogurt", "skyr", "icelandic yogurt",
            "labneh", "lebanese yogurt", "kefir", "lassi",
            // Eggs
            "egg", "eggs", "chicken egg", "duck egg", "quail egg", "egg white",
            "egg yolk", "liquid egg"
        ],
        
        // MARK: Herbs & Fresh Spices
        "Herbs & Fresh Spices": [
            // Mediterranean Herbs
            "basil", "sweet basil", "thai basil", "holy basil", "purple basil",
            "parsley", "flat-leaf parsley", "italian parsley", "curly parsley",
            "cilantro", "coriander leaf", "culantro", "oregano", "marjoram",
            "thyme", "rosemary", "sage", "bay leaf", "bay laurel", "tarragon",
            // Asian Herbs
            "mint", "peppermint", "spearmint", "vietnamese mint", "thai mint",
            "lemongrass", "kaffir lime", "lime leaf", "curry leaf", "shiso",
            "perilla", "vietnamese coriander", "saw leaf",
            // Other Fresh Herbs
            "dill", "fennel frond", "chervil", "chive", "garlic chive", "sorrel",
            "lovage", "borage", "savory", "epazote",
            // Fresh Spices
            "fresh ginger", "ginger root", "fresh turmeric", "turmeric root",
            "galangal", "horseradish root", "wasabi root"
        ],
        
        // MARK: Dried Spices & Seasonings
        "Dried Spices & Seasonings": [
            // Ground Spices - Common
            "cumin", "ground cumin", "coriander", "ground coriander", "turmeric",
            "paprika", "smoked paprika", "sweet paprika", "hot paprika",
            "cayenne", "cayenne pepper", "chili powder", "ancho chili",
            "chipotle powder", "ginger powder", "ground ginger",
            "garlic powder", "onion powder", "mustard powder", "celery seed",
            // Ground Spices - Sweet
            "cinnamon", "ground cinnamon", "nutmeg", "ground nutmeg", "mace",
            "clove", "ground clove", "allspice", "ground allspice",
            "cardamom", "ground cardamom", "vanilla powder",
            // Whole Spices
            "peppercorn", "black peppercorn", "white peppercorn", "green peppercorn",
            "pink peppercorn", "szechuan pepper", "sichuan pepper", "grains of paradise",
            "star anise", "fennel seed", "caraway", "anise seed", "coriander seed",
            "cumin seed", "mustard seed", "fenugreek", "fenugreek seed",
            "nigella", "black seed", "black cumin", "ajwain", "carom seed",
            "celery seed", "dill seed", "juniper berry", "saffron",
            "vanilla bean", "cinnamon stick", "cassia bark", "bay leaf", "clove",
            "cardamom pod", "whole nutmeg",
            // Chiles - Dried
            "dried chili", "ancho", "chipotle", "guajillo", "pasilla", "chile de arbol",
            "cascabel", "mulato", "new mexico chile", "california chile", "kashmiri chili",
            "bird's eye chili", "thai chili", "scotch bonnet", "habanero",
            "ghost pepper", "bhut jolokia", "carolina reaper",
            // Spice Blends - Indian
            "garam masala", "curry powder", "madras curry", "tikka masala",
            "tandoori masala", "chaat masala", "panch phoron", "panch phoran",
            "sambar powder", "rasam powder", "chole masala", "biryani masala",
            // Spice Blends - Middle Eastern
            "za'atar", "zaatar", "ras el hanout", "baharat", "berbere",
            "hawaij", "advieh", "seven spice", "dukkah", "sumac",
            // Spice Blends - Asian
            "chinese five spice", "five spice", "shichimi togarashi", "togarashi",
            "furikake", "nanami togarashi", "sansho pepper",
            // Spice Blends - Caribbean & Latin
            "jerk seasoning", "adobo", "sazon", "sofrito", "recaito", "achiote",
            "annatto",
            // Spice Blends - American
            "cajun seasoning", "creole seasoning", "old bay", "poultry seasoning",
            "pumpkin spice", "apple pie spice", "italian seasoning", "herbs de provence",
            "herbes de provence", "fines herbes", "bouquet garni",
            // Salts & Peppers
            "salt", "table salt", "sea salt", "kosher salt", "coarse salt",
            "fleur de sel", "himalayan salt", "pink salt", "black salt", "kala namak",
            "smoked salt", "celery salt", "garlic salt", "onion salt", "seasoned salt",
            "pepper", "black pepper", "white pepper", "red pepper flake", "chile flake",
            "crushed red pepper", "aleppo pepper", "marash pepper", "urfa pepper",
            // Others
            "msg", "monosodium glutamate", "yeast extract", "marmite", "vegemite",
            "chicken bouillon", "beef bouillon", "vegetable bouillon"
        ],
        
        // MARK: Oils & Fats
        "Oils & Fats": [
            // Olive Oil
            "olive oil", "extra virgin olive oil", "evoo", "virgin olive oil",
            "light olive oil", "pomace oil",
            // Vegetable Oils
            "vegetable oil", "canola oil", "rapeseed oil", "sunflower oil",
            "safflower oil", "corn oil", "soybean oil", "cottonseed oil",
            "grapeseed oil", "rice bran oil",
            // Nut & Seed Oils
            "peanut oil", "groundnut oil", "sesame oil", "toasted sesame oil",
            "walnut oil", "hazelnut oil", "almond oil", "pistachio oil",
            "pumpkin seed oil", "flaxseed oil", "linseed oil", "hemp oil",
            // Specialty Oils
            "coconut oil", "virgin coconut oil", "palm oil", "red palm oil",
            "avocado oil", "truffle oil", "white truffle oil", "black truffle oil",
            "chili oil", "chile oil", "sichuan chili oil", "infused oil",
            // Animal Fats
            "lard", "pork fat", "duck fat", "goose fat", "chicken fat", "schmaltz",
            "beef fat", "tallow", "suet", "bone marrow",
            // Other Fats
            "shortening", "vegetable shortening", "butter", "ghee", "margarine",
            "spray oil", "cooking spray"
        ],
        
        // MARK: Sauces & Condiments
        "Sauces & Condiments": [
            // Soy Sauce & Fermented
            "soy sauce", "light soy sauce", "dark soy sauce", "tamari", "shoyu",
            "kecap manis", "kecap asin", "coconut aminos", "liquid aminos",
            "fish sauce", "nam pla", "nuoc mam", "patis", "anchovy sauce",
            "oyster sauce", "hoisin sauce", "plum sauce", "black bean sauce",
            "fermented black bean", "doubanjiang", "gochujang", "doenjang",
            "miso", "white miso", "red miso", "yellow miso", "miso paste",
            // Asian Sauces
            "teriyaki", "teriyaki sauce", "ponzu", "ponzu sauce", "tonkatsu sauce",
            "okonomiyaki sauce", "takoyaki sauce", "yakisoba sauce", "bulgogi sauce",
            "sambal", "sambal oelek", "sambal matah", "sambal terasi",
            "sriracha", "sweet chili sauce", "chili garlic sauce", "xo sauce",
            "pad thai sauce", "peanut sauce", "satay sauce", "nuoc cham",
            // Western Condiments
            "ketchup", "tomato ketchup", "catsup", "mustard", "yellow mustard",
            "dijon mustard", "whole grain mustard", "stone ground mustard",
            "honey mustard", "spicy brown mustard", "english mustard",
            "mayo", "mayonnaise", "aioli", "garlic aioli", "chipotle mayo",
            "worcestershire", "worcestershire sauce", "hp sauce", "a1 sauce",
            "steak sauce", "bbq sauce", "barbecue sauce", "hot sauce", "tabasco",
            "louisiana hot sauce", "frank's redhot", "cholula", "tapatio",
            "valentina", "buffalo sauce",
            // European Sauces
            "pesto", "basil pesto", "sun-dried tomato pesto", "red pesto",
            "tapenade", "olive tapenade", "sun-dried tomato tapenade",
            "marinara", "tomato sauce", "pasta sauce", "arrabbiata", "puttanesca",
            "alfredo", "carbonara sauce", "bolognese", "ragù",
            // Mediterranean & Middle Eastern
            "tahini", "tahini sauce", "hummus", "baba ganoush", "tzatziki",
            "harissa", "harissa paste", "amba", "schug", "zhug", "toum",
            "pomegranate molasses", "date molasses", "tamarind", "tamarind paste",
            "tamarind concentrate", "mango chutney", "mint chutney",
            // Indian Subcontinent
            "curry paste", "green curry paste", "red curry paste", "yellow curry paste",
            "massaman curry paste", "tikka masala sauce", "korma sauce", "vindaloo sauce",
            "chutney", "tamarind chutney", "cilantro chutney", "coconut chutney",
            "pickle", "achar", "lime pickle", "mango pickle", "mixed pickle",
            "raita", "mint raita", "cucumber raita",
            // Vinegars
            "vinegar", "white vinegar", "distilled vinegar", "red wine vinegar",
            "white wine vinegar", "champagne vinegar", "sherry vinegar",
            "balsamic vinegar", "balsamic glaze", "modena balsamic",
            "rice vinegar", "rice wine vinegar", "black vinegar", "chinkiang vinegar",
            "apple cider vinegar", "cider vinegar", "malt vinegar", "coconut vinegar",
            // Pastes & Concentrates
            "tomato paste", "tomato puree", "tomato concentrate", "sun-dried tomato",
            "curry paste", "thai curry paste", "ginger paste", "garlic paste",
            "ginger-garlic paste", "green chili paste", "red chili paste",
            "chili paste", "harissa paste", "chipotle paste", "adobo sauce",
            "sofrito", "recaito", "mirepoix", "holy trinity",
            // Stocks & Broths
            "stock", "broth", "chicken stock", "chicken broth", "beef stock",
            "beef broth", "vegetable stock", "vegetable broth", "fish stock",
            "fish broth", "mushroom broth", "bone broth", "dashi", "kombu dashi",
            "bonito dashi", "miso soup base", "bouillon", "bouillon cube",
            "better than bouillon", "consommé",
            // Salad Dressings
            "ranch", "ranch dressing", "blue cheese dressing", "caesar dressing",
            "thousand island", "italian dressing", "french dressing", "balsamic dressing",
            "vinaigrette", "honey mustard dressing", "goddess dressing",
            // Other Condiments
            "relish", "pickle relish", "chow chow", "piccalilli", "kimchi",
            "sauerkraut", "capers", "caper brine", "cornichon", "pickled ginger",
            "pickled jalapeño", "banana pepper", "pepperoncini", "pickled onion",
            "preserved lemon", "anchovy paste", "horseradish", "prepared horseradish",
            "wasabi", "wasabi paste", "yuzu kosho"
        ],
        
        // MARK: Sweeteners
        "Sweeteners": [
            // Sugars
            "sugar", "white sugar", "granulated sugar", "cane sugar", "beet sugar",
            "brown sugar", "light brown sugar", "dark brown sugar", "raw sugar",
            "turbinado", "demerara", "muscovado", "piloncillo", "panela",
            "jaggery", "gur", "palm sugar", "coconut sugar", "date sugar",
            "confectioners sugar", "powdered sugar", "icing sugar", "pearl sugar",
            "sanding sugar", "coarse sugar", "vanilla sugar",
            // Liquid Sweeteners
            "honey", "raw honey", "manuka honey", "wildflower honey", "clover honey",
            "maple syrup", "pure maple syrup", "grade a maple syrup", "grade b maple syrup",
            "agave", "agave nectar", "agave syrup", "blue agave",
            "corn syrup", "light corn syrup", "dark corn syrup", "high fructose corn syrup",
            "golden syrup", "treacle", "black treacle", "molasses", "blackstrap molasses",
            "sorghum", "sorghum syrup", "date syrup", "pomegranate molasses",
            "brown rice syrup", "barley malt syrup", "yacon syrup",
            // Alternative Sweeteners
            "stevia", "monk fruit", "erythritol", "xylitol", "allulose",
            "sucralose", "aspartame", "saccharin", "sweet'n low", "splenda", "equal"
        ]
    ]
    
    // Additional comprehensive keyword lists would continue here...
    // This gives you the structure for a world-class categorization system
}
