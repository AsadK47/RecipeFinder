import Testing
import UIKit
@testable import RecipeFinder

/// Placeholder art for recipes without a photo: dish words in the name win, then the category; cuisine picks the colours.
@Suite("RecipePlaceholderArt")
struct RecipePlaceholderArtTests {

    @Test("Category picks the art when the name has no dish words", arguments: [
        ("Breakfast", RecipePlaceholderArt.Motif.breakfast),
        ("Starter", .snack),
        ("Snack", .snack),
        ("Main", .main),
        ("Side", .veg),
        ("Soup", .soup),
        ("Dessert", .sweet),
        ("Drink", .coldDrink),
    ])
    func categoryPicksArt(category: String, motif: RecipePlaceholderArt.Motif) {
        #expect(RecipePlaceholderArt.motif(name: "Grandma's Favourite", category: category) == motif)
    }

    @Test("Dish words in the name win over the category", arguments: [
        ("Chocolate Chip Cookies", "Main", RecipePlaceholderArt.Motif.sweet),
        ("Lemon Drizzle Cake", "Main", .sweet),
        ("Chicken Noodle Soup", "Main", .soup),
        ("Butter Chicken Curry", "Main", .curry),
        ("Vegetable Chow Mein", "Main", .wok),
        ("Egg Fried Rice", "Side", .wok),
        ("Steamed Bao Buns", "Main", .baked),
        ("Garden Salad", "Main", .veg),
        ("Baked Cod", "Main", .fish),
        ("Crispy Chicken Wings", "Starter", .poultry),
        ("Lamb Kebab", "Main", .meat),
        ("Fluffy Pancakes", "Main", .breakfast),
        ("Masala Chips", "Side", .snack),
        ("Shami Kebab", "Main", .main),
    ])
    func nameBeatsCategory(name: String, category: String, motif: RecipePlaceholderArt.Motif) {
        #expect(RecipePlaceholderArt.motif(name: name, category: category) == motif)
    }

    @Test("Pancakes are breakfast, not cake (whole words only)")
    func pancakesAreNotCake() {
        #expect(RecipePlaceholderArt.motif(name: "Pancakes", category: "") == .breakfast)
        #expect(RecipePlaceholderArt.motif(name: "Cupcakes", category: "") == .sweet)
    }

    @Test("Matching ignores case and punctuation")
    func ignoresCaseAndPunctuation() {
        #expect(RecipePlaceholderArt.motif(name: "SPICY-CURRY!", category: "") == .curry)
    }

    @Test("A Drink stays a drink even with food words; hot words make it hot unless it's iced", arguments: [
        ("Chocolate Milkshake", RecipePlaceholderArt.Motif.coldDrink),
        ("Matcha Latte", .hotDrink),
        ("Masala Chai", .hotDrink),
        ("Thai Iced Tea", .coldDrink),
    ])
    func drinksStayDrinks(name: String, motif: RecipePlaceholderArt.Motif) {
        #expect(RecipePlaceholderArt.motif(name: name, category: "Drink") == motif)
    }

    @Test("Drink words outside a Drink don't make food look like a cup")
    func drinkWordsNeedDrinkCategory() {
        #expect(RecipePlaceholderArt.motif(name: "Coffee Rubbed Steak", category: "Main") == .meat)
    }

    @Test("A Dessert keeps sweet art whatever it's named after", arguments: [
        "Coffee Cake", "Espresso Chocolate Cookies", "No-Bake Matcha Bars", "Apple Crisp with Oat Topping", "Banana Bread",
    ])
    func dessertsStaySweet(name: String) {
        #expect(RecipePlaceholderArt.motif(name: name, category: "Dessert") == .sweet)
    }

    @Test("Meat-free dishes named after meat don't get meat art")
    func meatFreeSkipsMeat() {
        #expect(RecipePlaceholderArt.motif(name: "Moroccan Jackfruit 'Lamb' Tagine", category: "Main") == .main)
        #expect(RecipePlaceholderArt.motif(name: "Vegan Chicken Nuggets", category: "Main") == .main)
    }

    @Test("Unknown name and category fall back to the general dish art")
    func unknownFallsBack() {
        #expect(RecipePlaceholderArt.motif(name: nil, category: nil) == .main)
        #expect(RecipePlaceholderArt.motif(name: "", category: "Mystery") == .main)
    }

    @Test("Cuisine comes from the cuisine field or a cuisine word in the name", arguments: [
        (nil as String?, "Pakistani Chicken Karahi", RecipePlaceholderArt.Cuisine.southAsian),
        ("Indian", "Dal", .southAsian),
        (nil, "Sri Lankan Coconut Sambol", .southAsian),
        (nil, "Cantonese Steamed Fish", .chinese),
        ("Korean", "Bibimbap", .japaneseKorean),
        (nil, "Thai Green Curry", .southeastAsian),
        ("Italian", "Lasagne", .mediterranean),
        (nil, "Mexican Street Corn", .latin),
    ])
    func cuisineDetected(cuisine: String?, name: String, expected: RecipePlaceholderArt.Cuisine) {
        #expect(RecipePlaceholderArt.cuisine(name: name, cuisine: cuisine) == expected)
    }

    @Test("No cuisine clue means no cuisine")
    func noCuisine() {
        #expect(RecipePlaceholderArt.cuisine(name: "Banana Bread", cuisine: nil) == nil)
        #expect(RecipePlaceholderArt.cuisine(name: "Banana Bread", cuisine: "  ") == nil)
    }

    @Test("Same cuisine shares a palette; different cuisines differ")
    func cuisinePalettes() {
        let a = RecipePlaceholderArt(name: "Pakistani Dal", category: "Main", cuisine: nil)
        let b = RecipePlaceholderArt(name: "Chicken Biryani", category: "Main", cuisine: "Indian")
        let c = RecipePlaceholderArt(name: "Thai Green Curry", category: "Main", cuisine: nil)
        #expect(a.paletteIndex == b.paletteIndex)
        #expect(a.paletteIndex != c.paletteIndex)
    }

    @Test("Without a cuisine the palette is stable per name and in range")
    func hashedPaletteIsStable() {
        let a = RecipePlaceholderArt(name: "Banana Bread", category: "Dessert", cuisine: nil)
        let b = RecipePlaceholderArt(name: "Banana Bread", category: "Dessert", cuisine: nil)
        #expect(a == b)
        // Pinned value: a per-launch hash (String.hashValue) would fail this.
        #expect(a.paletteIndex == 7)
    }

    @Test("Every cuisine palette index is in range")
    func cuisinePaletteInRange() {
        for cuisine in RecipePlaceholderArt.Cuisine.allCases {
            #expect(cuisine.paletteIndex >= 0 && cuisine.paletteIndex < RecipePlaceholderArt.paletteCount)
        }
    }

    // A missing SF Symbol renders as nothing, so every art piece must resolve on the running OS.
    @Test("Every motif's symbols exist", arguments: RecipePlaceholderArt.Motif.allCases)
    func symbolsExist(motif: RecipePlaceholderArt.Motif) {
        for name in [motif.symbol] + motif.accents {
            #expect(UIImage(systemName: name) != nil, "missing SF Symbol \(name)")
        }
    }

    @Test("Each motif has a distinct main symbol so lists don't look samey")
    func motifsLookDifferent() {
        let symbols = RecipePlaceholderArt.Motif.allCases.map(\.symbol)
        #expect(Set(symbols).count == symbols.count)
    }
}
