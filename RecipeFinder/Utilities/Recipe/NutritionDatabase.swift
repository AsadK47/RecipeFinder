import Foundation

/// Per-100 g nutritional reference data for common cooking ingredients.
/// Values follow UK FSA / USDA data and match the UK standard nutrition label order:
/// energy, fat, saturates, carbohydrate, sugars, fibre, protein, salt.
enum NutritionDatabase {

    struct Entry {
        let kcalPer100g: Double
        let fatPer100g: Double
        let satPer100g: Double
        let carbsPer100g: Double
        let sugarsPer100g: Double
        let fibrePer100g: Double
        let proteinPer100g: Double
        let saltPer100g: Double
        /// Density for converting volume units (ml, cup, tbsp …) to grams.
        let gramsPerMl: Double
        /// Weight per canonical count unit (e.g. "clove" → 5 g, "piece" → 150 g).
        let gramsPerUnit: [String: Double]

        /// Positional init: kcal, protein, carbs, fat — then keyword args for the rest.
        /// `sat`, `sugars`, `salt` default to 0 where exact data is unavailable.
        init(
            _ kcal: Double,
            _ protein: Double,
            _ carbs: Double,
            _ fat: Double,
            sat: Double = 0,
            sugars: Double = 0,
            fibre: Double = 0,
            salt: Double = 0,
            gPerMl: Double = 1.0,
            units: [String: Double] = [:]
        ) {
            kcalPer100g    = kcal
            proteinPer100g = protein
            carbsPer100g   = carbs
            fatPer100g     = fat
            satPer100g     = sat
            sugarsPer100g  = sugars
            fibrePer100g   = fibre
            saltPer100g    = salt
            gramsPerMl     = gPerMl
            gramsPerUnit   = units
        }
    }

    // MARK: - Lookup

    static func lookup(_ rawName: String) -> Entry? {
        let key = normalize(rawName)
        if let entry = entries[key] { return entry }

        // Progressively drop leading words ("extra virgin olive oil" → "olive oil")
        var words = key.split(separator: " ").map(String.init)
        while words.count > 1 {
            words.removeFirst()
            let candidate = words.joined(separator: " ")
            if let entry = entries[candidate] { return entry }
        }

        // Substring: return entry whose key is the longest substring of the normalised name
        var best: (key: String, entry: Entry)? = nil
        for (dbKey, entry) in entries where dbKey.count >= 3 {
            if key.contains(dbKey), best == nil || dbKey.count > best!.key.count {
                best = (dbKey, entry)
            }
        }
        return best?.entry
    }

    private static func normalize(_ name: String) -> String {
        let base = name.lowercased().components(separatedBy: ",").first ?? name.lowercased()
        let adjectives: Set<String> = [
            "fresh", "dried", "frozen", "canned", "tinned", "chopped", "diced",
            "sliced", "minced", "crushed", "grated", "shredded", "cooked", "raw",
            "whole", "extra", "virgin", "large", "small", "medium", "ripe", "peeled",
            "pitted", "boneless", "skinless", "lean", "ground", "unsalted", "salted",
            "uncooked", "organic", "baby", "mini", "thick", "thin", "halved",
            "quartered", "finely", "roughly", "lightly", "softened", "melted",
            "boiled", "steamed", "roasted", "fried", "grilled", "baked", "mashed",
            "pureed", "juiced", "zested", "toasted", "packed", "heaped", "level",
            "rounded", "full", "low", "reduced", "skimmed", "semi", "double",
            "single", "heavy", "whipped", "plain", "self", "raising",
            "room", "temperature", "good", "quality", "firm", "soft",
        ]
        let words = base
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty && !adjectives.contains($0) && !$0.hasPrefix("(") }
        return words.joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Reference data (per 100 g, UK FSA / USDA)

