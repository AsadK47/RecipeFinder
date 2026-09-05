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
        let normalizedFrom = fromUnit.lowercased().trimmingCharacters(in: .whitespaces)
        let normalizedTo = toUnit.lowercased().trimmingCharacters(in: .whitespaces)
        
        var grams: Double = 0
        
        switch normalizedFrom {
        case "g", "grams", "gram":
            grams = value
        case "kg", "kilograms", "kilogram":
            grams = value * Weight.gramsPerKg
        case "lbs", "lb", "pounds", "pound":
            grams = value * Weight.gramsPerPound
        case "oz", "ounces", "ounce":
            grams = value * Weight.gramsPerOunce
        default:
            return value
        }
        
        switch normalizedTo {
        case "g", "grams", "gram":
            return grams
        case "kg", "kilograms", "kilogram":
            return grams / Weight.gramsPerKg
        case "lbs", "lb", "pounds", "pound":
            return grams / Weight.gramsPerPound
        case "oz", "ounces", "ounce":
            return grams / Weight.gramsPerOunce
        default:
            return value
        }
    }
    
    static func convertVolume(value: Double, from fromUnit: String, to toUnit: String) -> Double {
        let normalizedFrom = fromUnit.lowercased().trimmingCharacters(in: .whitespaces)
        let normalizedTo = toUnit.lowercased().trimmingCharacters(in: .whitespaces)
        
        var ml: Double = 0
        
        switch normalizedFrom {
        case "ml", "milliliters", "milliliter":
            ml = value
        case "cl", "centiliters", "centiliter":
            ml = value * Volume.mlPerCL
        case "dl", "deciliters", "deciliter":
            ml = value * Volume.mlPerDL
        case "l", "liters", "liter":
            ml = value * Volume.mlPerL
        case "cup", "cups":
            ml = value * Volume.mlPerCup
        case "tbsp", "tablespoon", "tablespoons":
            ml = value * Volume.mlPerTbsp
        case "tsp", "teaspoon", "teaspoons":
            ml = value * Volume.mlPerTsp
        case "fl oz", "fluid ounce", "fluid ounces":
            ml = value * Volume.mlPerFlOz
        case "pt", "pint", "pints":
            ml = value * Volume.mlPerPint
        case "qt", "quart", "quarts":
            ml = value * Volume.mlPerQuart
        case "gal", "gallon", "gallons":
            ml = value * Volume.mlPerGallon
        default:
            return value
        }
        
        switch normalizedTo {
        case "ml", "milliliters", "milliliter":
            return ml
        case "cl", "centiliters", "centiliter":
            return ml / Volume.mlPerCL
        case "dl", "deciliters", "deciliter":
            return ml / Volume.mlPerDL
        case "l", "liters", "liter":
            return ml / Volume.mlPerL
        case "cup", "cups":
            return ml / Volume.mlPerCup
        case "tbsp", "tablespoon", "tablespoons":
            return ml / Volume.mlPerTbsp
        case "tsp", "teaspoon", "teaspoons":
            return ml / Volume.mlPerTsp
        case "fl oz", "fluid ounce", "fluid ounces":
            return ml / Volume.mlPerFlOz
        case "pt", "pint", "pints":
            return ml / Volume.mlPerPint
        case "qt", "quart", "quarts":
            return ml / Volume.mlPerQuart
        case "gal", "gallon", "gallons":
            return ml / Volume.mlPerGallon
        default:
            return value
        }
    }
    
    static func getUnitType(_ unit: String) -> UnitType {
        let normalized = unit.lowercased().trimmingCharacters(in: .whitespaces)
        
        switch normalized {
        case "g", "grams", "gram", "kg", "kilograms", "kilogram",
             "lbs", "lb", "pounds", "pound", "oz", "ounces", "ounce":
            return .weight
            
        case "ml", "milliliters", "milliliter",
             "cl", "centiliters", "centiliter",
             "dl", "deciliters", "deciliter",
             "l", "liters", "liter",
             "cup", "cups", "tbsp", "tablespoon", "tablespoons",
             "tsp", "teaspoon", "teaspoons", "fl oz", "fluid ounce", "fluid ounces",
             "pt", "pint", "pints", "qt", "quart", "quarts", "gal", "gallon", "gallons":
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
        
        switch unitType {
        case .weight:
            return convertWeightToSystem(value: value, unit: unit, system: system)
        case .volume:
            if let name = ingredientName, isSolidIngredient(name) {
                return convertVolumeToWeightForSolids(value: value, unit: unit, system: system, ingredientName: name)
            } else {
                return convertVolumeToSystem(value: value, unit: unit, system: system)
            }
        case .none:
            return (value, unit)
        }
    }
    
    private static func isSolidIngredient(_ ingredientName: String) -> Bool {
        let nameWords = IngredientWordMatcher.words(in: ingredientName)

        let liquids = ["oil", "water", "milk", "cream", "stock", "broth", "juice",
                      "sauce", "vinegar", "wine", "soy sauce", "coconut milk", "honey",
                      "syrup", "extract", "liquid", "melted"]

        for liquid in liquids where IngredientWordMatcher.matches(textWords: nameWords, keyword: liquid) {
            return false
        }

        let spices = ["cumin", "coriander", "turmeric", "paprika", "chili", "chilli",
                     "cinnamon", "nutmeg", "clove", "cardamom", "pepper", "ginger",
                     "garlic", "onion", "fennel", "mustard", "fenugreek", "bay leaf",
                     "oregano", "basil", "thyme", "rosemary", "parsley", "mint",
                     "sage", "tarragon", "dill", "cilantro", "cayenne", "allspice",
                     "saffron", "sumac", "za'atar", "curry", "masala", "garam",
                     "star anise", "peppercorn", "sesame", "poppy", "caraway"]

        let dryIngredients = ["flour", "sugar", "salt", "rice", "pasta", "oats",
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
        let normalized = unit.lowercased().trimmingCharacters(in: .whitespaces)

        let densityMap: [String: (tsp: Double, tbsp: Double, cup: Double)] = [
            "salt": (tsp: 6, tbsp: 18, cup: 288),
            "sugar": (tsp: 4, tbsp: 12.5, cup: 200),
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
        
        // Whole-word match, most-specific (longest) keyword first, so a multi-word
        // name resolves deterministically instead of depending on Dictionary order
        // (e.g. "garlic powder" wins over a bare "garlic" were both present).
        let orderedDensities = densityMap.sorted { lhs, rhs in
            let lWords = lhs.key.split(separator: " ").count
            let rWords = rhs.key.split(separator: " ").count
            return lWords != rWords ? lWords > rWords : lhs.key < rhs.key
        }

        for (ingredient, densities) in orderedDensities
        where IngredientWordMatcher.matches(textWords: nameWords, keyword: ingredient) {
            switch normalized {
            case "tsp", "teaspoon", "teaspoons":
                return densities.tsp
            case "tbsp", "tablespoon", "tablespoons":
                return densities.tbsp
            case "cup", "cups":
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
        let normalized = unit.lowercased().trimmingCharacters(in: .whitespaces)
        
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
            case "tsp", "teaspoon", "teaspoons":
                grams = value * SolidDensity.gramsPerTsp
            case "tbsp", "tablespoon", "tablespoons":
                grams = value * SolidDensity.gramsPerTbsp
            case "cup", "cups":
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
        let normalized = unit.lowercased().trimmingCharacters(in: .whitespaces)
        
        switch system {
        case .metric:
            if ["g", "grams", "gram", "kg", "kilograms", "kilogram"].contains(normalized) {
                return (value, unit)
            }
            let grams = convertWeight(value: value, from: unit, to: "g")
            if grams >= Weight.gramsPerKg {
                return (grams / Weight.gramsPerKg, "kg")
            } else {
                return (grams, "g")
            }
            
        case .imperial:
            if ["lbs", "lb", "pounds", "pound", "oz", "ounces", "ounce"].contains(normalized) {
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
        let normalized = unit.lowercased().trimmingCharacters(in: .whitespaces)
        
        switch system {
        case .metric:
            if ["ml", "milliliters", "milliliter",
                "cl", "centiliters", "centiliter",
                "dl", "deciliters", "deciliter",
                "l", "liters", "liter"].contains(normalized) {
                return (value, unit)
            }
            let ml = convertVolume(value: value, from: unit, to: "ml")
            if ml >= Volume.mlPerL {
                return (ml / Volume.mlPerL, "l")
            } else {
                return (ml, "ml")
            }
            
        case .imperial:
            if ["cup", "cups", "tbsp", "tablespoon", "tablespoons",
                "tsp", "teaspoon", "teaspoons", "fl oz", "fluid ounce", "fluid ounces",
                "pt", "pint", "pints", "qt", "quart", "quarts", "gal", "gallon", "gallons"].contains(normalized) {
                return (value, unit)
            }
            let ml = convertVolume(value: value, from: unit, to: "ml")
            
            let cups = ml / Volume.mlPerCup
            if cups >= 1 {
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
