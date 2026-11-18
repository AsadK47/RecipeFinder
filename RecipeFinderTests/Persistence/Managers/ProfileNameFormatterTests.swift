import Testing
import Foundation
@testable import RecipeFinder

/// `ProfileNameFormatter`'s display-name/initials rules (extracted from `ProfileManager`): pins the placeholder fallbacks ("Recipe Chef" / "RC") and one-sided-name handling.
@Suite struct ProfileNameFormatterTests {

    // MARK: - displayName

    @Test(arguments: [
        (first: "Jane", last: "Doe", expected: "Jane Doe"),
        (first: "Jane", last: "",    expected: "Jane"),        // first name only
        (first: "",     last: "Doe", expected: "Doe"),         // last name only, no leading space
        (first: "",     last: "",    expected: "Recipe Chef"), // placeholder
    ])
    func displayName(first: String, last: String, expected: String) {
        #expect(ProfileNameFormatter.displayName(firstName: first, lastName: last) == expected)
    }

    // MARK: - initials

    @Test(arguments: [
        (first: "Jane", last: "Doe", expected: "JD"),
        (first: "jane", last: "doe", expected: "JD"),   // uppercased
        (first: "Jane", last: "",    expected: "J"),    // first initial only
        (first: "",     last: "Doe", expected: "D"),    // last initial only
        (first: "",     last: "",    expected: "RC"),   // placeholder
    ])
    func initials(first: String, last: String, expected: String) {
        #expect(ProfileNameFormatter.initials(firstName: first, lastName: last) == expected)
    }

    // MARK: - editableName (what Me's inline name field starts with)

    @Test(arguments: [
        (first: "Jane", last: "Doe", expected: "Jane Doe"),
        (first: "",     last: "Doe", expected: "Doe"),
        (first: "",     last: "",    expected: ""),   // not the "Recipe Chef" stand-in
    ])
    func editableName(first: String, last: String, expected: String) {
        #expect(ProfileNameFormatter.editableName(firstName: first, lastName: last) == expected)
    }

    // MARK: - rename (Me's inline name field → first/last)

    @Test(arguments: [
        (text: "Sam Rivera",          first: "Sam",  last: "Rivera"),
        (text: "  Sam   Rivera  ",    first: "Sam",  last: "Rivera"),          // stray spaces collapse
        (text: "Sam",                 first: "Sam",  last: ""),                // one word → first name only
        (text: "Ana Lucía de la Cruz", first: "Ana", last: "Lucía de la Cruz"), // the rest is the last name
        (text: "Sam\nRivera",         first: "Sam",  last: "Rivera"),          // pasted line break
    ])
    func renameSplitsFirstWordFromTheRest(text: String, first: String, last: String) {
        let change = ProfileNameFormatter.rename(firstName: "Jane", lastName: "Doe", to: text)
        #expect(change == ProfileName(first: first, last: last))
    }

    @Test func renameToBlankClearsTheName() {
        #expect(ProfileNameFormatter.rename(firstName: "Jane", lastName: "Doe", to: "   ") == ProfileName(first: "", last: ""))
    }

    /// Re-splitting an untouched "Mary Ann" + "Smith" would turn it into "Mary" + "Ann Smith".
    @Test(arguments: ["Mary Ann Smith", " Mary  Ann Smith "])
    func renameWithTheSameNameChangesNothing(text: String) {
        #expect(ProfileNameFormatter.rename(firstName: "Mary Ann", lastName: "Smith", to: text) == nil)
    }

    @Test func renameBlankWithNoNameChangesNothing() {
        #expect(ProfileNameFormatter.rename(firstName: "", lastName: "", to: "") == nil)
    }

    @Test func renameCapsAVeryLongName() {
        let long = String(repeating: "a", count: 200) + " " + String(repeating: "b", count: 200)
        let change = ProfileNameFormatter.rename(firstName: "", lastName: "", to: long)
        let total = (change?.first.count ?? 0) + (change?.last.count ?? 0)
        #expect(change != nil)
        #expect(total <= ProfileNameFormatter.maxNameLength)
    }
}
