import Foundation

/// Today's "Copied a recipe link?" card: when to offer it, and which link a paste hands to the link importer.
enum ClipboardRecipeLink {
    /// Punctuation that often hugs a link in a caption or message ("(https://…).") but isn't part of it.
    private static let wrapping = CharacterSet(charactersIn: "<>()[]{}\"'“”‘’.,;:!?")

    /// The first http(s) link in the pasted items — captions and messages often wrap the link in other words.
    static func url(in pasted: [String]) -> URL? {
        for text in pasted {
            for token in text.split(whereSeparator: \.isWhitespace) {
                let candidate = token.trimmingCharacters(in: wrapping)
                guard let url = URL(string: candidate),
                      let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
                      let host = url.host, host.contains(".") else { continue }
                return url
            }
        }
        return nil
    }

    /// Show the card while the clipboard holds a link the user hasn't already pasted or dismissed. `changeCount`
    /// is the pasteboard's counter, so copying something new brings the card back.
    static func shouldOffer(hasWebLink: Bool, changeCount: Int, handledChangeCount: Int?) -> Bool {
        hasWebLink && changeCount != handledChangeCount
    }
}
