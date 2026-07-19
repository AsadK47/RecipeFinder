import Foundation

/// Hand-off point between the share extension and the app, backed by the
/// App Group's defaults.
///
/// The extension tries to complete the whole import itself and store a
/// finished recipe (`storeRecipe`). When that isn't possible — no network,
/// unparseable page, plain-text share — it stores the raw URL/text instead
/// and the app falls back to the interactive import sheet.
///
/// This file is compiled into both the app and RecipeShareExtension.
enum SharedImportInbox {
    static let appGroupID = "group.com.asadkhan.recipefinder"
    private static let recipeKey = "pendingSharedImportRecipeJSON"
    private static let urlKey = "pendingSharedImportURL"
    private static let textKey = "pendingSharedImportText"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Extension side (producers)

    /// Stores a fully imported recipe. Returns false when encoding or the
    /// App Group is unavailable so the caller can fall back to `storeURL`.
    @discardableResult
    static func storeRecipe(_ recipe: RecipeModel) -> Bool {
        guard let defaults, let data = try? JSONEncoder().encode(recipe) else {
            return false
        }
        defaults.set(data, forKey: recipeKey)
        return true
    }

    static func storeURL(_ urlString: String) {
        defaults?.set(urlString, forKey: urlKey)
    }

    static func storeText(_ text: String) {
        defaults?.set(text, forKey: textKey)
    }

    // MARK: - App side (consumer)

    enum Payload {
        /// The extension finished the import; save silently.
        case recipe(RecipeModel)
        /// A link to import interactively.
        case url(String)
        /// Plain text with no link — try parsing it as a recipe.
        case text(String)
    }

    /// Returns whatever the extension left behind — a finished recipe, a
    /// link, or plain text — and clears the inbox. Text containing a link is
    /// treated as a link share.
    static func consumePayload() -> Payload? {
        guard let defaults else { return nil }

        if let data = defaults.data(forKey: recipeKey) {
            defaults.removeObject(forKey: recipeKey)
            if let recipe = try? JSONDecoder().decode(RecipeModel.self, from: data) {
                return .recipe(recipe)
            }
        }

        let urlString = defaults.string(forKey: urlKey)
        let text = defaults.string(forKey: textKey)
        guard urlString != nil || text != nil else { return nil }

        defaults.removeObject(forKey: urlKey)
        defaults.removeObject(forKey: textKey)

        if let urlString, !urlString.isEmpty {
            return .url(urlString)
        }
        if let text, !text.isEmpty {
            if let link = firstURL(in: text) {
                return .url(link)
            }
            return .text(text)
        }
        return nil
    }

    private static func firstURL(in text: String) -> String? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        return detector.firstMatch(in: text, options: [], range: range)?.url?.absoluteString
    }
}
