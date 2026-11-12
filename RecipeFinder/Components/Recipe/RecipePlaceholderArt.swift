import Foundation

/// Which illustration a photo-less recipe gets: dish words in the name win, then the category; cuisine picks the colours
/// (else a stable hash of the name, so lists still look varied). Pure so the mapping is unit-tested.
struct RecipePlaceholderArt: Equatable, Sendable {
    let motif: Motif
    let paletteIndex: Int

    /// Number of colour palettes `RecipePlaceholderView` provides.
    static let paletteCount = 8

    enum Motif: String, CaseIterable, Sendable {
        // Order = match priority for food words ("Masala Chips" is a snack, not curry); drink words only count in a Drink.
        case sweet, breakfast, soup, snack, curry, wok, baked, fish, poultry, meat, veg, hotDrink, coldDrink, main

        /// Main SF Symbol, drawn large in the middle.
        var symbol: String {
            switch self {
            case .hotDrink: "cup.and.saucer"
            case .coldDrink: "wineglass"
            case .sweet: "birthday.cake"
            case .breakfast: "sun.horizon"
            case .soup: "humidity"
            case .curry: "flame"
            case .wok: "frying.pan"
            case .baked: "oven"
            case .fish: "fish"
            case .poultry: "bird"
            case .meat: "cooktop"
            case .veg: "carrot"
            case .snack: "popcorn"
            case .main: "fork.knife"
            }
        }

        /// Two small symbols scattered in the corners on larger tiles.
        var accents: [String] {
            switch self {
            case .hotDrink: ["leaf", "sparkles"]
            case .coldDrink: ["drop", "snowflake"]
            case .sweet: ["sparkles", "heart"]
            case .breakfast: ["cup.and.saucer", "sparkles"]
            case .soup: ["flame", "leaf"]
            case .curry: ["leaf", "sparkles"]
            case .wok: ["flame", "sparkles"]
            case .baked: ["sparkles", "flame"]
            case .fish: ["drop", "leaf"]
            case .poultry: ["flame", "leaf"]
            case .meat: ["flame", "fork.knife"]
            case .veg: ["leaf", "drop"]
            case .snack: ["sparkles", "star"]
            case .main: ["flame", "leaf"]
            }
        }

        /// Whole words (singular) that point at this dish.
        fileprivate var keywords: Set<String> {
            switch self {
            case .hotDrink: ["chai", "tea", "coffee", "latte", "cocoa", "espresso", "cappuccino"]
            case .coldDrink: ["smoothie", "lassi", "mocktail", "cocktail", "lemonade", "juice", "milkshake", "frappe", "spritz"]
            case .sweet: ["cake", "cupcake", "mooncake", "cheesecake", "cookie", "brownie", "tiramisu", "mousse", "custard",
                          "pudding", "chocolate", "mochi", "jelly", "tart", "shortbread", "biscuit", "fudge", "sorbet",
                          "muffin", "doughnut", "donut", "macaron", "meringue", "trifle", "crumble", "flapjack", "halwa",
                          "kheer", "sponge"]
            case .breakfast: ["pancake", "waffle", "porridge", "oat", "granola", "omelette", "omelet", "toast", "muesli",
                              "crepe", "frittata", "shakshuka"]
            case .soup: ["soup", "stew", "congee", "broth", "ramen", "pho", "chowder", "bisque", "minestrone", "laksa"]
            case .curry: ["curry", "masala", "korma", "tikka", "karahi", "dal", "dhal", "daal", "achari", "vindaloo",
                          "jalfrezi", "rogan", "gosht", "nihari", "haleem"]
            case .wok: ["stir", "noodle", "mein", "rice", "biryani", "pulao", "pilaf", "risotto", "pasta", "spaghetti",
                        "linguine", "penne", "fettuccine", "udon"]
            case .baked: ["bread", "bun", "bao", "roti", "naan", "chapati", "paratha", "loaf", "focaccia", "mantou",
                          "pizza", "pie", "quiche", "lasagne", "lasagna", "scone", "bagel", "pretzel", "croissant",
                          "bing"]
            case .fish: ["fish", "cod", "salmon", "tuna", "prawn", "shrimp", "seafood", "mackerel", "haddock", "crab",
                         "mussel", "squid", "sardine", "trout", "tilapia", "lobster", "scallop"]
            case .poultry: ["chicken", "wing", "turkey", "duck", "poussin"]
            case .meat: ["beef", "lamb", "pork", "steak", "burger", "meatball", "mince", "keema", "sausage",
                         "bacon", "ham", "mutton", "goat", "brisket", "rib", "meat"]
            case .veg: ["salad", "vegetable", "veg", "veggie", "tofu", "sabzi", "slaw", "coleslaw", "carrot", "broccoli",
                        "cabbage", "cauliflower", "aloo", "potato", "spinach", "mushroom", "aubergine", "eggplant",
                        "courgette", "zucchini"]
            case .snack: ["popcorn", "chip", "crisp", "fries", "nacho", "dip", "hummus", "samosa", "pakora", "bhaji"]
            case .main: []
            }
        }
    }

