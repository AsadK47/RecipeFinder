import Testing
@testable import RecipeFinder

/// The cook-mode step-timer extractor only counts numbers with an explicit time
/// unit, so temperatures and counts don't get read as a duration.
@Suite("CookingMode step timer")
struct CookingModeTimerTests {

    @Test("ignores temperatures, reads the real duration")
    func ignoresTemperature() {
        #expect(CookingModeView.cookTimerMinutes(in: "Cook at 350°F for 12 minutes") == 12)
    }

    @Test("sums hours and minutes")
    func sumsHoursAndMinutes() {
        #expect(CookingModeView.cookTimerMinutes(in: "Simmer for 1 hour 30 minutes") == 90)
    }

    @Test("bare numbers / counts are not a timer")
    func bareNumbersIgnored() {
        #expect(CookingModeView.cookTimerMinutes(in: "Whisk 2 eggs and 200 g flour") == nil)
    }

    @Test("no time phrase → nil")
    func noTime() {
        #expect(CookingModeView.cookTimerMinutes(in: "Season to taste") == nil)
    }

    @Test("abbreviations and 'mins' work")
    func abbreviations() {
        #expect(CookingModeView.cookTimerMinutes(in: "Bake 25 mins") == 25)
    }
}
