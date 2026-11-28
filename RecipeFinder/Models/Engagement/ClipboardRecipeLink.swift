import Foundation

/// Today's "Copied a recipe link?" card: when to offer it, and which link a paste hands to the link importer.
enum ClipboardRecipeLink {
    /// The first http(s) link in the pasted items — captions and messages often wrap the link in other words.
    static func url(in pasted: [String]) -> URL? {
        pasted.lazy.compactMap(RecipeLink.first(in:)).first
    }

    /// Show the card while the clipboard holds a link the user hasn't already pasted or dismissed. `changeCount`
    /// is the pasteboard's counter, so copying something new brings the card back.
    static func shouldOffer(hasWebLink: Bool, changeCount: Int, handledChangeCount: Int?) -> Bool {
        hasWebLink && changeCount != handledChangeCount
    }
}
