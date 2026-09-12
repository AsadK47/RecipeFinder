import Foundation

/// Pure presentation rules for an account's display name and initials, extracted
/// from `AccountManager` so they're unit-testable without constructing the
/// singleton (which loads the profile and touches every other store on init).
/// Behaviour is preserved exactly: an empty name shows the "Recipe Chef" / "RC"
/// placeholders the UI has always shown.
enum AccountNameFormatter {

    static func displayName(firstName: String, lastName: String) -> String {
        if firstName.isEmpty && lastName.isEmpty {
            return "Recipe Chef"
        }
        var name = firstName
        if !lastName.isEmpty {
            name += " \(lastName)"
        }
        return name.trimmingCharacters(in: .whitespaces)
    }

    static func initials(firstName: String, lastName: String) -> String {
        var initials = ""
        if let first = firstName.first {
            initials += String(first)
        }
        if let last = lastName.first {
            initials += String(last)
        }
        return initials.isEmpty ? "RC" : initials.uppercased()
    }
}
