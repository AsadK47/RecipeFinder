import Foundation

enum MeasurementSystem: String, CaseIterable, Codable {
    case metric = "Metric"
    case imperial = "Imperial"
    
    var icon: String {
        switch self {
        case .metric: return "scalemass"
        case .imperial: return "ruler"
        }
    }
}

struct UnitConversion {

    /// The one place unit spellings live. Every unit comparison in the app goes through `canonicalUnit(_:)`, so
    /// "litres", "Tbs" and "lb" behave like "l", "tbsp" and "lbs" everywhere (parsing, conversion, nutrition, merging).
    /// Synonym → canonical token; abbreviations and spelled-out forms collapse to one, count units keep a literal singular.
    static let unitSynonyms: [String: String] = [
        "teaspoon": "tsp", "teaspoons": "tsp", "tsp": "tsp",
        "tablespoon": "tbsp", "tablespoons": "tbsp", "tbsp": "tbsp", "tbs": "tbsp",
        "cup": "cup", "cups": "cup",
        "milliliter": "ml", "milliliters": "ml", "millilitre": "ml", "millilitres": "ml", "ml": "ml",
        "liter": "l", "liters": "l", "litre": "l", "litres": "l", "l": "l",
        "deciliter": "dl", "deciliters": "dl", "dl": "dl",
        "centiliter": "cl", "centiliters": "cl", "cl": "cl",
        "fl oz": "fl oz", "fluid ounce": "fl oz", "fluid ounces": "fl oz",
        "pint": "pt", "pints": "pt", "pt": "pt",
        "quart": "qt", "quarts": "qt", "qt": "qt",
        "gallon": "gal", "gallons": "gal", "gal": "gal",
        "gram": "g", "grams": "g", "gramme": "g", "grammes": "g", "g": "g",
        "kilogram": "kg", "kilograms": "kg", "kg": "kg",
        "ounce": "oz", "ounces": "oz", "oz": "oz",
        "pound": "lbs", "pounds": "lbs", "lb": "lbs", "lbs": "lbs",
        "clove": "clove", "cloves": "clove",
        "piece": "piece", "pieces": "piece",
        "slice": "slice", "slices": "slice",
        "pinch": "pinch", "pinches": "pinch",
        "dash": "dash", "dashes": "dash",
        "stick": "stick", "sticks": "stick",
        "can": "can", "cans": "can", "tin": "can", "tins": "can",
        "package": "package", "packages": "package", "pkg": "package",
        "bunch": "bunch", "bunches": "bunch",
        "sprig": "sprig", "sprigs": "sprig",
        "handful": "handful", "handfuls": "handful",
        "inch": "inch", "inches": "inch"
    ]

    /// Canonical token for any spelling ("Tablespoons" → "tbsp", "lb" → "lbs"); unknown units come back lowercased/trimmed.
    static func canonicalUnit(_ unit: String) -> String {
        let key = unit.trimmed.lowercased()
        return unitSynonyms[key] ?? key
    }

    enum Weight {
        static let gramsPerKg     = 1000.0
        static let gramsPerPound  = 453.59237
        static let gramsPerOunce  = 28.349523125
        static let ouncesPerPound = 16.0
    }

    enum Volume {
        static let mlPerCL     = 10.0
        static let mlPerDL     = 100.0
        static let mlPerL      = 1000.0
        static let mlPerCup    = 236.5882365
        static let mlPerTbsp   = 14.78676478125
        static let mlPerTsp    = 4.92892159375
        static let mlPerFlOz   = 29.5735295625
        static let mlPerPint   = 473.176473
        static let mlPerQuart  = 946.352946
        static let mlPerGallon = 3785.411784
    }

    enum SolidDensity {
        static let gramsPerTsp  = 5.0
        static let gramsPerTbsp = 15.0
        static let gramsPerCup  = 125.0
    }

    static func convertWeight(value: Double, from fromUnit: String, to toUnit: String) -> Double {
        let normalizedFrom = canonicalUnit(fromUnit)
        let normalizedTo = canonicalUnit(toUnit)
        
        var grams: Double = 0
        
        switch normalizedFrom {
        case "g":
            grams = value
        case "kg":
            grams = value * Weight.gramsPerKg
        case "lbs":
            grams = value * Weight.gramsPerPound
        case "oz":
            grams = value * Weight.gramsPerOunce
        default:
            return value
        }
        
        switch normalizedTo {
        case "g":
            return grams
        case "kg":
            return grams / Weight.gramsPerKg
        case "lbs":
            return grams / Weight.gramsPerPound
        case "oz":
            return grams / Weight.gramsPerOunce
        default:
            return value
        }
    }
    
