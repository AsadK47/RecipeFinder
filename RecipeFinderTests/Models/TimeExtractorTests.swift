import Testing
@testable import RecipeFinder

@Suite("TimeExtractor.extractMinutes")
struct TimeExtractorTests {

    @Test("Parses minute, hour, and combined durations", arguments: [
        ("30 min", 30),
        ("0 min", 0),
        ("45 minutes", 45),
        ("90 min", 90),
        ("1 hour", 60),
        ("1 hr", 60),
        ("2 hrs", 120),
        ("2 hours", 120),
        ("1 hour 30 min", 90),
        ("1 hr 15 mins", 75),
        ("1.5 hours", 90),
        ("30", 30),
        // Ranges collapse to the upper bound; the hyphen must not become a
        // negative sign (previously "20-30 min" parsed to -10).
        ("20-30 min", 30),
        ("1-2 hours", 120),
        ("-5 min", 0)
    ])
    func parses(input: String, expected: Int) {
        #expect(TimeExtractor.extractMinutes(from: input) == expected)
    }

    @Test("Non-durations extract to zero", arguments: ["N/A", "", "unknown"])
    func nonDuration_returnsZero(input: String) {
        #expect(TimeExtractor.extractMinutes(from: input) == 0)
    }
}
