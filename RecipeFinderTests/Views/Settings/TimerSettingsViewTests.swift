import XCTest
@testable import RecipeFinder

@MainActor
final class TimerSettingsViewTests: XCTestCase {

    private let sut = TimerSettingsView()

    // MARK: - formatDuration

    func testFormatDuration_underOneMinute_showsSeconds() {
        XCTAssertEqual(sut.formatDuration(45), "45 seconds")
    }

    func testFormatDuration_oneMinute_isSingular() {
        XCTAssertEqual(sut.formatDuration(60), "1 minute")
    }

    func testFormatDuration_minutes_arePlural() {
        XCTAssertEqual(sut.formatDuration(300), "5 minutes")
        XCTAssertEqual(sut.formatDuration(1800), "30 minutes")
    }

    func testFormatDuration_oneHour_isSingular() {
        XCTAssertEqual(sut.formatDuration(3600), "1 hour")
    }

    func testFormatDuration_hours_arePlural() {
        XCTAssertEqual(sut.formatDuration(7200), "2 hours")
    }

    // MARK: - TimerSound

    func testTimerSoundOffersFiveOptionsWithDefaultFirst() {
        XCTAssertEqual(TimerSettingsView.TimerSound.allCases.count, 5)
        XCTAssertEqual(TimerSettingsView.TimerSound.allCases.first, .default)
    }
}