    static func convertVolume(value: Double, from fromUnit: String, to toUnit: String) -> Double {
        let normalizedFrom = canonicalUnit(fromUnit)
        let normalizedTo = canonicalUnit(toUnit)
        
        var ml: Double = 0
        
        switch normalizedFrom {
        case "ml":
            ml = value
        case "cl":
            ml = value * Volume.mlPerCL
        case "dl":
            ml = value * Volume.mlPerDL
        case "l":
            ml = value * Volume.mlPerL
        case "cup":
            ml = value * Volume.mlPerCup
        case "tbsp":
            ml = value * Volume.mlPerTbsp
        case "tsp":
            ml = value * Volume.mlPerTsp
        case "fl oz":
            ml = value * Volume.mlPerFlOz
        case "pt":
            ml = value * Volume.mlPerPint
        case "qt":
            ml = value * Volume.mlPerQuart
        case "gal":
            ml = value * Volume.mlPerGallon
        default:
            return value
        }
        
        switch normalizedTo {
        case "ml":
            return ml
        case "cl":
            return ml / Volume.mlPerCL
        case "dl":
            return ml / Volume.mlPerDL
        case "l":
            return ml / Volume.mlPerL
        case "cup":
            return ml / Volume.mlPerCup
        case "tbsp":
            return ml / Volume.mlPerTbsp
        case "tsp":
            return ml / Volume.mlPerTsp
        case "fl oz":
            return ml / Volume.mlPerFlOz
        case "pt":
            return ml / Volume.mlPerPint
        case "qt":
            return ml / Volume.mlPerQuart
        case "gal":
            return ml / Volume.mlPerGallon
        default:
            return value
        }
    }
    
    static func getUnitType(_ unit: String) -> UnitType {
        let normalized = canonicalUnit(unit)
        
        switch normalized {
        case "g", "kg",
             "lbs", "oz":
            return .weight
            
        case "ml",
             "cl",
             "dl",
             "l",
             "cup", "tbsp",
             "tsp", "fl oz",
             "pt", "qt", "gal":
            return .volume
            
        default:
            return .none
        }
    }
    
    static func convert(
        value: Double,
        unit: String,
        to system: MeasurementSystem,
        ingredientName: String? = nil
    ) -> (quantity: Double, unit: String) {
        let unitType = getUnitType(unit)
        let normalizedUnit = canonicalUnit(unit)
        // Spoons and pinches are the same measure in both systems. Converting them produced "½ g" of cumin,
        // "2½ ml" of lemon juice and inconsistent results (1 tbsp garlic → 15 g, but ginger stayed in tbsp).
        let spoonUnits: Set<String> = ["tsp", "tbsp", "pinch"]
        if spoonUnits.contains(normalizedUnit) { return (value, unit) }
        
        switch unitType {
        case .weight:
            return tidy(convertWeightToSystem(value: value, unit: unit, system: system))
        case .volume:
            guard let name = ingredientName else {
                return tidy(convertVolumeToSystem(value: value, unit: unit, system: system))
            }
            // Only convert what we can convert honestly: liquids by volume, known-density solids by weight.
            // Anything else ("175 ml chana dal", "475 ml chopped cabbage", "22 g fresh coriander") keeps its cups.
            if isLiquidIngredient(name) {
                return tidy(convertVolumeToSystem(value: value, unit: unit, system: system))
            }
            if system == .metric, isSolidIngredient(name), !isFreshHerb(name),
               getDensityConversion(ingredientName: name, unit: unit) != nil {
                return tidy(convertVolumeToWeightForSolids(value: value, unit: unit, system: system, ingredientName: name))
            }
            return (value, unit)
        case .none:
            return (value, unit)
        }
    }
    
    private static let liquidKeywords = ["oil", "water", "milk", "cream", "stock", "broth", "juice",
                                         "sauce", "vinegar", "wine", "soy sauce", "coconut milk", "honey",
                                         "syrup", "extract", "liquid", "melted"]

    private static func isLiquidIngredient(_ ingredientName: String) -> Bool {
        let words = IngredientWordMatcher.words(in: ingredientName)
        return liquidKeywords.contains { IngredientWordMatcher.matches(textWords: words, keyword: $0) }
    }

