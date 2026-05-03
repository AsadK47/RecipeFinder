
import Foundation

enum AppError: LocalizedError {
    case saveFailed(details: String)
    case loadFailed(details: String)
    case deleteFailed(details: String)
    case duplicateEntry
    case notFound
    
    case invalidCredentials
    case weakPassword(reason: String)
    case invalidEmail
    case userAlreadyExists
    case authenticationFailed
    case sessionExpired
    
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
            
        case .invalidCredentials:
            return "Invalid email or password"
        case .weakPassword(let reason):
            return "Password is too weak: \(reason)"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .userAlreadyExists:
            return "An account with this email already exists"
        case .authenticationFailed:
            return "Authentication failed. Please try again"
        case .sessionExpired:
            return "Your session has expired. Please sign in again"
            
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
        case .weakPassword:
            return "Use at least 8 characters with numbers and letters"
        case .invalidEmail:
            return "Enter email in format: name@example.com"
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
    
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    static func validatePassword(_ password: String) throws {
        guard password.count >= 8 else {
            throw AppError.weakPassword(reason: "Must be at least 8 characters")
        }
        
        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:',.<>?/~`")
        let hasSpecialChar = password.rangeOfCharacter(from: specialCharacters) != nil
        
        guard hasUppercase && hasLowercase else {
            throw AppError.weakPassword(reason: "Must contain uppercase and lowercase letters")
        }
        
        guard hasNumber else {
            throw AppError.weakPassword(reason: "Must contain at least one number")
        }
        
        guard hasSpecialChar else {
            throw AppError.weakPassword(reason: "Must contain at least one special character (!@#$%^&* etc.)")
        }
    }
    
    static func validateRecipeName(_ name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
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
        let trimmed = quantity.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AppError.emptyField(field: field)
        }
        
        if let value = parseFraction(trimmed) {
            return value
        }
        
        guard let value = Double(trimmed), value > 0 else {
            throw AppError.invalidFormat(field: field)
        }
        
        return value
    }
    
    private static func parseFraction(_ string: String) -> Double? {
        let components = string.split(separator: " ")
        
        if components.count == 2 {
            guard let whole = Double(components[0]) else { return nil }
            guard let fraction = parseSingleFraction(String(components[1])) else { return nil }
            return whole + fraction
        } else if components.count == 1 && string.contains("/") {
            return parseSingleFraction(string)
        }
        
        return nil
    }
    
    private static func parseSingleFraction(_ string: String) -> Double? {
        let parts = string.split(separator: "/")
        guard parts.count == 2,
              let numerator = Double(parts[0]),
              let denominator = Double(parts[1]),
              denominator != 0 else {
            return nil
        }
        return numerator / denominator
    }
}