    static let entries: [String: Entry] = {
        var d: [String: Entry] = [:]

        // MARK: Poultry
        d["chicken breast"] = .init(165, 31.0,  0.0,  3.6, sat: 0.8,  sugars: 0,   fibre: 0,    salt: 0.1,
                                    units: ["piece": 175, "breast": 175])
        d["chicken thigh"]  = .init(209, 26.0,  0.0, 11.0, sat: 3.0,  sugars: 0,   fibre: 0,    salt: 0.1,
                                    units: ["piece": 110, "thigh": 110])
        d["chicken"]        = .init(165, 31.0,  0.0,  3.6, sat: 1.0,  sugars: 0,   fibre: 0,    salt: 0.1,
                                    units: ["piece": 175, "breast": 175, "thigh": 110])
        d["turkey"]         = .init(135, 30.0,  0.0,  1.0, sat: 0.3,  sugars: 0,   fibre: 0,    salt: 0.1,
                                    units: ["piece": 150])

        // MARK: Red meat
        d["beef mince"]     = .init(254, 26.0,  0.0, 16.0, sat: 6.0,  sugars: 0,   fibre: 0,    salt: 0.1)
        d["mince"]          = .init(254, 26.0,  0.0, 16.0, sat: 6.0,  sugars: 0,   fibre: 0,    salt: 0.1)
        d["beef"]           = .init(250, 26.0,  0.0, 15.0, sat: 5.5,  sugars: 0,   fibre: 0,    salt: 0.1,
                                    units: ["piece": 200, "steak": 220])
        d["pork"]           = .init(242, 27.0,  0.0, 14.0, sat: 4.5,  sugars: 0,   fibre: 0,    salt: 0.1,
                                    units: ["piece": 180, "chop": 150])
        d["lamb"]           = .init(282, 25.0,  0.0, 20.0, sat: 8.8,  sugars: 0,   fibre: 0,    salt: 0.1,
                                    units: ["piece": 180])
        d["bacon"]          = .init(541, 37.0,  0.0, 45.0, sat: 14.0, sugars: 0,   fibre: 0,    salt: 3.8,
                                    units: ["rasher": 25, "slice": 25, "piece": 25])
        d["sausage"]        = .init(301, 11.0,  3.1, 27.0, sat: 10.0, sugars: 1.0, fibre: 0,    salt: 1.8,
                                    units: ["piece": 60])

        // MARK: Fish & seafood
        d["salmon"]         = .init(208, 20.0,  0.0, 13.0, sat: 3.2,  sugars: 0,   fibre: 0,    salt: 0.1,
                                    units: ["piece": 150, "fillet": 150])
        d["cod"]            = .init( 82, 18.0,  0.0,  0.7, sat: 0.1,  sugars: 0,   fibre: 0,    salt: 0.1,
                                    units: ["piece": 150, "fillet": 150])
        d["tuna"]           = .init(116, 26.0,  0.0,  1.0, sat: 0.3,  sugars: 0,   fibre: 0,    salt: 0.1,
                                    units: ["can": 165, "piece": 150])
        d["prawns"]         = .init( 99, 24.0,  0.0,  0.3, sat: 0.1,  sugars: 0,   fibre: 0,    salt: 1.1,
                                    units: ["piece": 10])
        d["shrimp"]         = .init( 99, 24.0,  0.0,  0.3, sat: 0.1,  sugars: 0,   fibre: 0,    salt: 1.1,
                                    units: ["piece": 10])
        d["haddock"]        = .init( 82, 19.0,  0.0,  0.6, sat: 0.1,  sugars: 0,   fibre: 0,    salt: 0.2,
                                    units: ["fillet": 150])
        d["mackerel"]       = .init(305, 19.0,  0.0, 25.0, sat: 5.3,  sugars: 0,   fibre: 0,    salt: 0.2,
                                    units: ["fillet": 120])

        // MARK: Eggs
        d["egg"]            = .init(155, 13.0,  1.1, 11.0, sat: 3.1,  sugars: 0.6, fibre: 0,    salt: 0.3,
                                    units: ["piece": 60, "egg": 60])
        d["egg white"]      = .init( 52, 11.0,  0.7,  0.2, sat: 0,    sugars: 0.7, fibre: 0,    salt: 0.3,
                                    units: ["piece": 30])
        d["egg yolk"]       = .init(322, 16.0,  3.6, 27.0, sat: 9.0,  sugars: 0.5, fibre: 0,    salt: 0.1,
                                    units: ["piece": 17])

        // MARK: Dairy
        d["milk"]           = .init( 61,  3.2,  4.8,  3.3, sat: 2.1,  sugars: 4.7, fibre: 0,    salt: 0.1,
                                    gPerMl: 1.03)
        d["cream"]          = .init(340,  2.8,  2.8, 36.0, sat: 23.0, sugars: 2.5, fibre: 0,    salt: 0.05,
                                    gPerMl: 1.0)
        d["double cream"]   = .init(480,  2.0,  2.0, 50.0, sat: 33.0, sugars: 1.8, fibre: 0,    salt: 0.05,
                                    gPerMl: 1.0)
        d["butter"]         = .init(717,  0.9,  0.1, 81.0, sat: 51.0, sugars: 0.1, fibre: 0,    salt: 0.1,
                                    gPerMl: 0.97,
                                    units: ["stick": 113, "block": 250])
        d["cheddar"]        = .init(402, 25.0,  1.3, 33.0, sat: 21.0, sugars: 0.1, fibre: 0,    salt: 1.7)
        d["mozzarella"]     = .init(280, 28.0,  2.2, 17.0, sat: 11.0, sugars: 0.7, fibre: 0,    salt: 0.6)
        d["parmesan"]       = .init(431, 38.0,  3.2, 29.0, sat: 19.0, sugars: 0,   fibre: 0,    salt: 1.8)
        d["feta"]           = .init(264, 14.0,  4.1, 21.0, sat: 15.0, sugars: 0.5, fibre: 0,    salt: 2.7)
        d["cheese"]         = .init(402, 25.0,  1.3, 33.0, sat: 21.0, sugars: 0.1, fibre: 0,    salt: 1.5)
        d["yogurt"]         = .init( 59, 10.0,  3.6,  0.4, sat: 0.1,  sugars: 3.2, fibre: 0,    salt: 0.1,
                                    gPerMl: 1.05)
        d["sour cream"]     = .init(193,  2.4,  4.6, 19.0, sat: 12.0, sugars: 3.7, fibre: 0,    salt: 0.1,
                                    gPerMl: 1.0)
        d["cream cheese"]   = .init(342,  6.0,  4.1, 34.0, sat: 22.0, sugars: 2.8, fibre: 0,    salt: 0.5,
                                    gPerMl: 1.0)
        d["ricotta"]        = .init(174, 11.0,  3.0, 13.0, sat: 8.3,  sugars: 1.0, fibre: 0,    salt: 0.1,
                                    gPerMl: 1.0)

        // MARK: Oils & fats
        d["olive oil"]      = .init(884,  0.0,  0.0, 100.0, sat: 14.0, sugars: 0,  fibre: 0,    salt: 0,
                                    gPerMl: 0.9)
        d["sunflower oil"]  = .init(884,  0.0,  0.0, 100.0, sat: 11.0, sugars: 0,  fibre: 0,    salt: 0,
                                    gPerMl: 0.9)
        d["vegetable oil"]  = .init(884,  0.0,  0.0, 100.0, sat: 12.0, sugars: 0,  fibre: 0,    salt: 0,
                                    gPerMl: 0.9)
        d["coconut oil"]    = .init(892,  0.0,  0.0,  99.0, sat: 82.0, sugars: 0,  fibre: 0,    salt: 0,
                                    gPerMl: 0.92)
        d["rapeseed oil"]   = .init(884,  0.0,  0.0, 100.0, sat: 7.0,  sugars: 0,  fibre: 0,    salt: 0,
                                    gPerMl: 0.9)
        d["oil"]            = .init(884,  0.0,  0.0, 100.0, sat: 13.0, sugars: 0,  fibre: 0,    salt: 0,
                                    gPerMl: 0.9)

        // MARK: Vegetables
        d["onion"]          = .init( 40,  1.1,  9.3,  0.1, sat: 0,    sugars: 6.5, fibre: 1.7,  salt: 0.01,
                                    units: ["piece": 150, "medium": 150, "large": 220, "small": 80])
        d["garlic"]         = .init(149,  6.4, 33.0,  0.5, sat: 0.1,  sugars: 1.0, fibre: 2.1,  salt: 0.02,
                                    units: ["clove": 5, "head": 50, "bulb": 50])
        d["tomato"]         = .init( 18,  0.9,  3.9,  0.2, sat: 0,    sugars: 2.6, fibre: 1.2,  salt: 0.01,
                                    units: ["piece": 120, "medium": 120, "large": 180,
                                            "can": 400, "slice": 20])
        d["potato"]         = .init( 77,  2.0, 17.0,  0.1, sat: 0,    sugars: 0.7, fibre: 2.2,  salt: 0.01,
                                    units: ["piece": 200, "medium": 200, "large": 300, "small": 130])
        d["sweet potato"]   = .init( 86,  1.6, 20.0,  0.1, sat: 0,    sugars: 4.2, fibre: 3.0,  salt: 0.05,
                                    units: ["piece": 200, "medium": 200, "large": 300])
        d["carrot"]         = .init( 41,  0.9, 10.0,  0.2, sat: 0,    sugars: 4.7, fibre: 2.8,  salt: 0.07,
                                    units: ["piece": 80, "medium": 80, "large": 120, "small": 50])
        d["celery"]         = .init( 16,  0.7,  3.0,  0.2, sat: 0,    sugars: 1.4, fibre: 1.6,  salt: 0.1,
                                    units: ["piece": 40, "stalk": 40, "stick": 40, "bunch": 400])
        d["broccoli"]       = .init( 34,  2.8,  7.0,  0.4, sat: 0,    sugars: 1.7, fibre: 2.6,  salt: 0.04,
                                    units: ["piece": 200, "head": 200, "floret": 25])
        d["spinach"]        = .init( 23,  2.9,  3.6,  0.4, sat: 0,    sugars: 0.4, fibre: 2.2,  salt: 0.1,
                                    gPerMl: 0.15,
                                    units: ["handful": 30, "bunch": 200, "bag": 200])
        d["kale"]           = .init( 49,  4.3,  9.0,  0.9, sat: 0.1,  sugars: 1.0, fibre: 3.6,  salt: 0.07,
                                    gPerMl: 0.12,
                                    units: ["handful": 30, "bunch": 200])
        d["mushroom"]       = .init( 22,  3.1,  3.3,  0.3, sat: 0,    sugars: 0.4, fibre: 1.0,  salt: 0.01,
                                    gPerMl: 0.35,
                                    units: ["piece": 20, "mushroom": 20, "large": 40])
        d["bell pepper"]    = .init( 31,  1.0,  6.0,  0.3, sat: 0,    sugars: 4.2, fibre: 2.1,  salt: 0.01,
                                    units: ["piece": 120, "medium": 120])
        d["pepper"]         = .init( 31,  1.0,  6.0,  0.3, sat: 0,    sugars: 4.2, fibre: 2.1,  salt: 0.01,
                                    units: ["piece": 120, "medium": 120])
        d["black pepper"]   = .init(251, 10.0, 64.0,  3.3, sat: 0.6,  sugars: 0.6, fibre: 26.5, salt: 0.02,
                                    gPerMl: 0.6)
        d["white pepper"]   = .init(296, 11.0, 68.0,  2.1, sat: 0.7,  sugars: 0,   fibre: 26.2, salt: 0.02,
                                    gPerMl: 0.6)
        d["courgette"]      = .init( 17,  1.2,  3.1,  0.3, sat: 0,    sugars: 1.7, fibre: 1.0,  salt: 0.01,
                                    units: ["piece": 200, "medium": 200])
        d["zucchini"]       = .init( 17,  1.2,  3.1,  0.3, sat: 0,    sugars: 1.7, fibre: 1.0,  salt: 0.01,
                                    units: ["piece": 200, "medium": 200])
        d["cucumber"]       = .init( 16,  0.7,  3.6,  0.1, sat: 0,    sugars: 1.7, fibre: 0.5,  salt: 0.01,
                                    units: ["piece": 200, "medium": 200, "slice": 15])
        d["corn"]           = .init( 86,  3.3, 19.0,  1.4, sat: 0.2,  sugars: 3.2, fibre: 2.7,  salt: 0.01,
                                    units: ["piece": 100, "ear": 100, "cob": 100, "can": 285])
        d["pea"]            = .init( 81,  5.4, 14.0,  0.4, sat: 0,    sugars: 4.0, fibre: 5.7,  salt: 0.01,
                                    gPerMl: 0.6)
        d["peas"]           = .init( 81,  5.4, 14.0,  0.4, sat: 0,    sugars: 4.0, fibre: 5.7,  salt: 0.01,
                                    gPerMl: 0.6)
        d["green bean"]     = .init( 31,  1.8,  7.0,  0.1, sat: 0,    sugars: 2.0, fibre: 2.7,  salt: 0.01,
                                    units: ["handful": 60])
        d["green beans"]    = .init( 31,  1.8,  7.0,  0.1, sat: 0,    sugars: 2.0, fibre: 2.7,  salt: 0.01,
                                    units: ["handful": 60])
        d["butternut squash"] = .init(45, 1.0, 12.0,  0.1, sat: 0,    sugars: 4.0, fibre: 1.5,  salt: 0.01,
                                    units: ["piece": 400, "medium": 400])
        d["squash"]         = .init( 45,  1.0, 12.0,  0.1, sat: 0,    sugars: 4.0, fibre: 1.5,  salt: 0.01,
                                    units: ["piece": 400])
        d["cabbage"]        = .init( 25,  1.3,  6.0,  0.1, sat: 0,    sugars: 2.3, fibre: 2.5,  salt: 0.01,
                                    gPerMl: 0.4,
                                    units: ["piece": 800, "head": 800, "handful": 60])
        d["leek"]           = .init( 61,  1.5, 14.0,  0.3, sat: 0,    sugars: 3.0, fibre: 1.8,  salt: 0.01,
                                    units: ["piece": 100, "medium": 100, "large": 150])
        d["aubergine"]      = .init( 25,  1.0,  6.0,  0.2, sat: 0,    sugars: 2.5, fibre: 2.5,  salt: 0.01,
                                    units: ["piece": 300, "medium": 300])
        d["eggplant"]       = .init( 25,  1.0,  6.0,  0.2, sat: 0,    sugars: 2.5, fibre: 2.5,  salt: 0.01,
                                    units: ["piece": 300, "medium": 300])
        d["lettuce"]        = .init( 15,  1.4,  2.9,  0.2, sat: 0,    sugars: 1.2, fibre: 1.3,  salt: 0.02,
                                    gPerMl: 0.1,
                                    units: ["head": 500, "handful": 30, "leaf": 10])
        d["avocado"]        = .init(160,  2.0,  9.0, 15.0, sat: 2.1,  sugars: 0.7, fibre: 6.7,  salt: 0.01,
                                    units: ["piece": 200, "medium": 200, "half": 100])
        d["asparagus"]      = .init( 20,  2.2,  3.9,  0.1, sat: 0,    sugars: 1.9, fibre: 2.1,  salt: 0.01,
                                    units: ["piece": 20, "spear": 20, "stalk": 20, "bunch": 250])
        d["spring onion"]   = .init( 32,  1.8,  7.3,  0.2, sat: 0,    sugars: 3.0, fibre: 2.6,  salt: 0.01,
                                    units: ["piece": 15, "stalk": 15])
        d["scallion"]       = .init( 32,  1.8,  7.3,  0.2, sat: 0,    sugars: 3.0, fibre: 2.6,  salt: 0.01,
                                    units: ["piece": 15])

        // MARK: Fruits
        d["apple"]          = .init( 52,  0.3, 14.0,  0.2, sat: 0,    sugars: 10.0, fibre: 2.4, salt: 0.01,
                                    units: ["piece": 182, "medium": 182, "large": 220])
        d["banana"]         = .init( 89,  1.1, 23.0,  0.3, sat: 0.1,  sugars: 12.0, fibre: 2.6, salt: 0.01,
                                    units: ["piece": 118, "medium": 118, "large": 150])
        d["lemon"]          = .init( 29,  1.1,  9.0,  0.3, sat: 0,    sugars: 2.5,  fibre: 2.8, salt: 0.01,
                                    units: ["piece": 85, "medium": 85, "large": 110, "slice": 15])
        d["lime"]           = .init( 30,  0.7, 11.0,  0.2, sat: 0,    sugars: 1.7,  fibre: 2.8, salt: 0.01,
                                    units: ["piece": 67, "medium": 67, "slice": 10])
        d["orange"]         = .init( 47,  0.9, 12.0,  0.1, sat: 0,    sugars: 8.5,  fibre: 2.4, salt: 0.01,
                                    units: ["piece": 131, "medium": 131, "large": 180])
        d["strawberry"]     = .init( 32,  0.7,  7.7,  0.3, sat: 0,    sugars: 4.9,  fibre: 2.0, salt: 0.01,
                                    units: ["piece": 12, "handful": 80])
        d["blueberry"]      = .init( 57,  0.7, 14.0,  0.3, sat: 0,    sugars: 9.9,  fibre: 2.4, salt: 0.01,
                                    units: ["handful": 80])
        d["raspberry"]      = .init( 52,  1.2, 12.0,  0.7, sat: 0,    sugars: 4.4,  fibre: 6.5, salt: 0.01,
                                    units: ["handful": 60])
        d["mango"]          = .init( 60,  0.8, 15.0,  0.4, sat: 0.1,  sugars: 13.7, fibre: 1.6, salt: 0.01,
                                    units: ["piece": 200, "medium": 200])
        d["pineapple"]      = .init( 50,  0.5, 13.0,  0.1, sat: 0,    sugars: 9.9,  fibre: 1.4, salt: 0.01,
                                    units: ["piece": 900, "slice": 80])
        d["grapes"]         = .init( 67,  0.6, 17.0,  0.4, sat: 0.1,  sugars: 16.3, fibre: 0.9, salt: 0.01,
                                    units: ["bunch": 150, "handful": 80])

        // MARK: Grains & starches
        d["white rice"]     = .init(130,  2.4, 28.0,  0.3, sat: 0.1,  sugars: 0,   fibre: 0.4,  salt: 0.01,
                                    gPerMl: 0.75)
        d["brown rice"]     = .init(123,  2.7, 26.0,  0.9, sat: 0.2,  sugars: 0.7, fibre: 1.8,  salt: 0.01,
                                    gPerMl: 0.75)
        d["rice"]           = .init(130,  2.4, 28.0,  0.3, sat: 0.1,  sugars: 0,   fibre: 0.4,  salt: 0.01,
                                    gPerMl: 0.75)
        d["pasta"]          = .init(158,  5.5, 31.0,  0.9, sat: 0.2,  sugars: 0.6, fibre: 1.8,  salt: 0.01,
                                    gPerMl: 0.7)
        d["spaghetti"]      = .init(158,  5.5, 31.0,  0.9, sat: 0.2,  sugars: 0.6, fibre: 1.8,  salt: 0.01,
                                    gPerMl: 0.7)
        d["noodle"]         = .init(138,  4.5, 28.0,  0.6, sat: 0.1,  sugars: 0.3, fibre: 0.9,  salt: 0.02,
                                    gPerMl: 0.7)
        d["noodles"]        = .init(138,  4.5, 28.0,  0.6, sat: 0.1,  sugars: 0.3, fibre: 0.9,  salt: 0.02,
                                    gPerMl: 0.7)
        d["flour"]          = .init(364, 10.0, 76.0,  1.0, sat: 0.2,  sugars: 0.3, fibre: 2.7,  salt: 0.01,
                                    gPerMl: 0.53, units: ["cup": 125])
        d["bread"]          = .init(265,  9.0, 49.0,  3.2, sat: 0.6,  sugars: 3.5, fibre: 2.7,  salt: 1.0,
                                    units: ["slice": 30, "piece": 30])
        d["oats"]           = .init(389, 17.0, 66.0,  7.0, sat: 1.3,  sugars: 1.0, fibre: 10.6, salt: 0.01,
                                    gPerMl: 0.43)
        d["couscous"]       = .init(112,  3.8, 23.0,  0.2, sat: 0,    sugars: 0,   fibre: 1.4,  salt: 0.01,
                                    gPerMl: 0.65)
        d["quinoa"]         = .init(120,  4.4, 22.0,  1.9, sat: 0.2,  sugars: 1.6, fibre: 2.8,  salt: 0.01,
                                    gPerMl: 0.65)
        d["breadcrumb"]     = .init(395, 13.0, 73.0,  5.3, sat: 0.9,  sugars: 3.6, fibre: 3.8,  salt: 1.2,
                                    gPerMl: 0.3)
        d["breadcrumbs"]    = .init(395, 13.0, 73.0,  5.3, sat: 0.9,  sugars: 3.6, fibre: 3.8,  salt: 1.2,
                                    gPerMl: 0.3)
        d["tortilla"]       = .init(235,  6.5, 44.0,  4.5, sat: 1.5,  sugars: 2.0, fibre: 2.7,  salt: 0.8,
                                    units: ["piece": 45, "wrap": 45])
        d["wrap"]           = .init(235,  6.5, 44.0,  4.5, sat: 1.5,  sugars: 2.0, fibre: 2.7,  salt: 0.8,
                                    units: ["piece": 45])
        d["pita"]           = .init(275,  9.0, 55.0,  1.2, sat: 0.2,  sugars: 1.5, fibre: 2.2,  salt: 0.8,
                                    units: ["piece": 60])

        // MARK: Pulses
        d["chickpea"]       = .init(164,  8.9, 27.0,  2.6, sat: 0.3,  sugars: 5.3, fibre: 7.6,  salt: 0.01,
                                    gPerMl: 0.7, units: ["can": 400])
        d["chickpeas"]      = .init(164,  8.9, 27.0,  2.6, sat: 0.3,  sugars: 5.3, fibre: 7.6,  salt: 0.01,
                                    gPerMl: 0.7, units: ["can": 400])
        d["lentil"]         = .init(116,  9.0, 20.0,  0.4, sat: 0,    sugars: 1.8, fibre: 7.9,  salt: 0.01,
                                    gPerMl: 0.75)
        d["lentils"]        = .init(116,  9.0, 20.0,  0.4, sat: 0,    sugars: 1.8, fibre: 7.9,  salt: 0.01,
                                    gPerMl: 0.75)
        d["kidney bean"]    = .init(127,  8.7, 23.0,  0.5, sat: 0.1,  sugars: 0.3, fibre: 6.4,  salt: 0.01,
                                    units: ["can": 400])
        d["kidney beans"]   = .init(127,  8.7, 23.0,  0.5, sat: 0.1,  sugars: 0.3, fibre: 6.4,  salt: 0.01,
                                    units: ["can": 400])
        d["black bean"]     = .init(132,  8.9, 24.0,  0.5, sat: 0.1,  sugars: 0.3, fibre: 8.7,  salt: 0.01,
                                    units: ["can": 400])
        d["black beans"]    = .init(132,  8.9, 24.0,  0.5, sat: 0.1,  sugars: 0.3, fibre: 8.7,  salt: 0.01,
                                    units: ["can": 400])
        d["cannellini bean"] = .init(139, 9.7, 25.0,  0.4, sat: 0.1,  sugars: 0.3, fibre: 6.3,  salt: 0.01,
                                    units: ["can": 400])
        d["cannellini beans"] = .init(139, 9.7, 25.0, 0.4, sat: 0.1,  sugars: 0.3, fibre: 6.3,  salt: 0.01,
                                    units: ["can": 400])
        d["beans"]          = .init(132,  8.7, 23.0,  0.5, sat: 0.1,  sugars: 0.5, fibre: 7.0,  salt: 0.01,
                                    gPerMl: 0.75, units: ["can": 400])

        // MARK: Nuts & seeds
        d["almond"]         = .init(579, 21.0, 22.0, 50.0, sat: 3.8,  sugars: 4.4, fibre: 12.5, salt: 0.01,
                                    units: ["piece": 1.2, "handful": 30])
        d["almonds"]        = .init(579, 21.0, 22.0, 50.0, sat: 3.8,  sugars: 4.4, fibre: 12.5, salt: 0.01,
                                    units: ["handful": 30])
        d["walnut"]         = .init(654, 15.0, 14.0, 65.0, sat: 6.1,  sugars: 2.6, fibre: 6.7,  salt: 0.01,
                                    units: ["piece": 7, "handful": 30])
        d["walnuts"]        = .init(654, 15.0, 14.0, 65.0, sat: 6.1,  sugars: 2.6, fibre: 6.7,  salt: 0.01,
                                    units: ["handful": 30])
        d["cashew"]         = .init(553, 18.0, 30.0, 44.0, sat: 7.8,  sugars: 5.9, fibre: 3.3,  salt: 0.01,
                                    units: ["piece": 1.5, "handful": 30])
        d["cashews"]        = .init(553, 18.0, 30.0, 44.0, sat: 7.8,  sugars: 5.9, fibre: 3.3,  salt: 0.01,
                                    units: ["handful": 30])
        d["peanut"]         = .init(567, 26.0, 16.0, 49.0, sat: 6.8,  sugars: 3.6, fibre: 8.5,  salt: 0.01,
                                    units: ["handful": 30])
        d["peanuts"]        = .init(567, 26.0, 16.0, 49.0, sat: 6.8,  sugars: 3.6, fibre: 8.5,  salt: 0.01,
                                    units: ["handful": 30])
        d["peanut butter"]  = .init(588, 25.0, 20.0, 50.0, sat: 9.0,  sugars: 6.0, fibre: 5.0,  salt: 0.4,
                                    gPerMl: 1.1)
        d["pine nut"]       = .init(673, 14.0, 13.0, 68.0, sat: 4.9,  sugars: 3.6, fibre: 3.7,  salt: 0.01,
                                    units: ["handful": 15])
        d["pine nuts"]      = .init(673, 14.0, 13.0, 68.0, sat: 4.9,  sugars: 3.6, fibre: 3.7,  salt: 0.01,
                                    units: ["handful": 15])
        d["sesame seed"]    = .init(573, 18.0, 23.0, 50.0, sat: 7.0,  sugars: 0.3, fibre: 11.8, salt: 0.01,
                                    gPerMl: 0.6)
        d["sesame seeds"]   = .init(573, 18.0, 23.0, 50.0, sat: 7.0,  sugars: 0.3, fibre: 11.8, salt: 0.01,
                                    gPerMl: 0.6)
        d["sunflower seed"] = .init(584, 21.0, 20.0, 51.0, sat: 4.5,  sugars: 2.6, fibre: 8.6,  salt: 0.01,
                                    gPerMl: 0.58)
        d["sunflower seeds"] = .init(584, 21.0, 20.0, 51.0, sat: 4.5, sugars: 2.6, fibre: 8.6,  salt: 0.01,
                                    gPerMl: 0.58)
        d["chia seed"]      = .init(486, 17.0, 42.0, 31.0, sat: 3.3,  sugars: 0,   fibre: 34.4, salt: 0.01,
                                    gPerMl: 0.72)
        d["chia seeds"]     = .init(486, 17.0, 42.0, 31.0, sat: 3.3,  sugars: 0,   fibre: 34.4, salt: 0.01,
                                    gPerMl: 0.72)
        d["flaxseed"]       = .init(534, 18.0, 29.0, 42.0, sat: 3.7,  sugars: 1.5, fibre: 27.3, salt: 0.03,
                                    gPerMl: 0.7)
        d["flaxseeds"]      = .init(534, 18.0, 29.0, 42.0, sat: 3.7,  sugars: 1.5, fibre: 27.3, salt: 0.03,
                                    gPerMl: 0.7)
        d["coconut"]        = .init(660,  6.9, 25.0, 62.0, sat: 55.0, sugars: 6.0, fibre: 16.3, salt: 0.06,
                                    gPerMl: 0.3)

        // MARK: Sweeteners
        d["sugar"]          = .init(387,  0.0, 100.0,  0.0, sat: 0,   sugars: 99.9, fibre: 0,   salt: 0,
                                    gPerMl: 0.85)
        d["caster sugar"]   = .init(387,  0.0, 100.0,  0.0, sat: 0,   sugars: 99.9, fibre: 0,   salt: 0,
                                    gPerMl: 0.85)
        d["brown sugar"]    = .init(380,  0.1,  98.0,  0.0, sat: 0,   sugars: 97.0, fibre: 0,   salt: 0,
                                    gPerMl: 0.9)
        d["icing sugar"]    = .init(387,  0.0, 100.0,  0.0, sat: 0,   sugars: 99.9, fibre: 0,   salt: 0,
                                    gPerMl: 0.56)
        d["honey"]          = .init(304,  0.3,  82.0,  0.0, sat: 0,   sugars: 82.0, fibre: 0.2, salt: 0.01,
                                    gPerMl: 1.4)
        d["maple syrup"]    = .init(260,  0.0,  67.0,  0.1, sat: 0,   sugars: 60.0, fibre: 0,   salt: 0.01,
                                    gPerMl: 1.32)
        d["golden syrup"]   = .init(325,  0.3,  84.0,  0.0, sat: 0,   sugars: 79.0, fibre: 0,   salt: 0.05,
                                    gPerMl: 1.5)
        d["agave"]          = .init(310,  0.1,  76.0,  0.3, sat: 0,   sugars: 68.0, fibre: 0,   salt: 0.01,
                                    gPerMl: 1.35)
        d["syrup"]          = .init(325,  0.3,  84.0,  0.0, sat: 0,   sugars: 79.0, fibre: 0,   salt: 0.05,
                                    gPerMl: 1.5)

        // MARK: Condiments & sauces
        d["soy sauce"]      = .init(  8,  1.3,  0.8,  0.1, sat: 0,    sugars: 0.8, fibre: 0,    salt: 14.6,
                                    gPerMl: 1.1)
        d["fish sauce"]     = .init( 35,  5.0,  3.6,  0.0, sat: 0,    sugars: 3.6, fibre: 0,    salt: 18.0,
                                    gPerMl: 1.07)
        d["worcestershire"] = .init( 78,  1.1, 20.0,  0.0, sat: 0,    sugars: 14.0, fibre: 0,   salt: 4.5,
                                    gPerMl: 1.1)
        d["ketchup"]        = .init( 97,  1.4, 25.0,  0.3, sat: 0,    sugars: 21.0, fibre: 0.6, salt: 2.0,
                                    gPerMl: 1.1)
        d["mayonnaise"]     = .init(680,  1.0,  0.6, 75.0, sat: 7.8,  sugars: 0.5, fibre: 0,    salt: 1.4,
                                    gPerMl: 0.97)
        d["mustard"]        = .init( 66,  4.4,  5.3,  3.3, sat: 0.3,  sugars: 0.5, fibre: 3.3,  salt: 2.6,
                                    gPerMl: 1.05)
        d["vinegar"]        = .init( 20,  0.0,  0.9,  0.0, sat: 0,    sugars: 0,   fibre: 0,    salt: 0.01,
                                    gPerMl: 1.0)
        d["balsamic vinegar"] = .init(88, 0.5, 17.0,  0.0, sat: 0,    sugars: 14.0, fibre: 0,   salt: 0.03,
                                    gPerMl: 1.1)
        d["tomato puree"]   = .init( 32,  1.6,  7.5,  0.1, sat: 0,    sugars: 5.0, fibre: 1.7,  salt: 0.03,
                                    gPerMl: 1.04)
        d["tomato paste"]   = .init( 82,  4.3, 19.0,  0.5, sat: 0.1,  sugars: 11.0, fibre: 4.2, salt: 0.1,
                                    gPerMl: 1.06)
        d["passata"]        = .init( 32,  1.8,  6.5,  0.3, sat: 0,    sugars: 5.0, fibre: 1.5,  salt: 0.03,
                                    gPerMl: 1.02)
        d["hot sauce"]      = .init( 12,  0.9,  1.9,  0.5, sat: 0,    sugars: 0.5, fibre: 0,    salt: 4.0,
                                    gPerMl: 1.0)
        d["sriracha"]       = .init( 93,  1.0, 21.0,  0.3, sat: 0,    sugars: 15.0, fibre: 1.0, salt: 2.0,
                                    gPerMl: 1.05)
        d["tahini"]         = .init(595, 17.0, 21.0, 54.0, sat: 7.5,  sugars: 0.5, fibre: 9.3,  salt: 0.03,
                                    gPerMl: 1.1)

        // MARK: Stocks & liquids
        d["chicken stock"]  = .init( 13,  1.4,  0.9,  0.4, sat: 0.1,  sugars: 0.4, fibre: 0,    salt: 0.6,
                                    gPerMl: 1.0)
        d["beef stock"]     = .init( 15,  2.7,  0.0,  0.5, sat: 0.2,  sugars: 0,   fibre: 0,    salt: 0.7,
                                    gPerMl: 1.0)
        d["vegetable stock"] = .init( 11, 0.3,  1.9,  0.2, sat: 0,    sugars: 1.0, fibre: 0,    salt: 0.5,
                                    gPerMl: 1.0)
        d["stock"]          = .init( 13,  1.0,  1.0,  0.3, sat: 0.1,  sugars: 0.5, fibre: 0,    salt: 0.6,
                                    gPerMl: 1.0)
        d["broth"]          = .init( 13,  1.0,  1.0,  0.3, sat: 0.1,  sugars: 0.5, fibre: 0,    salt: 0.6,
                                    gPerMl: 1.0)
        d["coconut milk"]   = .init(197,  2.0,  6.0, 19.0, sat: 16.0, sugars: 5.5, fibre: 0,    salt: 0.02,
                                    gPerMl: 1.0, units: ["can": 400])
        d["coconut cream"]  = .init(330,  3.6,  6.7, 34.0, sat: 30.0, sugars: 5.5, fibre: 0,    salt: 0.02,
                                    gPerMl: 1.0, units: ["can": 160])
        d["water"]          = .init(  0,  0.0,  0.0,  0.0, gPerMl: 1.0)

        // MARK: Herbs & spices (tiny quantities; included for coverage scoring)
        d["salt"]           = .init(  0,  0.0,  0.0,  0.0, sat: 0,    sugars: 0,   fibre: 0,    salt: 100.0,
                                    gPerMl: 2.0,
                                    units: ["pinch": 0.3, "dash": 0.6])
        d["cumin"]          = .init(375, 18.0, 44.0, 22.0, sat: 1.5,  sugars: 2.3, fibre: 10.5, salt: 0.17,
                                    gPerMl: 0.5)
        d["paprika"]        = .init(282, 14.0, 54.0, 13.0, sat: 2.1,  sugars: 10.3, fibre: 34.9, salt: 0.07,
                                    gPerMl: 0.5)
        d["turmeric"]       = .init(354,  8.0, 65.0, 10.0, sat: 3.1,  sugars: 3.2, fibre: 21.0, salt: 0.03,
                                    gPerMl: 0.5)
        d["cinnamon"]       = .init(247,  4.0, 81.0,  1.2, sat: 0.3,  sugars: 2.2, fibre: 53.1, salt: 0.01,
                                    gPerMl: 0.45)
        d["chilli"]         = .init( 40,  1.9,  8.8,  0.4, sat: 0,    sugars: 5.5, fibre: 1.5,  salt: 0.01,
                                    units: ["piece": 15])
        d["chili"]          = .init( 40,  1.9,  8.8,  0.4, sat: 0,    sugars: 5.5, fibre: 1.5,  salt: 0.01,
                                    units: ["piece": 15])
        d["chilli flakes"]  = .init(282, 14.0, 50.0, 14.0, sat: 2.1,  sugars: 10.0, fibre: 27.2, salt: 0.07,
                                    gPerMl: 0.4)
        d["chili flakes"]   = .init(282, 14.0, 50.0, 14.0, sat: 2.1,  sugars: 10.0, fibre: 27.2, salt: 0.07,
                                    gPerMl: 0.4)
        d["oregano"]        = .init(265,  9.0, 69.0,  4.3, sat: 0.7,  sugars: 4.1, fibre: 42.5, salt: 0.01,
                                    gPerMl: 0.3)
        d["basil"]          = .init( 23,  3.2,  2.7,  0.6, sat: 0,    sugars: 0.3, fibre: 1.6,  salt: 0.01,
                                    gPerMl: 0.15, units: ["bunch": 30, "handful": 15])
        d["thyme"]          = .init(101,  5.6, 24.0,  1.7, sat: 0.3,  sugars: 1.7, fibre: 18.6, salt: 0.01,
                                    gPerMl: 0.2, units: ["sprig": 1, "bunch": 15])
        d["rosemary"]       = .init(131,  3.3, 21.0,  5.9, sat: 0.7,  sugars: 0,   fibre: 42.6, salt: 0.06,
                                    units: ["sprig": 2, "bunch": 20])
        d["parsley"]        = .init( 36,  3.0,  6.3,  0.8, sat: 0.1,  sugars: 0.9, fibre: 3.3,  salt: 0.05,
                                    gPerMl: 0.15, units: ["bunch": 30, "handful": 15])
        d["coriander"]      = .init( 23,  2.1,  3.7,  0.5, sat: 0,    sugars: 0.9, fibre: 2.8,  salt: 0.05,
                                    gPerMl: 0.15, units: ["bunch": 30, "handful": 15])
        d["cilantro"]       = .init( 23,  2.1,  3.7,  0.5, sat: 0,    sugars: 0.9, fibre: 2.8,  salt: 0.05,
                                    units: ["bunch": 30, "handful": 15])
        d["ginger"]         = .init( 80,  1.8, 18.0,  0.8, sat: 0.2,  sugars: 1.7, fibre: 2.0,  salt: 0.02,
                                    units: ["piece": 10, "inch": 10, "slice": 5])
        d["bay"]            = .init(313,  7.6, 75.0,  8.4, sat: 2.3,  sugars: 0,   fibre: 26.3, salt: 0.08,
                                    units: ["piece": 0.5, "leaf": 0.5])
        d["vanilla"]        = .init(288,  0.1, 13.0, 0.06, sat: 0,    sugars: 12.6, fibre: 0,   salt: 0.02,
                                    gPerMl: 0.88)

        // MARK: Baking
        d["baking powder"]  = .init(100,  0.0, 28.0,  0.0, sat: 0,    sugars: 0,   fibre: 0,    salt: 15.0,
                                    gPerMl: 0.72)
        d["baking soda"]    = .init(  0,  0.0,  0.0,  0.0, sat: 0,    sugars: 0,   fibre: 0,    salt: 28.5,
                                    gPerMl: 0.97)
        d["yeast"]          = .init(325, 40.0, 41.0,  7.6, sat: 0.9,  sugars: 0,   fibre: 26.9, salt: 0.04,
                                    gPerMl: 0.8)
        d["chocolate"]      = .init(546,  4.9, 60.0, 31.0, sat: 19.0, sugars: 48.0, fibre: 7.0, salt: 0.04,
                                    units: ["piece": 5, "chip": 5])
        d["dark chocolate"] = .init(546,  4.9, 60.0, 31.0, sat: 19.0, sugars: 48.0, fibre: 7.0, salt: 0.04)
        d["milk chocolate"] = .init(535,  7.7, 59.0, 30.0, sat: 18.0, sugars: 55.0, fibre: 3.4, salt: 0.1)
        d["cocoa powder"]   = .init(228, 19.6, 58.0, 13.7, sat: 8.1,  sugars: 2.0, fibre: 33.2, salt: 0.02,
                                    gPerMl: 0.52)
        d["cocoa"]          = .init(228, 19.6, 58.0, 13.7, sat: 8.1,  sugars: 2.0, fibre: 33.2, salt: 0.02,
                                    gPerMl: 0.52)
        d["cornstarch"]     = .init(381,  0.3, 91.0,  0.1, gPerMl: 0.6)
        d["cornflour"]      = .init(381,  0.3, 91.0,  0.1, gPerMl: 0.6)

        return d
    }()
}