    /// Fresh herbs/leaves share names with dried spices ("coriander") but weigh a fraction as much.
    private static func isFreshHerb(_ ingredientName: String) -> Bool {
        let words = IngredientWordMatcher.words(in: ingredientName)
        return ["fresh", "leaves", "leaf", "sprigs", "chopped"].contains { IngredientWordMatcher.matches(textWords: words, keyword: $0) }
    }

    /// Rounds converted amounts to what people actually measure: 945 ml → 950 ml, ⅞ oz → 1 oz, 16 oz → 1 lb,
    /// 14 tbsp → 1 cup.
    private static func tidy(_ result: (quantity: Double, unit: String)) -> (quantity: Double, unit: String) {
        let q = result.quantity
        func round(_ value: Double, to step: Double) -> Double { max(step, (value / step).rounded() * step) }
        switch result.unit {
        case "ml" where q >= 100: return (round(q, to: 10), "ml")
        case "ml" where q >= 20: return (round(q, to: 5), "ml")
        case "oz" where round(q, to: 0.5) >= 16: return (round(q / 16, to: 0.25), "lb")   // 450 g = 15.9 oz → 1 lb
        case "oz": return (round(q, to: 0.5), "oz")
        case "lb", "lbs": return (round(q, to: 0.25), "lb")   // "1 lbs" read oddly
        case "tbsp" where q >= 4: return (round(q / 16, to: 0.25), "cup")
        case "cup", "cups": return (round(q, to: 0.25), result.unit)
        default: return result
        }
    }

    private static func isSolidIngredient(_ ingredientName: String) -> Bool {
        let nameWords = IngredientWordMatcher.words(in: ingredientName)

        for liquid in liquidKeywords where IngredientWordMatcher.matches(textWords: nameWords, keyword: liquid) {
            return false
        }

        let spices = ["cumin", "coriander", "turmeric", "paprika", "chili", "chilli",
                     "cinnamon", "nutmeg", "clove", "cardamom", "pepper", "ginger",
                     "garlic", "onion", "fennel", "mustard", "fenugreek", "bay leaf",
                     "oregano", "basil", "thyme", "rosemary", "parsley", "mint",
                     "sage", "tarragon", "dill", "cilantro", "cayenne", "allspice",
                     "saffron", "sumac", "za'atar", "curry", "masala", "garam",
                     "star anise", "peppercorn", "sesame", "poppy", "caraway"]

        let dryIngredients = ["butter", "flour", "sugar", "salt", "rice", "pasta", "oats",
                             "breadcrumb", "cornstarch", "cornflour", "baking powder",
                             "baking soda", "yeast", "cocoa", "coffee", "tea", "seed",
                             "nut", "almond", "walnut", "cashew", "peanut", "pecan",
                             "lentil", "bean", "chickpea", "grain", "quinoa", "couscous",
                             "dried", "powder", "ground", "crushed", "flake", "granule"]

        for keyword in spices + dryIngredients where IngredientWordMatcher.matches(textWords: nameWords, keyword: keyword) {
            return true
        }

        return false
    }

    private static func getDensityConversion(ingredientName: String, unit: String) -> Double? {
        let nameWords = IngredientWordMatcher.words(in: ingredientName)
        let normalized = canonicalUnit(unit)

        let densityMap: [String: (tsp: Double, tbsp: Double, cup: Double)] = [
            "salt": (tsp: 6, tbsp: 18, cup: 288),
            "sugar": (tsp: 4, tbsp: 12.5, cup: 200),
            "butter": (tsp: 4.7, tbsp: 14, cup: 227),
            "flour": (tsp: 2.5, tbsp: 8, cup: 125),
            "cinnamon": (tsp: 2.6, tbsp: 8, cup: 128),
            "ginger": (tsp: 2, tbsp: 6, cup: 96),
            "garlic powder": (tsp: 3, tbsp: 9, cup: 144),
            "onion powder": (tsp: 2.4, tbsp: 7.2, cup: 115),
            "cumin": (tsp: 2.1, tbsp: 6.3, cup: 100),
            "coriander": (tsp: 1.8, tbsp: 5.4, cup: 86),
            "paprika": (tsp: 2.3, tbsp: 6.9, cup: 110),
            "turmeric": (tsp: 3, tbsp: 9, cup: 144),
            "cayenne": (tsp: 1.8, tbsp: 5.4, cup: 86),
            "black pepper": (tsp: 2.1, tbsp: 6.3, cup: 100),
            "chili powder": (tsp: 2.7, tbsp: 8.1, cup: 130),
            
            "cocoa": (tsp: 1.4, tbsp: 4.3, cup: 68),
            "baking powder": (tsp: 4.6, tbsp: 14, cup: 224),
            "baking soda": (tsp: 4.6, tbsp: 14, cup: 224),
            "cornstarch": (tsp: 2.5, tbsp: 8, cup: 128),
            "yeast": (tsp: 3.1, tbsp: 9.3, cup: 150),
            
            "sesame seed": (tsp: 3, tbsp: 9, cup: 144),
            "poppy seed": (tsp: 3.3, tbsp: 10, cup: 160)
        ]
        
        // Longest keyword first so multi-word names resolve deterministically, not by Dictionary order (e.g. "garlic powder" beats "garlic").
        let orderedDensities = densityMap.sorted { lhs, rhs in
            let lWords = lhs.key.split(separator: " ").count
            let rWords = rhs.key.split(separator: " ").count
            return lWords != rWords ? lWords > rWords : lhs.key < rhs.key
        }

        for (ingredient, densities) in orderedDensities
        where IngredientWordMatcher.matches(textWords: nameWords, keyword: ingredient) {
            switch normalized {
            case "tsp":
                return densities.tsp
            case "tbsp":
                return densities.tbsp
            case "cup":
                return densities.cup
            default:
                return nil
            }
        }

        return nil
    }
    
