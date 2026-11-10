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

@Suite struct DurationFormatterTests {

    @Test("Human label: minutes under an hour, then hr/min", arguments: [
        (0, "0 minutes"), (45, "45 minutes"), (60, "1 hr"), (90, "1 hr 30 min"), (585, "9 hr 45 min"),
    ])
    func label(minutes: Int, expected: String) {
        #expect(DurationFormatter.label(minutes: minutes) == expected)
    }

    @Test("Countdown clock is zero-padded HH:MM:SS", arguments: [
        (0, "00:00:00"), (59, "00:00:59"), (3909, "01:05:09"),
    ])
    func clock(seconds: Int, expected: String) {
        #expect(DurationFormatter.clock(seconds: seconds) == expected)
    }

    @Test("Total minutes split into hours and minutes", arguments: [
        (0, 0, 0), (45, 0, 45), (60, 1, 0), (125, 2, 5),
    ])
    func split(total: Int, hours: Int, minutes: Int) {
        #expect(DurationFormatter.hours(of: total) == hours)
        #expect(DurationFormatter.minutes(of: total) == minutes)
    }

    @Test("Changing one part keeps the other", arguments: [
        (125, 3, 185), (125, 0, 5), (0, 1, 60),
    ])
    func settingHours(total: Int, hours: Int, expected: Int) {
        #expect(DurationFormatter.total(total, settingHours: hours) == expected)
    }

    @Test("Changing minutes keeps the hours", arguments: [
        (125, 30, 150), (125, 0, 120), (0, 15, 15),
    ])
    func settingMinutes(total: Int, minutes: Int, expected: Int) {
        #expect(DurationFormatter.total(total, settingMinutes: minutes) == expected)
    }

    @Test("Minute choices step by 5 and keep an imported odd value selectable")
    func minuteChoices() {
        #expect(DurationFormatter.minuteChoices(including: 10) == Array(stride(from: 0, through: 55, by: 5)))
        let odd = DurationFormatter.minuteChoices(including: 67)
        #expect(odd.contains(7))
        #expect(odd == odd.sorted())
        #expect(odd.count == 13)
    }
}
