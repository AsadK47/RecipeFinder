import Testing
import Foundation
@testable import RecipeFinder

/// Covers the logic-bearing part of `NotificationSettingsView`:
/// the `reminderTimeFormatter` round-trip and parsing contract.
///
/// The formatter uses `HH:mm` (24-hour) with `en_US_POSIX` locale. The POSIX
/// locale is critical — without it, the device's 12/24-hour override silently
/// reformats the stored string (e.g. "10:00" becomes "10:00 AM"), causing the
/// parse on next launch to fail and reset the reminder to midnight.
@MainActor
@Suite struct NotificationSettingsTests {

    // MARK: - reminderTimeFormatter round-trip

    @Test func formatter_roundTrips_morning() throws {
        let f = NotificationSettingsView.reminderTimeFormatter
        let date = try #require(f.date(from: "08:00"))
        #expect(f.string(from: date) == "08:00")
    }

    @Test func formatter_roundTrips_evening() throws {
        let f = NotificationSettingsView.reminderTimeFormatter
        let date = try #require(f.date(from: "21:00"))
        #expect(f.string(from: date) == "21:00")
    }

    @Test func formatter_roundTrips_noon() throws {
        let f = NotificationSettingsView.reminderTimeFormatter
        let date = try #require(f.date(from: "12:00"))
        #expect(f.string(from: date) == "12:00")
    }

    @Test func formatter_roundTrips_midnight() throws {
        let f = NotificationSettingsView.reminderTimeFormatter
        let date = try #require(f.date(from: "00:00"))
        #expect(f.string(from: date) == "00:00")
    }

    @Test func formatter_roundTrips_defaultValue() throws {
        // The AppStorage default is "10:00" — this must always parse correctly.
        let f = NotificationSettingsView.reminderTimeFormatter
        let date = try #require(f.date(from: "10:00"))
        #expect(f.string(from: date) == "10:00")
    }

    @Test func formatter_usesEnUS_POSIX_locale() {
        // POSIX locale prevents the device's regional setting from reformatting
        // "HH:mm" output to "h:mm a", which would then fail to re-parse.
        let f = NotificationSettingsView.reminderTimeFormatter
        #expect(f.locale.identifier == "en_US_POSIX")
    }

    @Test func formatter_uses24HourFormat() throws {
        // 13:00 must NOT be rendered as "1:00 PM".
        let f = NotificationSettingsView.reminderTimeFormatter
        let date = try #require(f.date(from: "13:00"))
        #expect(f.string(from: date) == "13:00")
    }

    @Test(arguments: ["08:00", "10:00", "12:00", "18:30", "21:00", "00:00"])
    func formatter_parsesCommonTimes(timeString: String) throws {
        let f = NotificationSettingsView.reminderTimeFormatter
        let parsed = try #require(f.date(from: timeString), "Expected \(timeString) to parse")
        #expect(f.string(from: parsed) == timeString)
    }

    @Test func formatter_returnsNil_forGarbage() {
        let f = NotificationSettingsView.reminderTimeFormatter
        #expect(f.date(from: "not a time") == nil)
        #expect(f.date(from: "") == nil)
        // 12-hour AM/PM strings should fail (format is HH:mm, not h:mm a)
        #expect(f.date(from: "8:00 AM") == nil)
    }

    // MARK: - Time ordering

    @Test func morningTime_isBeforeEveningTime() throws {
        let f = NotificationSettingsView.reminderTimeFormatter
        let morning = try #require(f.date(from: "08:00"))
        let evening = try #require(f.date(from: "21:00"))
        #expect(morning < evening)
    }

    @Test func noon_isAfterMorning() throws {
        let f = NotificationSettingsView.reminderTimeFormatter
        let morning = try #require(f.date(from: "08:00"))
        let noon    = try #require(f.date(from: "12:00"))
        #expect(morning < noon)
    }
}
