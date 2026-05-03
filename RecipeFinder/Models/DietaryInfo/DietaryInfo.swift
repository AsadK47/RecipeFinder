
import Foundation

enum DietaryTag: String, Codable, CaseIterable {
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case pescatarian = "Pescatarian"
    case keto = "Keto"
    case paleo = "Paleo"
    case lowCarb = "Low Carb"
    case highProtein = "High Protein"
    case whole30 = "Whole30"
    
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"
    case nutFree = "Nut-Free"
    case eggFree = "Egg-Free"
    case soyFree = "Soy-Free"
    case shellfishFree = "Shellfish-Free"
    case fishFree = "Fish-Free"
    
    case lowCalorie = "Low Calorie"
    case lowSodium = "Low Sodium"
    case lowSugar = "Low Sugar"
    case highFiber = "High Fiber"
    case organic = "Organic"
    case raw = "Raw"
    
    var icon: String {
        switch self {
        case .vegetarian: return "🥬"
        case .vegan: return "🌱"
        case .pescatarian: return "🐟"
        case .keto: return "🥑"
        case .paleo: return "🥩"
        case .lowCarb: return "📉"
        case .highProtein: return "💪"
        case .whole30: return "✓"
        case .glutenFree: return "🌾"
        case .dairyFree: return "🥛"
        case .nutFree: return "🥜"
        case .eggFree: return "🥚"
        case .soyFree: return "🌿"
        case .shellfishFree: return "🦐"
        case .fishFree: return "🐠"
        case .lowCalorie: return "⚡️"
        case .lowSodium: return "🧂"
        case .lowSugar: return "🍬"
        case .highFiber: return "🌾"
        case .organic: return "🌿"
        case .raw: return "🥗"
        }
    }
    
    var color: String {
        switch self {
        case .vegetarian, .vegan, .pescatarian: return "green"
        case .keto, .paleo, .lowCarb: return "orange"
        case .glutenFree, .dairyFree, .nutFree, .eggFree, .soyFree, .shellfishFree, .fishFree: return "red"
        case .highProtein, .lowCalorie, .lowSodium, .lowSugar: return "blue"
        case .highFiber, .organic, .raw, .whole30: return "purple"
        }
    }
}

struct SnackItem: Identifiable, Codable, Hashable {
    let id: UUID
    let emoji: String
    let name: String
    let dietaryTags: [DietaryTag]
    let calories: Int?
    let category: SnackCategory
    
    init(
        id: UUID = UUID(),
        emoji: String,
        name: String,
        dietaryTags: [DietaryTag] = [],
        calories: Int? = nil,
        category: SnackCategory
    ) {
        self.id = id
        self.emoji = emoji
        self.name = name
        self.dietaryTags = dietaryTags
        self.calories = calories
        self.category = category
    }
    
    var displayName: String {
        "\(emoji) \(name)"
    }
    
    func matches(dietaryFilters: Set<DietaryTag>) -> Bool {
        guard !dietaryFilters.isEmpty else { return true }
        return dietaryFilters.allSatisfy { dietaryTags.contains($0) }
    }
}

enum SnackCategory: String, Codable, CaseIterable {
    case fruit = "Fruit"
    case vegetables = "Vegetables"
    case nuts = "Nuts & Seeds"
    case dairy = "Dairy"
    case grains = "Grains & Crackers"
    case protein = "Protein"
    case sweets = "Sweets"
    case beverages = "Beverages"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .fruit: return "🍎"
        case .vegetables: return "🥕"
        case .nuts: return "🥜"
        case .dairy: return "🧀"
        case .grains: return "🍞"
        case .protein: return "🥚"
        case .sweets: return "🍪"
        case .beverages: return "🥤"
        case .other: return "🍽️"
        }
    }
}

