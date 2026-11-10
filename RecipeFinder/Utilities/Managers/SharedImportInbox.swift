import Foundation

/// Share-extension↔app hand-off via App Group defaults: extension queues parsed `ExtractedRecipeData` (app saves silently) or, if it can't finish, raw URL/text for the interactive flow. Compiled into both targets, so Foundation-only (no app singletons/UI).
enum SharedImportInbox {
    static let appGroupID = "group.com.asadkhan.recipefinder"
    private static let recipeKey = "pendingSharedImportRecipeJSON"
    private static let urlKey = "pendingSharedImportURL"
    private static let textKey = "pendingSharedImportText"

    /// Every share appends here, so a second share before the app opens no longer overwrites the first.
    private static let queueKey = "pendingSharedImportQueue"

    static var appGroupDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Extension side (producers)

    /// Queues fetched+parsed recipe data. Returns false when encoding or the
    /// App Group is unavailable so the caller can fall back to `storeURL`.
    @discardableResult
    static func storeExtractedRecipe(_ data: ExtractedRecipeData, in defaults: UserDefaults? = appGroupDefaults) -> Bool {
        enqueue(.extracted(data), in: defaults)
    }

    static func storeURL(_ urlString: String, in defaults: UserDefaults? = appGroupDefaults) {
        enqueue(.url(urlString), in: defaults)
    }

    static func storeText(_ text: String, in defaults: UserDefaults? = appGroupDefaults) {
        enqueue(.text(text), in: defaults)
    }

    /// Whether parsed data is complete enough for the app to save without review; otherwise the extension hands
    /// over the link so the app imports it interactively instead of telling the user it was saved.
    static func isCompleteRecipe(_ data: ExtractedRecipeData) -> Bool {
        !data.rawIngredients.isEmpty && !data.instructions.isEmpty
    }

    @discardableResult
    private static func enqueue(_ payload: Payload, in defaults: UserDefaults?) -> Bool {
        guard let defaults, let encoded = try? JSONEncoder().encode(payload) else { return false }
        var queue = defaults.array(forKey: queueKey) as? [Data] ?? []
        queue.append(encoded)
        defaults.set(queue, forKey: queueKey)
        return true
    }

    // MARK: - App side (consumer)

    enum Payload: Equatable, Codable {
        /// The extension finished fetch + parse; build and save silently.
        case extracted(ExtractedRecipeData)
        /// A link to import interactively.
        case url(String)
        /// Plain text with no link — try parsing it as a recipe.
        case text(String)
    }

    /// Returns everything the extension left behind, oldest first, and clears the inbox. Also drains the
    /// single-slot keys an older extension build may have written before an update.
    static func consumePayloads(from defaults: UserDefaults? = appGroupDefaults) -> [Payload] {
        guard let defaults else { return [] }

        let legacy = resolvePayload(
            recipeData: defaults.data(forKey: recipeKey),
            urlString: defaults.string(forKey: urlKey),
            text: defaults.string(forKey: textKey)
        )
        let queued = (defaults.array(forKey: queueKey) as? [Data] ?? []).compactMap { entry -> Payload? in
            guard let payload = try? JSONDecoder().decode(Payload.self, from: entry) else { return nil }
            if case let .text(text) = payload {
                return resolvePayload(recipeData: nil, urlString: nil, text: text)
            }
            return payload
        }

        for key in [recipeKey, urlKey, textKey, queueKey] {
            defaults.removeObject(forKey: key)
        }

        return (legacy.map { [$0] } ?? []) + queued
    }

    /// Pure precedence resolution (decodable recipe > link > text, with embedded links promoted to `.url`); kept off `UserDefaults` so it's unit-testable.
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
