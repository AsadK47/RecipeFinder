import Foundation

/// The one place whitespace trimming lives — use instead of `trimmingCharacters(in: .whitespacesAndNewlines)`.
/// Foundation-only and compiled into the share extension too, because the shared parsers use it.
extension StringProtocol {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isBlank: Bool {
        trimmed.isEmpty
    }

    /// Identity key for "is this the same named thing?" — trimmed and lowercased, so " Eggs" and "eggs" are one item.
    /// (Not `IngredientNameFormatter.matchKey`, which also strips qualifiers for fuzzy ingredient matching.)
    var nameKey: String {
        trimmed.lowercased()
    }
}
