
import Foundation

enum AppError: LocalizedError {
    case saveFailed(details: String)
    case loadFailed(details: String)
    case deleteFailed(details: String)
    case duplicateEntry
    case notFound
    
    case invalidRecipeName
    case missingIngredients
    case missingInstructions
    case invalidServings
    case invalidCookTime
    
    case networkUnavailable
    case importFailed(reason: String)
    case invalidURL
    case parsingFailed
    
    case emptyField(field: String)
    case invalidFormat(field: String)
    case outOfRange(field: String, min: Int, max: Int)
    
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let details):
            return "Failed to save: \(details)"
        case .loadFailed(let details):
            return "Failed to load data: \(details)"
        case .deleteFailed(let details):
            return "Failed to delete: \(details)"
        case .duplicateEntry:
            return "This item already exists"
        case .notFound:
            return "Item not found"
            
        case .invalidRecipeName:
            return "Recipe name must be at least 3 characters"
        case .missingIngredients:
            return "Please add at least one ingredient"
        case .missingInstructions:
            return "Please add cooking instructions"
        case .invalidServings:
            return "Servings must be between 1 and 50"
        case .invalidCookTime:
            return "Please enter a valid cooking time"
            
        case .networkUnavailable:
            return "No internet connection. Please check your network and try again"
        case .importFailed(let reason):
            return "Import failed: \(reason)"
        case .invalidURL:
            return "Please enter a valid recipe URL"
        case .parsingFailed:
            return "Could not parse recipe from this website"
            
        case .emptyField(let field):
            return "\(field) cannot be empty"
        case .invalidFormat(let field):
            return "\(field) format is invalid"
        case .outOfRange(let field, let min, let max):
            return "\(field) must be between \(min) and \(max)"
            
        case .unknown(let error):
            return "An error occurred: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again"
        case .invalidRecipeName:
            return "Enter a descriptive recipe name"
        case .missingIngredients:
            return "Add ingredients to save this recipe"
        case .importFailed, .parsingFailed:
            return "Try copying the recipe manually or use a different website"
        default:
            return nil
        }
    }
}

struct Validator {
    
    static func validateRecipeName(_ name: String) throws {
        let trimmed = name.trimmed
        guard !trimmed.isEmpty else {
            throw AppError.emptyField(field: "Recipe name")
        }
        guard trimmed.count >= 3 else {
            throw AppError.invalidRecipeName
        }
    }
    
    static func validateServings(_ servings: Int) throws {
        guard servings >= 1 && servings <= 50 else {
            throw AppError.invalidServings
        }
    }
    
    static func validateQuantity(_ quantity: String, field: String) throws -> Double {
        let trimmed = quantity.trimmed
        guard !trimmed.isEmpty else {
            throw AppError.emptyField(field: field)
        }
        
        // Same parser as ingredient lines, so "½", "1½" and "1 1/2" are accepted everywhere alike.
        let normalised = IngredientLineParser.normaliseUnicodeFractions(trimmed)
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let value = IngredientLineParser.parseQuantity(normalised)
        guard value > 0 else {
            throw AppError.invalidFormat(field: field)
        }
        return value
    }
}
