import Foundation

/// Hand-off point between the share extension and the app, backed by the
/// App Group's defaults.
///
/// The extension tries to complete the fetch + parse itself and store the
/// resulting `ExtractedRecipeData` (`storeExtractedRecipe`). The app turns that
/// into a `RecipeModel` and saves it silently on next launch. When the extension
/// can't finish — no network, unparseable page, plain-text share — it stores the
/// raw URL/text instead and the app falls back to the interactive import flow.
///
/// This file is compiled into both the app and RecipeShareExtension, so it must
/// stay Foundation-only (no app singletons / UI).
enum SharedImportInbox {
    static let appGroupID = "group.com.asadkhan.recipefinder"
    private static let recipeKey = "pendingSharedImportRecipeJSON"
    private static let urlKey = "pendingSharedImportURL"
    private static let textKey = "pendingSharedImportText"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Extension side (producers)

    /// Stores fetched+parsed recipe data. Returns false when encoding or the
    /// App Group is unavailable so the caller can fall back to `storeURL`.
    @discardableResult
    static func storeExtractedRecipe(_ data: ExtractedRecipeData) -> Bool {
        guard let defaults, let encoded = try? JSONEncoder().encode(data) else {
            return false
        }
        defaults.set(encoded, forKey: recipeKey)
        return true
    }

    static func storeURL(_ urlString: String) {
        defaults?.set(urlString, forKey: urlKey)
    }

    static func storeText(_ text: String) {
        defaults?.set(text, forKey: textKey)
    }

    // MARK: - App side (consumer)

    enum Payload: Equatable {
        /// The extension finished fetch + parse; build and save silently.
        case extracted(ExtractedRecipeData)
        /// A link to import interactively.
        case url(String)
        /// Plain text with no link — try parsing it as a recipe.
        case text(String)
    }

    /// Returns whatever the extension left behind — extracted recipe data, a
    /// link, or plain text — and clears the inbox.
    static func consumePayload() -> Payload? {
        guard let defaults else { return nil }

        let recipeData = defaults.data(forKey: recipeKey)
        let urlString = defaults.string(forKey: urlKey)
        let text = defaults.string(forKey: textKey)

        defaults.removeObject(forKey: recipeKey)
        defaults.removeObject(forKey: urlKey)
        defaults.removeObject(forKey: textKey)

        return resolvePayload(recipeData: recipeData, urlString: urlString, text: text)
    }

    /// Pure resolution of the three raw slots into a single payload, in priority
    /// order: a decodable extracted recipe wins; then a link; then plain text
    /// (with a link embedded in text promoted to `.url`). Kept separate from
    /// `UserDefaults` so the precedence rules are unit-testable.
    static func resolvePayload(recipeData: Data?, urlString: String?, text: String?) -> Payload? {
        if let recipeData,
           let data = try? JSONDecoder().decode(ExtractedRecipeData.self, from: recipeData) {
            return .extracted(data)
        }

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
