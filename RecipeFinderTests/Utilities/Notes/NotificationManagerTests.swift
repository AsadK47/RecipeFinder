import Foundation
import Testing
import UserNotifications
@testable import RecipeFinder

/// Pure parsing of the Settings reminder time (scheduling: `NotificationRequestTests` below).
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

/// Records what `NotificationManager` hands the notification center; nothing is scheduled and no prompt shows.
final class FakeNotificationCenter: @unchecked Sendable {
    private let lock = NSLock()
    private var addedRequests: [UNNotificationRequest] = []
    private var removedIdentifiers: [String] = []
    private var permissionAsks = 0
    /// The cook's answer to the permission prompt.
    let grants: Bool

    init(grants: Bool = true) {
        self.grants = grants
    }

    var added: [UNNotificationRequest] { lock.withLock { addedRequests } }
    var removed: [String] { lock.withLock { removedIdentifiers } }
    var asks: Int { lock.withLock { permissionAsks } }

    var client: NotificationCenterClient {
        NotificationCenterClient(
            add: { [self] request, done in
                lock.withLock { addedRequests.append(request) }
                done(nil)
            },
            removePending: { [self] identifiers in
                lock.withLock { removedIdentifiers.append(contentsOf: identifiers) }
            },
            requestAuthorization: { [self] done in
                lock.withLock { permissionAsks += 1 }
                done(grants, nil)
            }
        )
    }
}

/// What each scheduler hands the notification center: wording, tap-routing type, trigger time, and whether it asks
/// for permission first. Tap routing (`didReceive`) is exempt: `UNNotificationResponse` can't be built in a test.
@Suite struct NotificationRequestTests {
    let fake = FakeNotificationCenter()
    var manager: NotificationManager { NotificationManager(center: fake.client) }

    /// Sunday 23 Nov 2025, 18:00 in the test host's calendar (the manager reads `Calendar.current`).
    let sundayEvening: Date = {
        var parts = DateComponents()
        parts.year = 2025; parts.month = 11; parts.day = 23; parts.hour = 18; parts.minute = 0
        return Calendar.current.date(from: parts) ?? .distantPast
    }()

    private func calendarTrigger(_ request: UNNotificationRequest?) -> UNCalendarNotificationTrigger? {
        request?.trigger as? UNCalendarNotificationTrigger
    }

