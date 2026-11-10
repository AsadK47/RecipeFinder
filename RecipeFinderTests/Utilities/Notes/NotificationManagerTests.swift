import Testing
@testable import RecipeFinder

/// Pure parsing of the Settings reminder time. Scheduling itself goes through `UNUserNotificationCenter`
/// (Apple framework, exempt from unit coverage).
@Suite struct GroceriesReminderTimeTests {

    @Test(arguments: [("10:00", 10, 0), ("07:45", 7, 45), ("23:59", 23, 59), ("0:05", 0, 5)])
    func parsesStoredTime(time: String, hour: Int, minute: Int) {
        let parsed = NotificationManager.hourAndMinute(from: time)
        #expect(parsed?.hour == hour)
        #expect(parsed?.minute == minute)
    }

    @Test(arguments: ["", "10", "24:00", "12:60", "ab:cd", "1:30 PM", "10:00:00"])
    func rejectsUnusableTime(time: String) {
        #expect(NotificationManager.hourAndMinute(from: time) == nil)
    }
}
