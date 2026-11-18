import Foundation

/// Pure display-name/initials rules extracted from `ProfileManager` for unit-testing; empty name yields the "Recipe Chef" / "RC" placeholders.
enum ProfileNameFormatter {

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

    /// Longest name the inline editor keeps, so a stray paste can't push the hero off the screen.
    static let maxNameLength = 60

    /// What Me's inline name field starts with: the name as shown, or empty — never the "Recipe Chef" stand-in.
    static func editableName(firstName: String, lastName: String) -> String {
        words(in: "\(firstName) \(lastName)").joined(separator: " ")
    }

    /// Splits the inline field's text into first word + the rest (or the stored multi-word first name + the rest). `nil` when the name is unchanged, so an untouched
    /// "Mary Ann" + "Smith" isn't re-split into "Mary" + "Ann Smith".
    static func rename(firstName: String, lastName: String, to text: String) -> ProfileName? {
        let trimmed = words(in: text).joined(separator: " ")
        guard trimmed != editableName(firstName: firstName, lastName: lastName) else { return nil }
        let capped = words(in: String(trimmed.prefix(maxNameLength)))
        guard let first = capped.first else { return ProfileName(first: "", last: "") }
        // A typo fixed after a multi-word first name keeps that first name ("Mary Ann" + "Smyth", not "Mary" + "Ann Smyth").
        let keptFirst = words(in: firstName)
        if keptFirst.count > 1, capped.starts(with: keptFirst) {
            return ProfileName(first: keptFirst.joined(separator: " "),
                               last: capped.dropFirst(keptFirst.count).joined(separator: " "))
        }
        return ProfileName(first: first, last: capped.dropFirst().joined(separator: " "))
    }

    private static func words(in text: String) -> [String] {
        text.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    }
}

/// A first + last name pair as stored on the profile.
struct ProfileName: Equatable, Sendable {
    let first: String
    let last: String
}
