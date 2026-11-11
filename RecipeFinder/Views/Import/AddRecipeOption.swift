import SwiftUI

/// What the "+" sheet's paste box holds: a link goes to the link importer, anything else to the text reader.
enum AddRecipeInput: Equatable {
    case empty
    case link(URL)
    case text(String)

    /// A link with a few words around it ("so good! https://…") is still a link; a caption long enough to hold a
    /// recipe is read as text even when it mentions a link.
    static let maxWordsForLink = 8

    static func classify(_ raw: String) -> AddRecipeInput {
        let trimmed = raw.trimmed
        guard !trimmed.isEmpty else { return .empty }
        if let url = ClipboardRecipeLink.url(in: [trimmed]),
           trimmed.split(whereSeparator: \.isWhitespace).count <= maxWordsForLink {
            return .link(url)
        }
        return .text(trimmed)
    }
}

/// What the add flow does once a link has been read: straight to the recipe screen, or ask first when the library
/// already has a recipe of that name (case and spacing ignored).
enum AddRecipeLinkResult: Equatable {
    case review
    case duplicate

    static func decide(recipeName: String, existingNames: [String]) -> AddRecipeLinkResult {
        let key = normalized(recipeName)
        guard !key.isEmpty else { return .review }
        return existingNames.contains { normalized($0) == key } ? .duplicate : .review
    }

    private static func normalized(_ name: String) -> String {
        name.split(whereSeparator: \.isWhitespace).joined(separator: " ").lowercased()
    }
}

/// The other ways to add a recipe, listed under the paste box in the Recipes "+" sheet.
enum AddRecipeOption: String, CaseIterable, Identifiable {
    case photo, web, otherApp, manual

    var id: String { rawValue }

    /// Stable UI-test identifier (`import.<x>`), kept from the old Import tab so existing tests still find each card.
    var accessibilityID: String {
        switch self {
        case .web: "import.web"
        case .photo: "import.photo"
        case .otherApp: "import.otherApp"
        case .manual: "import.wizard"
        }
    }

    var title: String {
        switch self {
        case .web: "Search the web"
        case .photo: "Photo or PDF"
        case .otherApp: "From another app"
        case .manual: "Start blank"
        }
    }

    var subtitle: String {
        switch self {
        case .web: "Find a recipe online, then import the page you're on."
        case .photo: "A cookbook page, screenshot, handwritten card or PDF — read on device."
        case .otherApp: "Move your collection over from Paprika, Mela or a CSV file."
        case .manual: "Write your own recipe from scratch."
        }
    }

    var icon: String {
        switch self {
        case .web: "globe"
        case .photo: "text.viewfinder"
        case .otherApp: "tray.and.arrow.down.fill"
        case .manual: "square.and.pencil"
        }
    }

    var color: Color {
        switch self {
        case .web: .blue
        case .photo: .purple
        case .otherApp: .pink
        case .manual: .teal
        }
    }
}
