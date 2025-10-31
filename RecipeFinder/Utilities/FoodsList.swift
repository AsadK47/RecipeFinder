import Foundation

struct FoodsList {
    
    // MARK: - Food Categories
    static let categories = [
        "Fruits",
        "Vegetables",
        "Dairy & Eggs",
        "Meat & Poultry",
        "Seafood",
        "Grains & Bread",
        "Legumes & Beans",
        "Nuts & Seeds",
        "Oils & Fats",
        "Herbs & Spices",
        "Condiments & Sauces",
        "Beverages",
        "Baking",
        "Frozen Foods",
        "Canned Goods"
    ]
    
    // MARK: - Food Database
    static let foodsByCategory: [String: [String]] = [
        "Fruits": [
            "Apple", "Banana", "Orange", "Strawberry", "Blueberry", "Raspberry",
            "Blackberry", "Mango", "Pineapple", "Watermelon", "Cantaloupe",
            "Honeydew Melon", "Grapes", "Peach", "Pear", "Plum", "Cherry",
            "Apricot", "Kiwi", "Papaya", "Guava", "Dragon Fruit", "Lychee",
            "Passion Fruit", "Pomegranate", "Fig", "Date", "Cranberry",
            "Grapefruit", "Lemon", "Lime", "Tangerine", "Clementine",
            "Blood Orange", "Nectarine", "Persimmon", "Starfruit"
        ],
        
        "Vegetables": [
            "Tomato", "Cucumber", "Lettuce", "Spinach", "Kale", "Arugula",
            "Cabbage", "Broccoli", "Cauliflower", "Carrot", "Celery", "Bell Pepper",
            "Jalapeño", "Serrano Pepper", "Habanero", "Poblano Pepper",
            "Onion", "Red Onion", "Green Onion", "Shallot", "Leek", "Garlic",
            "Ginger", "Potato", "Sweet Potato", "Yam", "Eggplant", "Zucchini",
            "Yellow Squash", "Butternut Squash", "Acorn Squash", "Pumpkin",
            "Asparagus", "Green Beans", "Snap Peas", "Snow Peas", "Corn",
            "Brussels Sprouts", "Beet", "Radish", "Turnip", "Parsnip",
            "Mushroom", "Shiitake Mushroom", "Portobello Mushroom",
            "Button Mushroom", "Oyster Mushroom", "Bok Choy", "Napa Cabbage",
            "Swiss Chard", "Collard Greens", "Mustard Greens", "Artichoke",
            "Fennel", "Okra", "Jicama", "Kohlrabi", "Rutabaga"
        ],
        
        "Dairy & Eggs": [
            "Milk", "Whole Milk", "2% Milk", "Skim Milk", "Almond Milk",
            "Oat Milk", "Soy Milk", "Coconut Milk", "Heavy Cream",
            "Light Cream", "Half and Half", "Sour Cream", "Cream Cheese",
            "Butter", "Unsalted Butter", "Salted Butter", "Ghee",
            "Cheddar Cheese", "Mozzarella Cheese", "Parmesan Cheese",
            "Swiss Cheese", "Gouda Cheese", "Brie Cheese", "Feta Cheese",
            "Ricotta Cheese", "Cottage Cheese", "Blue Cheese", "Provolone Cheese",
            "Monterey Jack", "Pepper Jack", "Colby Cheese", "Gruyere Cheese",
            "Manchego Cheese", "Pecorino Romano", "Mascarpone", "Greek Yogurt",
            "Plain Yogurt", "Vanilla Yogurt", "Eggs", "Egg Whites", "Egg Yolks",
            "Quail Eggs"
        ],
        
        "Meat & Poultry": [
            // Chicken
            "Chicken Breast", "Boneless Chicken Breast", "Chicken Breast with Skin",
            "Chicken Thigh", "Boneless Chicken Thigh", "Chicken Thigh with Skin",
            "Chicken Wings", "Chicken Drumsticks", "Chicken Legs",
            "Whole Chicken", "Ground Chicken", "Chicken Tenders",
            // Turkey
            "Turkey Breast", "Ground Turkey", "Whole Turkey", "Turkey Legs",
            "Turkey Thigh", "Turkey Wings", "Turkey Tenderloin",
            // Other Poultry
            "Duck", "Duck Breast", "Duck Legs", "Whole Duck",
            "Quail", "Cornish Hen", "Goose", "Pheasant",
            // Beef - Steaks
            "Beef Steak", "Ribeye Steak", "Sirloin Steak", "T-Bone Steak",
            "Porterhouse Steak", "Filet Mignon", "New York Strip", "Flank Steak",
            "Skirt Steak", "Hanger Steak", "Flat Iron Steak", "Tri-Tip Steak",
            // Beef - Roasts & Cuts
            "Chuck Roast", "Brisket", "Beef Short Ribs", "Beef Tenderloin",
            "Prime Rib", "Top Sirloin Roast", "Bottom Round Roast", "Eye of Round",
            "Beef Shank", "Oxtail", "Beef Ribs", "Back Ribs",
            // Beef - Ground & Processed
            "Ground Beef", "Lean Ground Beef", "Ground Chuck", "Ground Sirloin",
            "Beef Patties", "Beef Meatballs",
            // Pork
            "Pork Chop", "Bone-In Pork Chop", "Boneless Pork Chop",
            "Pork Tenderloin", "Pork Loin", "Pork Shoulder", "Pork Butt",
            "Pork Belly", "Ground Pork", "Pork Ribs", "Baby Back Ribs",
            "Spare Ribs", "Country Style Ribs", "Pork Hock", "Pork Shank",
            // Pork - Cured & Processed
            "Ham", "Prosciutto", "Bacon", "Pancetta", "Canadian Bacon",
            "Pork Sausage", "Italian Sausage", "Chorizo", "Bratwurst",
            "Andouille Sausage", "Kielbasa", "Hot Dogs", "Salami", "Pepperoni",
            "Mortadella", "Coppa", "Soppressata",
            // Lamb
            "Lamb Chop", "Lamb Loin Chop", "Lamb Shoulder Chop",
            "Leg of Lamb", "Lamb Shank", "Lamb Shoulder", "Rack of Lamb",
            "Ground Lamb", "Lamb Ribs", "Lamb Stew Meat",
            // Veal
            "Veal Cutlet", "Veal Chop", "Veal Shank", "Veal Scallopini",
            "Ground Veal", "Veal Osso Buco",
            // Game & Specialty
            "Venison", "Venison Steak", "Ground Venison",
            "Bison", "Bison Steak", "Ground Bison",
            "Elk", "Wild Boar", "Rabbit",
            // Organ Meats
            "Beef Liver", "Chicken Liver", "Beef Heart", "Beef Tongue",
            "Beef Kidney", "Sweetbreads", "Tripe"
        ],
        
        "Seafood": [
            "Salmon", "Atlantic Salmon", "Sockeye Salmon", "Coho Salmon",
            "Tuna", "Yellowfin Tuna", "Albacore Tuna", "Bluefin Tuna",
            "Cod", "Halibut", "Sea Bass", "Snapper", "Mahi Mahi", "Swordfish",
            "Tilapia", "Catfish", "Trout", "Rainbow Trout", "Mackerel",
            "Sardines", "Anchovies", "Haddock", "Flounder", "Sole",
            "Shrimp", "Prawns", "Lobster", "Crab", "Snow Crab", "King Crab",
            "Dungeness Crab", "Scallops", "Clams", "Mussels", "Oysters",
            "Squid", "Calamari", "Octopus", "Cuttlefish"
        ],
        
        "Grains & Bread": [
            "White Rice", "Brown Rice", "Jasmine Rice", "Basmati Rice",
            "Arborio Rice", "Wild Rice", "Black Rice", "Quinoa", "Couscous",
            "Bulgur Wheat", "Farro", "Barley", "Pearl Barley", "Oats",
            "Rolled Oats", "Steel Cut Oats", "Cornmeal", "Polenta", "Grits",
            "White Bread", "Whole Wheat Bread", "Sourdough Bread", "Rye Bread",
            "Pumpernickel Bread", "Ciabatta", "Focaccia", "Baguette",
            "Pita Bread", "Naan", "Tortilla", "Corn Tortilla", "Flour Tortilla",
            "English Muffin", "Bagel", "Croissant", "Brioche", "Challah",
            "Pasta", "Spaghetti", "Penne", "Fettuccine", "Linguine",
            "Rigatoni", "Farfalle", "Fusilli", "Lasagna Noodles",
            "Macaroni", "Orzo", "Angel Hair Pasta", "Egg Noodles",
            "Rice Noodles", "Udon Noodles", "Soba Noodles", "Ramen Noodles"
        ],
        
        "Legumes & Beans": [
            "Black Beans", "Pinto Beans", "Kidney Beans", "Navy Beans",
            "Great Northern Beans", "Cannellini Beans", "Lima Beans",
            "Chickpeas", "Garbanzo Beans", "Lentils", "Red Lentils",
            "Green Lentils", "Black Lentils", "Yellow Split Peas", "Green Split Peas",
            "Black-Eyed Peas", "Mung Beans", "Adzuki Beans", "Fava Beans",
            "Soybeans", "Edamame", "Tofu", "Firm Tofu", "Silken Tofu",
            "Extra Firm Tofu", "Tempeh"
        ],
        
        "Nuts & Seeds": [
            "Almonds", "Sliced Almonds", "Almond Flour", "Cashews", "Walnuts",
            "Pecans", "Pistachios", "Macadamia Nuts", "Hazelnuts", "Pine Nuts",
            "Brazil Nuts", "Peanuts", "Peanut Butter", "Almond Butter",
            "Cashew Butter", "Sunflower Seeds", "Pumpkin Seeds", "Pepitas",
            "Sesame Seeds", "Chia Seeds", "Flax Seeds", "Hemp Seeds",
            "Poppy Seeds", "Tahini"
        ],
        
        "Oils & Fats": [
            "Olive Oil", "Extra Virgin Olive Oil", "Vegetable Oil", "Canola Oil",
            "Avocado Oil", "Coconut Oil", "Sesame Oil", "Peanut Oil",
            "Sunflower Oil", "Grapeseed Oil", "Walnut Oil", "Truffle Oil",
            "Butter", "Ghee", "Lard", "Shortening", "Cooking Spray"
        ],
        
        "Herbs & Spices": [
            "Basil", "Oregano", "Thyme", "Rosemary", "Sage", "Parsley",
            "Cilantro", "Dill", "Mint", "Tarragon", "Bay Leaf", "Chives",
            "Black Pepper", "White Pepper", "Cayenne Pepper", "Paprika",
            "Smoked Paprika", "Cumin", "Coriander", "Turmeric", "Cinnamon",
            "Nutmeg", "Cloves", "Cardamom", "Star Anise", "Fennel Seeds",
            "Mustard Seeds", "Celery Seeds", "Caraway Seeds", "Salt",
            "Sea Salt", "Kosher Salt", "Himalayan Pink Salt", "Garlic Powder",
            "Onion Powder", "Ginger Powder", "Chili Powder", "Curry Powder",
            "Garam Masala", "Chinese Five Spice", "Italian Seasoning",
            "Herbs de Provence", "Za'atar", "Sumac", "Vanilla Extract",
            "Almond Extract", "Peppermint Extract"
        ],
        
        "Condiments & Sauces": [
            "Ketchup", "Mustard", "Dijon Mustard", "Whole Grain Mustard",
            "Mayonnaise", "Soy Sauce", "Tamari", "Worcestershire Sauce",
            "Hot Sauce", "Sriracha", "Tabasco", "BBQ Sauce", "Teriyaki Sauce",
            "Hoisin Sauce", "Fish Sauce", "Oyster Sauce", "Chili Garlic Sauce",
            "Sambal Oelek", "Gochujang", "Miso Paste", "White Miso", "Red Miso",
            "Tahini", "Harissa", "Pesto", "Marinara Sauce", "Alfredo Sauce",
            "Tomato Sauce", "Tomato Paste", "Salsa", "Pico de Gallo",
            "Guacamole", "Hummus", "Ranch Dressing", "Italian Dressing",
            "Caesar Dressing", "Balsamic Vinaigrette", "Vinegar",
            "Balsamic Vinegar", "Red Wine Vinegar", "White Wine Vinegar",
            "Apple Cider Vinegar", "Rice Vinegar"
        ],
        
        "Beverages": [
            "Water", "Sparkling Water", "Coffee", "Ground Coffee", "Coffee Beans",
            "Espresso", "Tea", "Black Tea", "Green Tea", "Herbal Tea",
            "Chamomile Tea", "Peppermint Tea", "Orange Juice", "Apple Juice",
            "Cranberry Juice", "Grapefruit Juice", "Tomato Juice", "V8 Juice",
            "Lemonade", "Iced Tea", "Coconut Water", "Vegetable Broth",
            "Chicken Broth", "Beef Broth", "Bone Broth", "Wine", "Red Wine",
            "White Wine", "Beer", "Sake", "Rum", "Vodka", "Whiskey", "Bourbon",
            "Gin", "Tequila", "Cognac", "Brandy"
        ],
        
        "Baking": [
            "All-Purpose Flour", "Bread Flour", "Cake Flour", "Whole Wheat Flour",
            "Almond Flour", "Coconut Flour", "Oat Flour", "White Sugar",
            "Brown Sugar", "Light Brown Sugar", "Dark Brown Sugar",
            "Powdered Sugar", "Confectioners Sugar", "Granulated Sugar",
            "Raw Sugar", "Turbinado Sugar", "Honey", "Maple Syrup",
            "Agave Nectar", "Molasses", "Blackstrap Molasses", "Corn Syrup",
            "Baking Powder", "Baking Soda", "Yeast", "Active Dry Yeast",
            "Instant Yeast", "Cornstarch", "Arrowroot Powder", "Tapioca Starch",
            "Cocoa Powder", "Dutch Process Cocoa", "Chocolate Chips",
            "Semi-Sweet Chocolate Chips", "Dark Chocolate Chips",
            "White Chocolate Chips", "Baking Chocolate", "Unsweetened Chocolate",
            "Vanilla Beans", "Gelatin", "Agar Agar", "Cream of Tartar"
        ],
        
        "Frozen Foods": [
            "Frozen Peas", "Frozen Corn", "Frozen Carrots", "Frozen Broccoli",
            "Frozen Cauliflower", "Frozen Green Beans", "Frozen Spinach",
            "Frozen Mixed Vegetables", "Frozen Berries", "Frozen Strawberries",
            "Frozen Blueberries", "Frozen Mango", "Frozen Pineapple",
            "Frozen Edamame", "Frozen Shrimp", "Frozen Fish Fillets",
            "Frozen Chicken Breasts", "Frozen Ground Beef", "Ice Cream",
            "Sorbet", "Frozen Yogurt", "Popsicles"
        ],
        
        "Canned Goods": [
            "Canned Tomatoes", "Crushed Tomatoes", "Diced Tomatoes",
            "Whole Peeled Tomatoes", "Tomato Sauce", "Tomato Paste",
            "Canned Black Beans", "Canned Pinto Beans", "Canned Kidney Beans",
            "Canned Chickpeas", "Canned Cannellini Beans", "Canned Corn",
            "Canned Green Beans", "Canned Peas", "Canned Carrots",
            "Canned Pumpkin", "Pumpkin Puree", "Canned Coconut Milk",
            "Coconut Cream", "Evaporated Milk", "Sweetened Condensed Milk",
            "Canned Tuna", "Canned Salmon", "Canned Sardines", "Canned Anchovies",
            "Canned Clams", "Canned Crab", "Canned Chicken", "Canned Beef",
            "Canned Soup", "Chicken Noodle Soup", "Tomato Soup", "Cream of Mushroom"
        ]
    ]
    
    // MARK: - Helper Functions
    static func getAllFoods() -> [String] {
        return foodsByCategory.values.flatMap { $0 }.sorted()
    }
    
    static func searchFoods(query: String) -> [String] {
        guard !query.isEmpty else { return [] }
        return getAllFoods().filter { $0.localizedCaseInsensitiveContains(query) }
    }
    
    static func getFoods(forCategory category: String) -> [String] {
        return foodsByCategory[category] ?? []
    }
    
    static func getCategoryForFood(_ food: String) -> String? {
        for (category, foods) in foodsByCategory {
            if foods.contains(where: { $0.localizedCaseInsensitiveCompare(food) == .orderedSame }) {
                return category
            }
        }
        return nil
    }
}
