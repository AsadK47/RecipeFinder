import Foundation

/// The two sides of the Groceries tab: *To buy* (the shopping list) and *At home* (the kitchen that powers "Fits your
/// kitchen" and use-it-up). Same pattern as Recipes' Discover | My recipes; the choice is remembered.
/// Pure so the switch is tested, not just eyeballed.
enum GroceriesMode: String, CaseIterable, Identifiable {
    /// Raw values are stored, so don't rename them.
    case toBuy, atHome

    var id: String { rawValue }

    var title: String {
        switch self {
        case .toBuy: "To buy"
        case .atHome: "At home"
        }
    }

    /// The header field adds to whichever side is showing.
    var searchPlaceholder: String {
        switch self {
        case .toBuy: "Add or search groceries…"
        case .atHome: "Add to your kitchen…"
        }
    }

    /// Spoken in the add buttons' labels ("Add to kitchen").
    var listName: String {
        switch self {
        case .toBuy: "groceries"
        case .atHome: "kitchen"
        }
    }

    static let modeKey = "groceries.mode"
    /// Groceries' job is the shopping list (PRODUCT.md); At home is one tap away and remembered once chosen.
    static let defaultMode = GroceriesMode.toBuy

    /// Stores are where you buy, so their filter only shows on To buy, and not over search suggestions.
    static func showsStoreFilter(mode: GroceriesMode, hasStores: Bool, isSearching: Bool) -> Bool {
        mode == .toBuy && hasStores && !isSearching
    }

    /// Same-name check for the add buttons, so " Eggs" and "eggs" count as one item.
    static func contains(_ name: String, in names: [String]) -> Bool {
        let key = name.nameKey
        return names.contains { $0.nameKey == key }
    }
}