    @Test func planNudgeCarriesItsWordingTypeAndWeek() {
        manager.schedulePlanNudge(at: sundayEvening, identifier: SundayPlanNudge.identifier)

        #expect(fake.added.count == 1)
        let request = fake.added.first
        #expect(request?.identifier == SundayPlanNudge.identifier)
        #expect(request?.content.title == SundayPlanNudge.title)
        #expect(request?.content.body == SundayPlanNudge.body)
        let userInfo = request?.content.userInfo
        #expect(userInfo?["type"] as? String == NotificationKind.planNudge.rawValue)
        let monday = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: sundayEvening))
        #expect(SundayPlanNudge.weekStart(from: userInfo) == monday)
    }

    @Test func planNudgeFiresOnceAtTheExactMinute() {
        manager.schedulePlanNudge(at: sundayEvening, identifier: SundayPlanNudge.identifier)

        let trigger = calendarTrigger(fake.added.first)
        #expect(trigger?.repeats == false)
        let parts = trigger?.dateComponents
        #expect(parts?.year == 2025)
        #expect(parts?.month == 11)
        #expect(parts?.day == 23)
        #expect(parts?.hour == 18)
        #expect(parts?.minute == 0)
    }

    @Test func planNudgeDoesNotPromptForPermission() {
        manager.schedulePlanNudge(at: sundayEvening, identifier: SundayPlanNudge.identifier)
        #expect(fake.asks == 0)
    }

    @Test(arguments: [
        (1, "Cook something this week to keep your streak going."),
        (3, "Your 3-week cooking streak ends soon — cook this week to keep it.")
    ])
    func streakReminderWordingFollowsTheWeeks(weeks: Int, body: String) {
        manager.scheduleStreakReminder(weeks: weeks, at: sundayEvening, identifier: "streak")

        #expect(fake.added.count == 1)

        let request = fake.added.first
        #expect(request?.content.body == body)
        #expect(request?.content.userInfo["type"] as? String == NotificationKind.streak.rawValue)
        #expect(calendarTrigger(request)?.repeats == false)
        #expect(fake.asks == 1)
    }

    @Test func groceriesReminderOnRepeatsDailyAtTheChosenTime() {
        manager.syncGroceriesReminder(isOn: true, time: "07:45")

        #expect(fake.added.count == 1)

        let request = fake.added.first
        #expect(request?.identifier == NotificationManager.groceriesReminderIdentifier)
        #expect(request?.content.userInfo["type"] as? String == NotificationKind.groceriesReminder.rawValue)
        let trigger = calendarTrigger(request)
        #expect(trigger?.repeats == true)
        #expect(trigger?.dateComponents.hour == 7)
        #expect(trigger?.dateComponents.minute == 45)
        #expect(trigger?.dateComponents.day == nil)
        #expect(fake.asks == 1)
    }

    @Test(arguments: [(false, "07:45"), (true, "25:00")])
    func groceriesReminderOffOrUnreadableCancelsIt(isOn: Bool, time: String) {
        manager.syncGroceriesReminder(isOn: isOn, time: time)

        #expect(fake.added.isEmpty)
        #expect(fake.removed == [NotificationManager.groceriesReminderIdentifier])
        #expect(fake.asks == 0)
    }

    @Test func expiryNotifiesAtSixTheEveningBefore() {
        let expiry = Date().addingTimeInterval(3 * 24 * 60 * 60)
        let item = KitchenInventoryModel(name: "Coriander", category: .produce, quantity: 1, unit: "bunch",
                                         expiryDate: expiry)

        let identifier = manager.scheduleExpiryNotification(for: item)

        #expect(fake.added.count == 1)

        #expect(identifier == NotificationManager.expiryIdentifier(for: item.id))
        let request = fake.added.first
        #expect(request?.identifier == identifier)
        #expect(request?.content.body == "Coriander expires tomorrow — use it up tonight.")
        #expect(request?.content.userInfo["itemId"] as? String == item.id.uuidString)
        let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: expiry) ?? expiry
        let expected = Calendar.current.dateComponents([.year, .month, .day], from: dayBefore)
        let parts = calendarTrigger(request)?.dateComponents
        #expect(parts?.year == expected.year)
        #expect(parts?.month == expected.month)
        #expect(parts?.day == expected.day)
        #expect(parts?.hour == 18)
        #expect(fake.asks == 1)
    }

    @Test(arguments: [nil, -60.0 * 60, 12.0 * 60 * 60])
    func expiryWithNoDateOrNoEveningLeftSchedulesNothing(secondsFromNow: Double?) {
        let expiry = secondsFromNow.map { Date().addingTimeInterval($0) }
        let item = KitchenInventoryModel(name: "Milk", category: .produce, quantity: 1, unit: "l", expiryDate: expiry)

        #expect(manager.scheduleExpiryNotification(for: item) == nil)
        #expect(fake.added.isEmpty)
        #expect(fake.asks == 0)
    }

    @Test func cancellingAnExpiryRemovesItsIdentifier() {
        let id = UUID()
        manager.cancelExpiryNotification(for: id)
        #expect(fake.removed == [NotificationManager.expiryIdentifier(for: id)])
    }

    @Test func weeklyMealReminderMatchesWeekdayAndTime() {
        manager.scheduleMealReminder(mealName: "Dinner", recipeName: "Dal", date: sundayEvening,
                                     identifier: "meal-1", repeatsWeekly: true)

        #expect(fake.added.count == 1)

        let request = fake.added.first
        #expect(request?.content.body == "Time for Dinner: Dal")
        #expect(request?.content.userInfo["type"] as? String == NotificationKind.meal.rawValue)
        let trigger = calendarTrigger(request)
        #expect(trigger?.repeats == true)
        #expect(trigger?.dateComponents.weekday == Calendar.current.component(.weekday, from: sundayEvening))
        #expect(trigger?.dateComponents.hour == 18)
        #expect(trigger?.dateComponents.day == nil)
    }

    @Test func oneOffMealReminderFiresOnItsDate() {
        let id = manager.scheduleMealReminder(mealName: "Lunch", recipeName: "Soup", date: sundayEvening)

        #expect(fake.added.count == 1)

        let request = fake.added.first
        #expect(request?.identifier == id)
        let trigger = calendarTrigger(request)
        #expect(trigger?.repeats == false)
        #expect(trigger?.dateComponents.day == 23)
        #expect(trigger?.dateComponents.weekday == nil)
    }

    @Test func timerFiresAfterItsIntervalTaggedAsATimer() {
        let id = manager.scheduleTimerNotification(title: "Rice", body: "Done", timeInterval: 600)

        #expect(fake.added.count == 1)

        let request = fake.added.first
        #expect(request?.identifier == id)
        #expect(request?.content.userInfo["type"] as? String == NotificationKind.timer.rawValue)
        let trigger = request?.trigger as? UNTimeIntervalNotificationTrigger
        #expect(trigger?.timeInterval == 600)
        #expect(trigger?.repeats == false)
    }

    @Test(arguments: [true, false])
    func permissionAnswerReachesTheCaller(grants: Bool) async {
        let fake = FakeNotificationCenter(grants: grants)
        let answer = await NotificationManager(center: fake.client).requestPermission()
        #expect(answer == grants)
        #expect(fake.asks == 1)
    }

    @Test func sharedInstanceRoutesTaps() {
        #expect(UNUserNotificationCenter.current().delegate === NotificationManager.shared)
    }
}
