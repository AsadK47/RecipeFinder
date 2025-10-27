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
    static func convert(value: Double, unit: String, to system: MeasurementSystem) -> (quantity: Double, unit: String) {
        let unitType = getUnitType(unit)
        
        switch unitType {
        case .weight:
            return convertWeightToSystem(value: value, unit: unit, system: system)
        case .volume:
            return convertVolumeToSystem(value: value, unit: unit, system: system)
        case .none:
            return (value, unit)
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
