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
}
