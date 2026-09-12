import Testing
import Foundation
@testable import RecipeFinder

/// `AccountNameFormatter` — the display-name and initials rules extracted from
/// `AccountManager`. These pin the placeholder fallbacks ("Recipe Chef" / "RC")
/// and the one-sided-name handling so the extraction stays behaviour-preserving.
@Suite struct AccountNameFormatterTests {

    // MARK: - displayName

    @Test(arguments: [
        (first: "Jane", last: "Doe", expected: "Jane Doe"),
        (first: "Jane", last: "",    expected: "Jane"),        // first name only
        (first: "",     last: "Doe", expected: "Doe"),         // last name only, no leading space
        (first: "",     last: "",    expected: "Recipe Chef"), // placeholder
    ])
    func displayName(first: String, last: String, expected: String) {
        #expect(AccountNameFormatter.displayName(firstName: first, lastName: last) == expected)
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
        #expect(AccountNameFormatter.initials(firstName: first, lastName: last) == expected)
    }
}