struct SnackDatabase {
    static let allSnacks: [SnackItem] = [
        SnackItem(emoji: "🍎", name: "Apple", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCalorie, .highFiber], calories: 95, category: .fruit),
        SnackItem(emoji: "🍌", name: "Banana", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .highFiber], calories: 105, category: .fruit),
        SnackItem(emoji: "🍊", name: "Orange", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCalorie], calories: 62, category: .fruit),
        SnackItem(emoji: "🍇", name: "Grapes", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCalorie], calories: 62, category: .fruit),
        SnackItem(emoji: "🍓", name: "Strawberries", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCalorie, .lowSugar], calories: 49, category: .fruit),
        SnackItem(emoji: "🫐", name: "Blueberries", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCalorie, .highFiber], calories: 84, category: .fruit),
        SnackItem(emoji: "🍑", name: "Peach", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCalorie], calories: 58, category: .fruit),
        SnackItem(emoji: "🥝", name: "Kiwi", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCalorie], calories: 42, category: .fruit),
        SnackItem(emoji: "🍉", name: "Watermelon", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCalorie, .lowSugar], calories: 46, category: .fruit),
        
        SnackItem(emoji: "🥕", name: "Carrots", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCalorie, .highFiber], calories: 25, category: .vegetables),
        SnackItem(emoji: "🥒", name: "Cucumber", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCalorie, .lowCarb, .keto], calories: 16, category: .vegetables),
        SnackItem(emoji: "🫑", name: "Bell Peppers", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCalorie, .lowCarb], calories: 24, category: .vegetables),
        SnackItem(emoji: "🥦", name: "Broccoli", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCalorie, .highFiber], calories: 31, category: .vegetables),
        SnackItem(emoji: "🍅", name: "Cherry Tomatoes", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCalorie, .lowCarb], calories: 27, category: .vegetables),
        SnackItem(emoji: "🥬", name: "Celery", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCalorie, .lowCarb, .keto], calories: 14, category: .vegetables),
        
        SnackItem(emoji: "🥜", name: "Peanuts", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .highProtein, .highFiber], calories: 161, category: .nuts),
        SnackItem(emoji: "🌰", name: "Almonds", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .keto, .paleo, .highProtein, .highFiber], calories: 164, category: .nuts),
        SnackItem(emoji: "🥜", name: "Cashews", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .highProtein], calories: 157, category: .nuts),
        SnackItem(emoji: "🌻", name: "Sunflower Seeds", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .highProtein], calories: 165, category: .nuts),
        SnackItem(emoji: "🥜", name: "Trail Mix", dietaryTags: [.vegetarian, .glutenFree, .highProtein, .highFiber], calories: 131, category: .nuts),
        
        SnackItem(emoji: "🧀", name: "Cheese", dietaryTags: [.vegetarian, .glutenFree, .nutFree, .lowCarb, .keto, .highProtein], calories: 114, category: .dairy),
        SnackItem(emoji: "🥛", name: "Yogurt", dietaryTags: [.vegetarian, .glutenFree, .nutFree, .highProtein], calories: 100, category: .dairy),
        SnackItem(emoji: "🧀", name: "String Cheese", dietaryTags: [.vegetarian, .glutenFree, .nutFree, .lowCarb, .highProtein], calories: 80, category: .dairy),
        
        SnackItem(emoji: "🍿", name: "Popcorn", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCalorie, .highFiber], calories: 31, category: .grains),
        SnackItem(emoji: "🥨", name: "Pretzel", dietaryTags: [.vegan, .vegetarian, .dairyFree, .nutFree, .lowCalorie], calories: 108, category: .grains),
        SnackItem(emoji: "🍞", name: "Rice Cakes", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCalorie], calories: 35, category: .grains),
        SnackItem(emoji: "🍘", name: "Crackers", dietaryTags: [.vegetarian, .dairyFree], calories: 122, category: .grains),
        SnackItem(emoji: "🍪", name: "Granola Bar", dietaryTags: [.vegetarian, .highFiber], calories: 100, category: .grains),
        SnackItem(emoji: "🥐", name: "Crisps", dietaryTags: [.vegan, .vegetarian, .dairyFree], calories: 152, category: .grains),
        
        SnackItem(emoji: "🥚", name: "Hard Boiled Egg", dietaryTags: [.vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCarb, .keto, .paleo, .highProtein], calories: 78, category: .protein),
        SnackItem(emoji: "🍗", name: "Chicken Strips", dietaryTags: [.glutenFree, .dairyFree, .nutFree, .lowCarb, .highProtein, .paleo], calories: 150, category: .protein),
        SnackItem(emoji: "🥓", name: "Beef Jerky", dietaryTags: [.glutenFree, .dairyFree, .nutFree, .lowCarb, .keto, .paleo, .highProtein], calories: 116, category: .protein),
        SnackItem(emoji: "🦃", name: "Turkey Slices", dietaryTags: [.glutenFree, .dairyFree, .nutFree, .lowCarb, .highProtein], calories: 29, category: .protein),
        
        SnackItem(emoji: "🍪", name: "Cookie", dietaryTags: [.vegetarian], calories: 142, category: .sweets),
        SnackItem(emoji: "🍫", name: "Dark Chocolate", dietaryTags: [.vegetarian, .glutenFree, .nutFree], calories: 155, category: .sweets),
        SnackItem(emoji: "🍩", name: "Donut", dietaryTags: [.vegetarian], calories: 269, category: .sweets),
        SnackItem(emoji: "🧁", name: "Muffin", dietaryTags: [.vegetarian], calories: 174, category: .sweets),
        SnackItem(emoji: "🍬", name: "Gummy Bears", dietaryTags: [.glutenFree, .dairyFree, .nutFree, .lowCalorie], calories: 87, category: .sweets),
        
        SnackItem(emoji: "🧃", name: "Juice Box", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree], calories: 100, category: .beverages),
        SnackItem(emoji: "🥤", name: "Smoothie", dietaryTags: [.vegetarian, .glutenFree, .nutFree, .highFiber], calories: 150, category: .beverages),
        SnackItem(emoji: "☕️", name: "Coffee", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCalorie], calories: 2, category: .beverages),
        SnackItem(emoji: "🍵", name: "Tea", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .lowCalorie], calories: 2, category: .beverages),
        
        SnackItem(emoji: "🥪", name: "Mini Sandwich", dietaryTags: [.highProtein], calories: 200, category: .other),
        SnackItem(emoji: "🌮", name: "Protein Bar", dietaryTags: [.highProtein, .highFiber], calories: 200, category: .other),
        SnackItem(emoji: "🍱", name: "Edamame", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .highProtein, .highFiber], calories: 189, category: .other),
        SnackItem(emoji: "🥑", name: "Avocado", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .keto, .paleo, .lowCarb, .highFiber], calories: 234, category: .other),
        SnackItem(emoji: "🍿", name: "Hummus & Veggies", dietaryTags: [.vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree, .highFiber, .highProtein], calories: 100, category: .other),
    ]
    
    static func snacks(forCategory category: SnackCategory) -> [SnackItem] {
        allSnacks.filter { $0.category == category }
    }
    
    static func snacks(matching dietaryFilters: Set<DietaryTag>) -> [SnackItem] {
        guard !dietaryFilters.isEmpty else { return allSnacks }
        return allSnacks.filter { $0.matches(dietaryFilters: dietaryFilters) }
    }
    
    static func popularSnacks() -> [SnackItem] {
        return [
            allSnacks.first { $0.name == "Apple" }!,
            allSnacks.first { $0.name == "Banana" }!,
            allSnacks.first { $0.name == "Almonds" }!,
            allSnacks.first { $0.name == "Yogurt" }!,
            allSnacks.first { $0.name == "Popcorn" }!,
            allSnacks.first { $0.name == "String Cheese" }!,
            allSnacks.first { $0.name == "Granola Bar" }!,
            allSnacks.first { $0.name == "Carrots" }!,
        ]
    }
}