    private static func convertVolumeToWeightForSolids(
        value: Double,
        unit: String,
        system: MeasurementSystem,
        ingredientName: String
    ) -> (quantity: Double, unit: String) {
        let normalized = canonicalUnit(unit)
        
        switch system {
        case .imperial:
            return (value, unit)
            
        case .metric:
            
            if let specificGrams = getDensityConversion(ingredientName: ingredientName, unit: unit) {
                let grams = value * specificGrams
                
                if grams >= Weight.gramsPerKg {
                    return (grams / Weight.gramsPerKg, "kg")
                } else {
                    return (grams, "g")
                }
            }

            var grams: Double = 0

            switch normalized {
            case "tsp":
                grams = value * SolidDensity.gramsPerTsp
            case "tbsp":
                grams = value * SolidDensity.gramsPerTbsp
            case "cup":
                grams = value * SolidDensity.gramsPerCup
            default:
                return convertVolumeToSystem(value: value, unit: unit, system: system)
            }

            if grams >= Weight.gramsPerKg {
                return (grams / Weight.gramsPerKg, "kg")
            } else {
                return (grams, "g")
            }
        }
    }
    
    private static func convertWeightToSystem(value: Double, unit: String, system: MeasurementSystem) -> (quantity: Double, unit: String) {
        let normalized = canonicalUnit(unit)
        
        switch system {
        case .metric:
            if ["g", "kg"].contains(normalized) {
                return (value, unit)
            }
            let grams = convertWeight(value: value, from: unit, to: "g")
            if grams >= Weight.gramsPerKg {
                return (grams / Weight.gramsPerKg, "kg")
            } else {
                return (grams, "g")
            }
            
        case .imperial:
            if ["lbs", "oz"].contains(normalized) {
                return (value, unit)
            }
            let oz = convertWeight(value: value, from: unit, to: "oz")
            if oz >= Weight.ouncesPerPound {
                return (oz / Weight.ouncesPerPound, "lbs")
            } else {
                return (oz, "oz")
            }
        }
    }
    
    private static func convertVolumeToSystem(value: Double, unit: String, system: MeasurementSystem) -> (quantity: Double, unit: String) {
        let normalized = canonicalUnit(unit)
        
        switch system {
        case .metric:
            if ["ml",
                "cl",
                "dl",
                "l"].contains(normalized) {
                return (value, unit)
            }
            let ml = convertVolume(value: value, from: unit, to: "ml")
            if ml >= Volume.mlPerL {
                return (ml / Volume.mlPerL, "l")
            } else {
                return (ml, "ml")
            }
            
        case .imperial:
            if ["cup", "tbsp",
                "tsp", "fl oz",
                "pt", "qt", "gal"].contains(normalized) {
                return (value, unit)
            }
            let ml = convertVolume(value: value, from: unit, to: "ml")
            
            let cups = ml / Volume.mlPerCup
            if cups >= 1 {
                if cups >= 16 { return (cups / 16, "gal") }
                if cups >= 4 { return (cups / 4, "qt") }
                return (cups, "cup")
            }

            let tbsp = ml / Volume.mlPerTbsp
            if tbsp >= 1 {
                return (tbsp, "tbsp")
            }

            let tsp = ml / Volume.mlPerTsp
            return (tsp, "tsp")
        }
    }
}

enum UnitType {
    case weight
    case volume
    case none
}
