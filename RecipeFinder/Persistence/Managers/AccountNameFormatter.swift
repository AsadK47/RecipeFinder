import Foundation

/// Pure display-name/initials rules extracted from `AccountManager` for unit-testing; empty name yields the "Recipe Chef" / "RC" placeholders.
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
