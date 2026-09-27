import Testing
@testable import RecipeFinder

/// `parseISO8601Duration` once required a literal "PT", so durations with a date component (e.g. "P0DT0H30M" from Google/AllRecipes) failed to match and the time silently vanished on import.
@Suite("parseISO8601Duration")
struct ISO8601DurationTests {

    @Test(
        "Parses common time-only durations to minutes",
        arguments: [
            ("PT15M", 15),
            ("PT30M", 30),
            ("PT1H", 60),
            ("PT1H30M", 90),
            ("PT2H15M", 135),
        ]
    )
    func timeOnly(duration: String, expected: Int) {
        #expect(RecipeParser.parseISO8601Duration(duration) == expected)
    }

    @Test(
        "Parses durations that include a date (day/week) component",
        arguments: [
            ("P0DT0H30M", 30),
            ("P0DT1H30M", 90),
            ("P1DT2H", 1560),   // 1 day + 2 hours
            ("P1D", 1440),
        ]
    )
    func withDateComponent(duration: String, expected: Int) {
        #expect(RecipeParser.parseISO8601Duration(duration) == expected)
    }

    @Test(
        "Returns nil when there is no usable duration",
        arguments: ["", "PT", "P", "PT0M", "garbage"]
    )
    func noUsableDuration(duration: String) {
        #expect(RecipeParser.parseISO8601Duration(duration) == nil)
    }

    @Test(
        "Absurdly large components are clamped, not overflow-trapped",
        arguments: ["P916000000000000W", "PT999999999999999999H", "P100000000000000DT0H0M"]
    )
    func hugeComponentsDoNotCrash(duration: String) {
        // Previously trapped on Int overflow in the minute arithmetic; now clamped.
        let result = RecipeParser.parseISO8601Duration(duration)
        #expect(result == nil || result! > 0)
    }
}