    enum Cuisine: CaseIterable, Sendable {
        case southAsian, chinese, japaneseKorean, southeastAsian, mediterranean, latin

        var paletteIndex: Int {
            switch self {
            case .southAsian: 5      // saffron → orange
            case .chinese: 2         // orange → red
            case .japaneseKorean: 4  // pink → magenta
            case .southeastAsian: 3  // green → teal
            case .mediterranean: 0   // teal → blue
            case .latin: 1           // purple
            }
        }

        fileprivate var keywords: Set<String> {
            switch self {
            case .southAsian: ["indian", "pakistani", "lankan", "bangladeshi", "nepali", "punjabi", "desi"]
            case .chinese: ["chinese", "cantonese", "sichuan", "szechuan", "taiwanese", "hunan"]
            case .japaneseKorean: ["japanese", "korean"]
            case .southeastAsian: ["thai", "vietnamese", "malaysian", "indonesian", "filipino", "singaporean"]
            case .mediterranean: ["italian", "greek", "turkish", "spanish", "french", "lebanese", "moroccan", "mediterranean"]
            case .latin: ["mexican", "peruvian", "brazilian", "caribbean", "jamaican", "cuban"]
            }
        }
    }

    init(name: String?, category: String?, cuisine: String?) {
        motif = Self.motif(name: name, category: category)
        if let found = Self.cuisine(name: name, cuisine: cuisine) {
            paletteIndex = found.paletteIndex
        } else {
            // Sum Unicode scalars (String.hashValue is randomised per launch) so a recipe keeps its colour.
            let hash = (name ?? "").unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
            paletteIndex = abs(hash % Self.paletteCount)
        }
    }

    private struct Key: Hashable, Sendable { let name: String?, category: String?, cuisine: String? }
    private static let cache = MemoCache<Key, RecipePlaceholderArt>(maxSize: 500)

    /// Memoised: lists rebuild rows often and the name scan is the same every time.
    static func art(name: String?, category: String?, cuisine: String?) -> RecipePlaceholderArt {
        cache.value(for: Key(name: name, category: category, cuisine: cuisine)) {
            RecipePlaceholderArt(name: $0.name, category: $0.category, cuisine: $0.cuisine)
        }
    }

    static func motif(name: String?, category: String?) -> Motif {
        let words = Self.words(in: name)
        let category = (category ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        if category == "drink" {
            if !words.isDisjoint(with: Self.coldWords) { return .coldDrink }
            return words.isDisjoint(with: Motif.hotDrink.keywords) ? .coldDrink : .hotDrink
        }
        // Desserts keep cake art even when named after a drink or bake ("Espresso Cookies", "Apple Crisp with Oat").
        if category == "dessert" { return .sweet }
        let meatFree = !words.isDisjoint(with: Self.meatFreeWords)
        let food = Motif.allCases.filter { $0 != .hotDrink && $0 != .coldDrink }
        if let match = food.first(where: { motif in
            if meatFree, [Motif.meat, .poultry, .fish].contains(motif) { return false }
            return !words.isDisjoint(with: motif.keywords)
        }) {
            return match
        }
        switch category {
        case "breakfast": return .breakfast
        case "starter", "snack": return .snack
        case "side": return .veg
        case "soup": return .soup
        case "dessert": return .sweet
        default: return .main
        }
    }

    private static let coldWords: Set<String> = ["iced", "cold", "boba", "frozen"]
    // "Jackfruit 'Lamb'" or a vegan "chicken" shouldn't get meat art.
    private static let meatFreeWords: Set<String> = ["vegan", "vegetarian", "jackfruit", "meatless", "plant"]

    static func cuisine(name: String?, cuisine: String?) -> Cuisine? {
        let fromField = Self.words(in: cuisine)
        if let match = Cuisine.allCases.first(where: { !fromField.isDisjoint(with: $0.keywords) }) { return match }
        let fromName = Self.words(in: name)
        return Cuisine.allCases.first(where: { !fromName.isDisjoint(with: $0.keywords) })
    }

    /// Lower-cased whole words plus their singular guesses ("buns" → "bun", "potatoes" → "potato").
    private static func words(in text: String?) -> Set<String> {
        guard let text, !text.isEmpty else { return [] }
        var result = Set<String>()
        for word in text.lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init) {
            result.insert(word)
            if word.hasSuffix("es") { result.insert(String(word.dropLast(2))) }
            if word.hasSuffix("s") { result.insert(String(word.dropLast())) }
        }
        return result
    }
}
