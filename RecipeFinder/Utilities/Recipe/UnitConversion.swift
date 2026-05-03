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
    
    static func convertWeight(value: Double, from fromUnit: String, to toUnit: String) -> Double {
        let normalizedFrom = fromUnit.lowercased().trimmingCharacters(in: .whitespaces)
        let normalizedTo = toUnit.lowercased().trimmingCharacters(in: .whitespaces)
        
        var grams: Double = 0
        
        switch normalizedFrom {
        case "g", "grams", "gram":
            grams = value
        case "kg", "kilograms", "kilogram":
            grams = value * 1000.0
        case "lbs", "lb", "pounds", "pound":
            grams = value * 453.59237
        case "oz", "ounces", "ounce":
            grams = value * 28.349523125
        default:
            return value
        }
        
        switch normalizedTo {
        case "g", "grams", "gram":
            return grams
        case "kg", "kilograms", "kilogram":
            return grams / 1000.0
        case "lbs", "lb", "pounds", "pound":
            return grams / 453.59237
        case "oz", "ounces", "ounce":
            return grams / 28.349523125
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
            ml = value * 10.0
        case "dl", "deciliters", "deciliter":
            ml = value * 100.0
        case "l", "liters", "liter":
            ml = value * 1000.0
        case "cup", "cups":
            ml = value * 236.5882365
        case "tbsp", "tablespoon", "tablespoons":
            ml = value * 14.78676478125
        case "tsp", "teaspoon", "teaspoons":
            ml = value * 4.92892159375
        case "fl oz", "fluid ounce", "fluid ounces":
            ml = value * 29.5735295625
        case "pt", "pint", "pints":
            ml = value * 473.176473
        case "qt", "quart", "quarts":
            ml = value * 946.352946
        case "gal", "gallon", "gallons":
            ml = value * 3785.411784
        default:
            return value
        }
        
        switch normalizedTo {
        case "ml", "milliliters", "milliliter":
            return ml
        case "cl", "centiliters", "centiliter":
            return ml / 10.0
        case "dl", "deciliters", "deciliter":
            return ml / 100.0
        case "l", "liters", "liter":
            return ml / 1000.0
        case "cup", "cups":
            return ml / 236.5882365
        case "tbsp", "tablespoon", "tablespoons":
            return ml / 14.78676478125
        case "tsp", "teaspoon", "teaspoons":
            return ml / 4.92892159375
        case "fl oz", "fluid ounce", "fluid ounces":
            return ml / 29.5735295625
        case "pt", "pint", "pints":
            return ml / 473.176473
        case "qt", "quart", "quarts":
            return ml / 946.352946
        case "gal", "gallon", "gallons":
            return ml / 3785.411784
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
        let name = ingredientName.lowercased()
        
        let liquids = ["oil", "water", "milk", "cream", "stock", "broth", "juice",
                      "sauce", "vinegar", "wine", "soy sauce", "coconut milk", "honey",
                      "syrup", "extract", "liquid", "melted"]
        
        for liquid in liquids where name.contains(liquid) {
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
        
        for keyword in spices + dryIngredients where name.contains(keyword) {
            return true
        }
        
        return false
    }
    
    private static func getDensityConversion(ingredientName: String, unit: String) -> Double? {
        let name = ingredientName.lowercased()
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
        
        for (ingredient, densities) in densityMap where name.contains(ingredient) {
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
                
                if grams >= 1000 {
                    return (grams / 1000, "kg")
                } else {
                    return (grams, "g")
                }
            }
            
            var grams: Double = 0
            
            switch normalized {
            case "tsp", "teaspoon", "teaspoons":
                grams = value * 5
            case "tbsp", "tablespoon", "tablespoons":
                grams = value * 15
            case "cup", "cups":
                grams = value * 125
            default:
                return convertVolumeToSystem(value: value, unit: unit, system: system)
            }
            
            if grams >= 1000 {
                return (grams / 1000, "kg")
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
            if grams >= 1000 {
                return (grams / 1000, "kg")
            } else {
                return (grams, "g")
            }
            
        case .imperial:
            if ["lbs", "lb", "pounds", "pound", "oz", "ounces", "ounce"].contains(normalized) {
                return (value, unit)
            }
            let oz = convertWeight(value: value, from: unit, to: "oz")
            if oz >= 16 {
                return (oz / 16, "lbs")
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
            if ml >= 1000 {
                return (ml / 1000, "l")
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
            
            let cups = ml / 236.588
            if cups >= 1 {
                if cups >= 4 { return (cups / 4, "qt") }
                return (cups, "cup")
            }
            
            let tbsp = ml / 14.7868
            if tbsp >= 1 {
                return (tbsp, "tbsp")
            }
            
            let tsp = ml / 4.92892
            return (tsp, "tsp")
        }
    }
}

enum UnitType {
    case weight
    case volume
    case none
}
