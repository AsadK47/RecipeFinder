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

    /// Largest file `read(from:)` opens — a recipe package is a few KB, so anything near this is not one.
    static let maxFileBytes = 5 * 1024 * 1024

    /// Reads and decodes a `.recipefinderrecipe` file opened from Files, iCloud Drive or another app.
    static func read(
        from url: URL,
        access: ScopedFileAccess = .securityScoped,
        coordination: FileReadCoordination = .fileCoordinator
    ) throws -> RecipeModel {
        let didAccess = access.start(url)
        defer { if didAccess { access.stop(url) } }
        // Coordinated so a Files / iCloud Drive placeholder is downloaded first; read the URL the coordinator hands over.
        let data = try coordination.read(url, readCapped)
        return try decode(data)
    }

    /// Reads at most `maxFileBytes`, one byte past the cap so a huge file is never loaded whole, whatever size it reports.
    private static func readCapped(_ url: URL) throws -> Data {
        let handle = try FileHandle(forReadingFrom: url)
        // A failed close of a read-only handle loses nothing; the bytes are already read or the read already threw.
        defer { try? handle.close() }
        let data = try handle.read(upToCount: maxFileBytes + 1) ?? Data()
        guard data.count <= maxFileBytes else { throw RecipeFileError.tooLarge }
        return data
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

enum RecipeFileError: LocalizedError, Equatable {
    case unsupportedVersion(Int)
    case tooLarge
    case notDownloaded

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let v):
            return "This recipe was exported with a newer version of RecipeFinder (format \(v))."
        case .tooLarge:
            return "This file is too large to be a recipe, so it was left unopened."
        case .notDownloaded:
            return "This recipe file isn't ready to open yet. Check your connection and try again."
        }
    }
}

// MARK: - Scoped access

/// Starts and stops access to a file another app hands us; files opened in place need security-scoped access.
/// A seam so tests can check every start is balanced by a stop.
struct ScopedFileAccess: Sendable {
    let start: @Sendable (URL) -> Bool
    let stop: @Sendable (URL) -> Void

    static let securityScoped = ScopedFileAccess(
        start: { $0.startAccessingSecurityScopedResource() },
        stop: { $0.stopAccessingSecurityScopedResource() }
    )
}

// MARK: - Coordinated read

/// Reads a file through `NSFileCoordinator`, which downloads an iCloud Drive placeholder before handing it over
/// and keeps another app from writing it mid-read. A seam so tests can check the read goes through it.
struct FileReadCoordination: Sendable {
    let read: @Sendable (URL, (URL) throws -> Data) throws -> Data

    static let fileCoordinator = fileCoordinator(timeout: 30)

    /// Gives up after `timeout` seconds — a placeholder opened offline would otherwise hold a thread forever —
    /// and reports `RecipeFileError.notDownloaded`.
    static func fileCoordinator(timeout: TimeInterval) -> FileReadCoordination {
        FileReadCoordination { url, body in
            let coordinator = CoordinatorBox(NSFileCoordinator(filePresenter: nil))
            // `cancel()` is made to be called from another thread; it ends a wait that hasn't reached the reader yet.
            let giveUp = DispatchWorkItem { coordinator.value.cancel() }
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout, execute: giveUp)
            defer { giveUp.cancel() }
            var coordinationError: NSError?
            var result: Result<Data, any Error>?
            coordinator.value.coordinate(readingItemAt: url, options: [], error: &coordinationError) { readURL in
                result = Result { try body(readURL) }
            }
            if let coordinationError {
                if coordinationError.domain == NSCocoaErrorDomain, coordinationError.code == NSUserCancelledError {
                    throw RecipeFileError.notDownloaded
                }
                throw coordinationError
            }
            guard let result else { throw CocoaError(.fileReadUnknown) }
            return try result.get()
        }
    }
}

/// Carries the coordinator into the give-up timer; `NSFileCoordinator.cancel()` is documented as callable from any thread.
private final class CoordinatorBox: @unchecked Sendable {
    let value: NSFileCoordinator
    init(_ value: NSFileCoordinator) { self.value = value }
}
