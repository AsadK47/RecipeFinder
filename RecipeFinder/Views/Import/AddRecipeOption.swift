import SwiftUI

/// The ways to add a recipe, in the order the Recipes "+" sheet lists them.
enum AddRecipeOption: String, CaseIterable, Identifiable {
    case link, web, paste, photo, otherApp, manual

    var id: String { rawValue }

    /// Stable UI-test identifier (`import.<x>`), kept from the old Import tab so existing tests still find each card.
    var accessibilityID: String {
        switch self {
        case .link: "import.link"
        case .web: "import.web"
        case .paste: "import.paste"
        case .photo: "import.photo"
        case .otherApp: "import.otherApp"
        case .manual: "import.wizard"
        }
    }

    var title: String {
        switch self {
        case .link: "Paste a link"
        case .web: "Search the web"
        case .paste: "Paste text"
        case .photo: "Scan a photo or PDF"
        case .otherApp: "Bring recipes from another app"
        case .manual: "Create manually"
        }
    }

    var subtitle: String {
        switch self {
        case .link: "Import from a recipe website — we fetch and parse it for you."
        case .web: "Find a recipe online, then import the page you're on."
        case .paste: "Paste a caption, note, or message — we pull out the recipe to review."
        case .photo: "A cookbook page, screenshot, handwritten card or PDF — read on device."
        case .otherApp: "Move your collection over from Paprika, Mela or a CSV file."
        case .manual: "Add a recipe yourself, step by step."
        }
    }

    var icon: String {
        switch self {
        case .link: "link"
        case .web: "globe"
        case .paste: "doc.on.clipboard"
        case .photo: "text.viewfinder"
        case .otherApp: "tray.and.arrow.down.fill"
        case .manual: "square.and.pencil"
        }
    }

    var color: Color {
        switch self {
        case .link: .orange
        case .web: .blue
        case .paste: .green
        case .photo: .purple
        case .otherApp: .pink
        case .manual: .teal
        }
    }
}
