import Foundation

/// One home for folding an English plural to its singular, so every matcher agrees that "Blueberries" is "blueberry",
/// "bay leaves" is "bay leaf" and "cheeses" is "cheese". Conservative: a word that only looks plural ("hummus",
/// "asparagus", "couscous", "molasses", "swiss", "glass") comes back unchanged. Expects one lowercased word.
enum EnglishPlural {

    static func singular(_ word: String) -> String {
        if invariant.contains(word) { return word }
        if let irregular = irregular[word] { return irregular }
        guard word.count > 3, word.hasSuffix("s"), !word.hasSuffix("ss"), !word.hasSuffix("us") else { return word }
        let withoutS = String(word.dropLast())
        if eEndingNouns.contains(withoutS) { return withoutS }              // cookies → cookie, quiches → quiche
        if word.count > 4, word.hasSuffix("ies") { return String(word.dropLast(3)) + "y" }   // cherries → cherry
        if word.count > 4, esPluralEndings.contains(where: word.hasSuffix) {
            return String(word.dropLast(2))                                  // peaches → peach, tomatoes → tomato
        }
        return withoutS                                                      // carrots → carrot, cheeses → cheese
    }

    /// Endings whose plural adds "es" to the singular.
    private static let esPluralEndings = ["ches", "shes", "xes", "sses", "oes"]

    /// Words ending in "s" that are already singular (or the same either way).
    private static let invariant: Set<String> = [
        "series", "species", "molasses", "news", "lens", "pastis", "iris", "atlas", "pancreas",
    ]

    /// Plurals no suffix rule can fold. "-ves" is listed rather than ruled: olives, cloves and chives keep their "e".
    private static let irregular: [String: String] = [
        "leaves": "leaf", "loaves": "loaf", "halves": "half", "knives": "knife", "shelves": "shelf",
        "calves": "calf", "wolves": "wolf", "geese": "goose", "mice": "mouse", "teeth": "tooth", "feet": "foot",
        "children": "child", "chilies": "chili", "chillies": "chilli", "fungi": "fungus", "cacti": "cactus",
    ]

    /// Singulars ending in "e" that the "-ies" / "-ches" / "-oes" rules would otherwise cut too short.
    private static let eEndingNouns: Set<String> = [
        "cookie", "brownie", "smoothie", "veggie", "calorie", "toastie", "hoagie", "rotisserie", "charcuterie",
        "patisserie", "boulangerie", "goodie", "sweetie", "quiche", "brioche", "ganache", "cloche", "niche", "cache",
        "panache", "sloe", "aloe", "shoe", "oboe", "canoe", "mousse", "crevasse",
    ]
}
