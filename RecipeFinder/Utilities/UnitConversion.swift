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
    
    // MARK: - Weight Conversions
    static func convertWeight(value: Double, from fromUnit: String, to toUnit: String) -> Double {
        let normalizedFrom = fromUnit.lowercased().trimmingCharacters(in: .whitespaces)
        let normalizedTo = toUnit.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Convert to grams first (base unit)
        var grams: Double = 0
        
        // From conversions
        switch normalizedFrom {
        case "g", "grams", "gram":
            grams = value
        case "kg", "kilograms", "kilogram":
            grams = value * 1000
        case "lbs", "lb", "pounds", "pound":
            grams = value * 453.592
        case "oz", "ounces", "ounce":
            grams = value * 28.3495
        default:
            return value // No conversion needed
        }
        
        // To conversions
        switch normalizedTo {
        case "g", "grams", "gram":
            return grams
        case "kg", "kilograms", "kilogram":
            return grams / 1000
        case "lbs", "lb", "pounds", "pound":
            return grams / 453.592
        case "oz", "ounces", "ounce":
            return grams / 28.3495
        default:
            return value
        }
    }
    
    // MARK: - Volume Conversions
    static func convertVolume(value: Double, from fromUnit: String, to toUnit: String) -> Double {
        let normalizedFrom = fromUnit.lowercased().trimmingCharacters(in: .whitespaces)
        let normalizedTo = toUnit.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Convert to ml first (base unit)
        var ml: Double = 0
        
        // From conversions
        switch normalizedFrom {
        case "ml", "milliliters", "milliliter":
            ml = value
        case "l", "liters", "liter":
            ml = value * 1000
        case "cup", "cups":
            ml = value * 236.588
        case "tbsp", "tablespoon", "tablespoons":
            ml = value * 14.7868
        case "tsp", "teaspoon", "teaspoons":
            ml = value * 4.92892
        case "fl oz", "fluid ounce", "fluid ounces":
            ml = value * 29.5735
        default:
            return value
        }
        
        // To conversions
        switch normalizedTo {
        case "ml", "milliliters", "milliliter":
            return ml
        case "l", "liters", "liter":
            return ml / 1000
        case "cup", "cups":
            return ml / 236.588
        case "tbsp", "tablespoon", "tablespoons":
            return ml / 14.7868
        case "tsp", "teaspoon", "teaspoons":
            return ml / 4.92892
        case "fl oz", "fluid ounce", "fluid ounces":
            return ml / 29.5735
        default:
            return value
        }
    }
    
    // MARK: - Unit Type Detection
    static func getUnitType(_ unit: String) -> UnitType {
        let normalized = unit.lowercased().trimmingCharacters(in: .whitespaces)
        
        switch normalized {
        // Weight units
        case "g", "grams", "gram", "kg", "kilograms", "kilogram",
             "lbs", "lb", "pounds", "pound", "oz", "ounces", "ounce":
            return .weight
            
        // Volume units
        case "ml", "milliliters", "milliliter", "l", "liters", "liter",
             "cup", "cups", "tbsp", "tablespoon", "tablespoons",
             "tsp", "teaspoon", "teaspoons", "fl oz", "fluid ounce", "fluid ounces":
            return .volume
            
        // No conversion needed
        default:
            return .none
        }
    }
    
    // MARK: - Smart Conversion
    static func convert(value: Double, unit: String, to system: MeasurementSystem, ingredientName: String? = nil) -> (quantity: Double, unit: String) {
        let unitType = getUnitType(unit)
        
        switch unitType {
        case .weight:
            return convertWeightToSystem(value: value, unit: unit, system: system)
        case .volume:
            // If it's a volume unit (tsp, tbsp, cup), check if the ingredient is a solid
            if let name = ingredientName, isSolidIngredient(name) {
                // Convert volume to weight for solid ingredients (spices, flour, sugar, etc.)
                return convertVolumeToWeightForSolids(value: value, unit: unit, system: system, ingredientName: name)
            } else {
                // Treat as liquid - normal volume conversion
                return convertVolumeToSystem(value: value, unit: unit, system: system)
            }
        case .none:
            return (value, unit)
        }
    }
    
    // MARK: - Solid Ingredient Detection
    private static func isSolidIngredient(_ ingredientName: String) -> Bool {
        let name = ingredientName.lowercased()
        
        // Liquids (check first to avoid false positives)
        let liquids = ["oil", "water", "milk", "cream", "stock", "broth", "juice",
                      "sauce", "vinegar", "wine", "soy sauce", "coconut milk", "honey",
                      "syrup", "extract", "liquid", "melted"]
        
        for liquid in liquids {
            if name.contains(liquid) {
                return false
            }
        }
        
        // Common spices and dry herbs
        let spices = ["cumin", "coriander", "turmeric", "paprika", "chili", "chilli", 
                     "cinnamon", "nutmeg", "clove", "cardamom", "pepper", "ginger",
                     "garlic", "onion", "fennel", "mustard", "fenugreek", "bay leaf",
                     "oregano", "basil", "thyme", "rosemary", "parsley", "mint",
                     "sage", "tarragon", "dill", "cilantro", "cayenne", "allspice",
                     "saffron", "sumac", "za'atar", "curry", "masala", "garam",
                     "star anise", "peppercorn", "sesame", "poppy", "caraway"]
        
        // Dry ingredients (baking, grains, etc.)
        let dryIngredients = ["flour", "sugar", "salt", "rice", "pasta", "oats",
                             "breadcrumb", "cornstarch", "cornflour", "baking powder", 
                             "baking soda", "yeast", "cocoa", "coffee", "tea", "seed",
                             "nut", "almond", "walnut", "cashew", "peanut", "pecan",
                             "lentil", "bean", "chickpea", "grain", "quinoa", "couscous",
                             "dried", "powder", "ground", "crushed", "flake", "granule"]
        
        // Check if any keyword matches
        for keyword in spices + dryIngredients {
            if name.contains(keyword) {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Specific Density Conversions
    private static func getDensityConversion(ingredientName: String, unit: String) -> Double? {
        let name = ingredientName.lowercased()
        let normalized = unit.lowercased().trimmingCharacters(in: .whitespaces)
        
        // More accurate conversions for common ingredients (grams per tsp/tbsp/cup)
        let densityMap: [String: (tsp: Double, tbsp: Double, cup: Double)] = [
            // Spices (grams)
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
            
            // Common baking ingredients
            "cocoa": (tsp: 1.4, tbsp: 4.3, cup: 68),
            "baking powder": (tsp: 4.6, tbsp: 14, cup: 224),
            "baking soda": (tsp: 4.6, tbsp: 14, cup: 224),
            "cornstarch": (tsp: 2.5, tbsp: 8, cup: 128),
            "yeast": (tsp: 3.1, tbsp: 9.3, cup: 150),
            
            // Seeds and nuts
            "sesame seed": (tsp: 3, tbsp: 9, cup: 144),
            "poppy seed": (tsp: 3.3, tbsp: 10, cup: 160),
        ]
        
        // Find matching density
        for (ingredient, densities) in densityMap {
            if name.contains(ingredient) {
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
        }
        
        return nil
    }
    
    // MARK: - Volume to Weight Conversion for Solids
    private static func convertVolumeToWeightForSolids(value: Double, unit: String, system: MeasurementSystem, ingredientName: String) -> (quantity: Double, unit: String) {
        let normalized = unit.lowercased().trimmingCharacters(in: .whitespaces)
        
        // For imperial system, keep volume units (tsp/tbsp) as-is for spices/dry ingredients
        // Only convert to grams for metric system
        switch system {
        case .imperial:
            // Keep the original volume unit for imperial (tsp, tbsp, cups are standard in US cooking)
            return (value, unit)
            
        case .metric:
            // Convert volume to weight (grams) for metric system
            
            // Try to get specific density conversion first
            if let specificGrams = getDensityConversion(ingredientName: ingredientName, unit: unit) {
                let grams = value * specificGrams
                
                if grams >= 1000 {
                    return (grams / 1000, "kg")
                } else {
                    return (grams, "g")
                }
            }
            
            // Fall back to generic density conversions
            var grams: Double = 0
            
            switch normalized {
            case "tsp", "teaspoon", "teaspoons":
                grams = value * 5 // Generic: 1 tsp ≈ 5g
            case "tbsp", "tablespoon", "tablespoons":
                grams = value * 15 // Generic: 1 tbsp ≈ 15g
            case "cup", "cups":
                grams = value * 125 // Generic: 1 cup ≈ 125g (varies widely)
            default:
                // If it's already a weight unit or unknown, fall back to volume conversion
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
            // If already metric, return as is
            if ["g", "grams", "gram", "kg", "kilograms", "kilogram"].contains(normalized) {
                return (value, unit)
            }
            // Convert to grams or kg
            let grams = convertWeight(value: value, from: unit, to: "g")
            if grams >= 1000 {
                return (grams / 1000, "kg")
            } else {
                return (grams, "g")
            }
            
        case .imperial:
            // If already imperial, return as is
            if ["lbs", "lb", "pounds", "pound", "oz", "ounces", "ounce"].contains(normalized) {
                return (value, unit)
            }
            // Convert to oz or lbs
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
            // If already metric, return as is
            if ["ml", "milliliters", "milliliter", "l", "liters", "liter"].contains(normalized) {
                return (value, unit)
            }
            // Convert to ml or l
            let ml = convertVolume(value: value, from: unit, to: "ml")
            if ml >= 1000 {
                return (ml / 1000, "l")
            } else {
                return (ml, "ml")
            }
            
        case .imperial:
            // If already imperial, return as is
            if ["cup", "cups", "tbsp", "tablespoon", "tablespoons",
                "tsp", "teaspoon", "teaspoons", "fl oz", "fluid ounce", "fluid ounces"].contains(normalized) {
                return (value, unit)
            }
            // Keep common imperial units
            let ml = convertVolume(value: value, from: unit, to: "ml")
            
            // Prioritize common cooking measurements
            let cups = ml / 236.588
            if cups >= 1 {
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
