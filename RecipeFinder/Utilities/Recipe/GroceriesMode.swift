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

    /// Same as Recipes' toggle: suggestions replace the list while typing and already say where they add.
    static func showsModePicker(isSearching: Bool) -> Bool {
        !isSearching
    }

    /// Stores are where you buy, so their filter only shows on To buy, and not over search suggestions.
    static func showsStoreFilter(mode: GroceriesMode, hasStores: Bool, isSearching: Bool) -> Bool {
        mode == .toBuy && hasStores && !isSearching
    }

    /// What Return in the header field (or a suggestion's Add) does on this side.
    enum AddAction: Equatable {
        case shopping(String)
        case kitchen(String)
        /// Kitchen adds toggle, so an existing name is kept and the cook is told instead.
        case alreadyInKitchen
        case nothing
    }

    /// The shopping list merges duplicates itself; the kitchen would remove an existing name, so it's checked here.
    func add(_ text: String, kitchenNames: [String]) -> AddAction {
        let name = text.trimmed
        guard !name.isEmpty else { return .nothing }
        switch self {
        case .toBuy: return .shopping(name)
        case .atHome:
            return Self.contains(name, in: kitchenNames) ? .alreadyInKitchen : .kitchen(name)
        }
    }

    /// Reminders and badges that open Groceries land on the side they're about: an expiry reminder on At home,
    /// everything else (groceries reminder, shopping badge) on To buy. `type` is the notification's `userInfo["type"]`.
    static func side(openedBy type: String?) -> GroceriesMode {
        type == NotificationKind.expiry.rawValue ? .atHome : .toBuy
    }

    /// Stores the side a reminder or badge opens, for Groceries' `@AppStorage` to pick up. The tab root calls this
    /// rather than observing the key itself, so a defaults write doesn't re-render every tab.
    static func rememberSide(openedBy type: String?, in defaults: UserDefaults = .standard) {
        defaults.set(side(openedBy: type).rawValue, forKey: modeKey)
    }

    /// Same-name check for the add buttons, so " Eggs" and "eggs" count as one item.
    static func contains(_ name: String, in names: [String]) -> Bool {
        let key = name.nameKey
        return names.contains { $0.nameKey == key }
    }
}
