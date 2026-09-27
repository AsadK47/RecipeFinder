import Foundation
import UniformTypeIdentifiers

extension UTType {
    static let recipeFile = UTType(exportedAs: "com.recipefinder.recipe")
}

// MARK: - Wire format

/// Versioned JSON package for `.recipefinderrecipe` files; content fields only, personal data (rating, cookCount, isFavorite, local photos) excluded so the recipient starts fresh.
struct RecipePackage: Codable {
    let version: Int
    let name: String
    let category: String
    let difficulty: String
    let prepTime: String
    let cookingTime: String
    let baseServings: Int
    let ingredients: [PackagedIngredient]
    let prePrepInstructions: [String]
    let instructions: [String]
    let notes: String
    let cuisine: String?
    let tags: [String]
    let dietaryInfo: DietaryInfo
    /// Original source URL, if this recipe was imported from the web.
    let sourceURL: String?
    /// Hero image URL — only when it's an HTTP URL; sender's local file paths omitted.
    let imageURL: String?

    struct PackagedIngredient: Codable {
        let quantity: Double
        let unit: String
        let name: String
    }
}

// MARK: - Exporter

enum RecipeFileExporter {

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private static let decoder = JSONDecoder()

    /// Encodes `recipe` into a `RecipePackage` JSON payload.
    static func encode(_ recipe: RecipeModel) throws -> Data {
        let package = RecipePackage(
            version: 1,
            name: recipe.name,
            category: recipe.category,
            difficulty: recipe.difficulty,
            prepTime: recipe.prepTime,
            cookingTime: recipe.cookingTime,
            baseServings: recipe.baseServings,
            ingredients: recipe.ingredients.map {
                .init(quantity: $0.baseQuantity, unit: $0.unit, name: $0.name)
            },
            prePrepInstructions: recipe.prePrepInstructions,
            instructions: recipe.instructions,
            notes: recipe.notesForDisplay,
            cuisine: recipe.cuisine,
            tags: recipe.tags,
            dietaryInfo: recipe.dietaryInfo,
            sourceURL: recipe.importedFromURL?.absoluteString,
            imageURL: {
                guard let img = recipe.imageName, img.hasPrefix("http") else { return nil }
                return img
            }()
        )
        return try encoder.encode(package)
    }

    /// Writes the encoded recipe to `url`, creating or overwriting the file.
    static func write(_ recipe: RecipeModel, to url: URL) throws {
        try encode(recipe).write(to: url, options: .atomic)
    }

    /// Decodes `data` into a fresh `RecipeModel` with a new UUID; personal data reset to defaults.
    static func decode(_ data: Data) throws -> RecipeModel {
        let package = try decoder.decode(RecipePackage.self, from: data)
        guard package.version == 1 else {
            throw RecipeFileError.unsupportedVersion(package.version)
        }
        let ingredients = package.ingredients.map {
            Ingredient(baseQuantity: $0.quantity, unit: $0.unit, name: $0.name)
        }
        // Reconstruct notes footer so "View Original" works on the recipient's device.
        let notes: String
        if let sourceURL = package.sourceURL {
            notes = package.notes.isEmpty
                ? sourceURL
                : "\(package.notes)\n\(sourceURL)"
        } else {
            notes = package.notes
        }
        return RecipeModel(
            name: package.name,
            category: package.category,
            difficulty: package.difficulty,
            prepTime: package.prepTime,
            cookingTime: package.cookingTime,
            baseServings: package.baseServings,
            ingredients: ingredients,
            prePrepInstructions: package.prePrepInstructions,
            instructions: package.instructions,
            notes: notes,
            imageName: package.imageURL,
            tags: package.tags,
            dietaryInfo: package.dietaryInfo,
            cuisine: package.cuisine
        )
    }
}

// MARK: - Errors

enum RecipeFileError: LocalizedError {
    case unsupportedVersion(Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let v):
            return "This recipe was exported with a newer version of RecipeFinder (format \(v))."
        }
    }
}
