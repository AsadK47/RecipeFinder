import Foundation

/// Finds the recipe page link in shared or pasted text. The link detector also matches email addresses
/// (`mailto:`) and other schemes, and a recipe imports from a web page, so everything but http(s) is skipped.
/// The text must spell the scheme out: the detector also turns bare words like "nan.s" or "example.com" into
/// links, and the "+" paste box would then send a short recipe note to the link importer.
enum RecipeLink {
    private static let schemes = ["http://", "https://"]

    /// The first http(s) link in `text`, or nil when it has none.
    static func first(in text: String) -> URL? {
        guard !text.isEmpty,
              let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        for match in detector.matches(in: text, options: [], range: range) {
            guard let matched = Range(match.range, in: text),
                  schemes.contains(where: { text[matched].lowercased().hasPrefix($0) }),
                  let url = match.url,
                  let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
                  let host = url.host, host.contains(".") else { continue }
            return url
        }
        return nil
    }
}
