import Foundation

/// Hand-off point between the share extension and the app.
///
/// The extension writes the shared URL/text into the App Group's defaults;
/// the app consumes it on foreground and routes it into recipe import. Keys
/// must stay in sync with ShareViewController in RecipeShareExtension.
enum SharedImportInbox {
    static let appGroupID = "group.com.asadkhan.recipefinder"
    private static let urlKey = "pendingSharedImportURL"
    private static let textKey = "pendingSharedImportText"

    /// Returns the pending shared URL — from a URL share, or the first link
    /// found in shared text — and clears the inbox. Returns nil when nothing
    /// is pending.
    static func consumePendingURL() -> String? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }

        let urlString = defaults.string(forKey: urlKey)
        let text = defaults.string(forKey: textKey)
        guard urlString != nil || text != nil else { return nil }

        defaults.removeObject(forKey: urlKey)
        defaults.removeObject(forKey: textKey)

        if let urlString, !urlString.isEmpty {
            return urlString
        }
        if let text {
            return firstURL(in: text)
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
