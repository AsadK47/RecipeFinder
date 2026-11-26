import Foundation
import UserNotifications

private let logger = AppLogger.logger(category: "Notification")

/// The userInfo "type" a notification is tagged with; the tap handler routes on it.
enum NotificationKind: String {
    case timer
    case meal
    case expiry
    case streak
    case groceriesReminder = "groceries-reminder"
    case planNudge = "plan-nudge"
}

/// The calls `NotificationManager` makes on the notification center, so tests can read each request it builds
/// (content, trigger, identifier) without scheduling real notifications or prompting for permission.
struct NotificationCenterClient: Sendable {
    let add: @Sendable (UNNotificationRequest, @escaping @Sendable ((any Error)?) -> Void) -> Void
    let removePending: @Sendable ([String]) -> Void
    let requestAuthorization: @Sendable (@escaping @Sendable (Bool, (any Error)?) -> Void) -> Void

    static let system = NotificationCenterClient(
        add: { request, done in
            UNUserNotificationCenter.current().add(request) { error in done(error) }
        },
        removePending: { identifiers in
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        },
        requestAuthorization: { done in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                done(granted, error)
            }
        }
    )
}

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate, Sendable {
    /// The app's one instance is the center's delegate (tap routing); test instances never are.
    static let shared: NotificationManager = {
        let manager = NotificationManager(center: .system)
        UNUserNotificationCenter.current().delegate = manager
        manager.checkAuthorizationStatus()
        return manager
    }()

    private let center: NotificationCenterClient

    init(center: NotificationCenterClient) {
        self.center = center
        super.init()
    }
    
    func requestPermission(completion: @escaping @Sendable (Bool) -> Void) {
        center.requestAuthorization { granted, error in
            Task { @MainActor in
                if let error = error {
                    logger.error("❌ Notification permission error: \(error.localizedDescription)")
                } else if granted {
                    logger.debug("✅ Notification permission granted")
                } else {
                    logger.debug("⚠️ Notification permission denied")
                }
                completion(granted)
            }
        }
    }
    
    /// The async form, for callers that act on the answer (a switch that must not stay on when iOS says no).
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            requestPermission { continuation.resume(returning: $0) }
        }
    }

    /// Asks for permission in context (the system only prompts the first time; afterwards it returns the saved
    /// choice), then schedules. Replaces the old ask-on-every-launch prompt.
    private func addAskingPermissionFirst(_ request: UNNotificationRequest, failureLabel: String) {
        requestPermission { _ in }
        // Scheduled regardless of the answer: iOS delivers it only if notifications are allowed when it fires.
        add(request, failureLabel: failureLabel)
    }

    /// The single path every request is added through, so no failure goes unlogged.
    private func add(_ request: UNNotificationRequest, failureLabel: String, successMessage: String? = nil) {
        center.add(request) { error in
            if let error = error {
                logger.error("❌ Failed to schedule \(failureLabel): \(error.localizedDescription)")
            } else if let successMessage {
                logger.debug("✅ \(successMessage)")
            }
        }
    }

    private func schedule(
        id: String,
        content: UNNotificationContent,
        trigger: UNNotificationTrigger?,
        failureLabel: String,
        successMessage: String? = nil
    ) {
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        add(request, failureLabel: failureLabel, successMessage: successMessage)
    }

    /// Exact-minute components for a one-shot calendar trigger.
    private static func oneShotComponents(for date: Date) -> DateComponents {
        Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    }

    static func expiryIdentifier(for itemId: UUID) -> String {
        "expiry-\(itemId.uuidString)"
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { @Sendable settings in
            let authStatus = settings.authorizationStatus
            let alertSetting = settings.alertSetting
            let soundSetting = settings.soundSetting
            let badgeSetting = settings.badgeSetting
            
            Task { @MainActor in
                logger.debug("📱 Notification Status: \(authStatus.rawValue)")
                logger.debug("   - Alert: \(alertSetting.rawValue)")
                logger.debug("   - Sound: \(soundSetting.rawValue)")
                logger.debug("   - Badge: \(badgeSetting.rawValue)")
            }
        }
    }
    
    @discardableResult
    func scheduleTimerNotification(
        title: String,
        body: String,
        timeInterval: TimeInterval,
        identifier: String? = nil
    ) -> String {
        let notificationId = identifier ?? "timer-\(UUID().uuidString)"
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        content.userInfo = ["type": NotificationKind.timer.rawValue, "identifier": notificationId]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        schedule(
            id: notificationId,
            content: content,
            trigger: trigger,
            failureLabel: "notification",
            successMessage: "Notification scheduled: \(title) in \(timeInterval)s"
        )
        
        return notificationId
    }
    
    @discardableResult
    func scheduleMealReminder(
        mealName: String,
        recipeName: String,
        date: Date,
        identifier: String? = nil,
        repeatsWeekly: Bool = false
    ) -> String {
        let notificationId = identifier ?? "meal-\(UUID().uuidString)"
        
        let content = UNMutableNotificationContent()
        content.title = "🍽️ Meal Reminder"
        content.body = "Time for \(mealName): \(recipeName)"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": NotificationKind.meal.rawValue, "identifier": notificationId]
        
        // Weekly repeat matches on weekday+time only; a one-off fires at the exact date.
        let dateComponents = repeatsWeekly
            ? Calendar.current.dateComponents([.weekday, .hour, .minute], from: date)
            : Self.oneShotComponents(for: date)
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: repeatsWeekly
        )
        schedule(
            id: notificationId,
            content: content,
            trigger: trigger,
            failureLabel: "meal reminder",
            successMessage: "Meal reminder scheduled for \(date)"
        )
        
        return notificationId
    }
    
    /// One-shot weekly cooking-streak lapse nudge (fires once at `date`); delivered only if the user has granted notifications.
    func scheduleStreakReminder(weeks: Int, at date: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "🔥 Keep your streak!"
        content.body = weeks <= 1
            ? "Cook something this week to keep your streak going."
            : "Your \(weeks)-week cooking streak ends soon — cook this week to keep it."
        content.sound = .default
        content.userInfo = ["type": NotificationKind.streak.rawValue, "identifier": identifier]

        let trigger = UNCalendarNotificationTrigger(dateMatching: Self.oneShotComponents(for: date), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        addAskingPermissionFirst(request, failureLabel: "streak reminder")
    }

    /// The opt-in Sunday planning nudge (`SundayPlanNudge`); a tap opens Plan.
    func schedulePlanNudge(at date: Date, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = SundayPlanNudge.title
        content.body = SundayPlanNudge.body
        content.sound = .default
        var userInfo: [String: Any] = SundayPlanNudge.userInfo(firingAt: date)
        userInfo["type"] = NotificationKind.planNudge.rawValue
        content.userInfo = userInfo

        let trigger = UNCalendarNotificationTrigger(dateMatching: Self.oneShotComponents(for: date), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        add(request, failureLabel: "Sunday plan nudge")
    }

    static let groceriesReminderIdentifier = "daily-groceries-reminder"

    /// The Settings "Groceries Reminders" toggle: a repeating daily nudge at the chosen time, or none when off.
    /// Re-adding with the same identifier replaces the previous time.
    func syncGroceriesReminder(isOn: Bool, time: String) {
        guard isOn, let clock = Self.hourAndMinute(from: time) else {
            cancelNotification(identifier: Self.groceriesReminderIdentifier)
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "🛒 Groceries"
        content.body = "Picking up food today? Your list is ready."
        content.sound = .default
        content.userInfo = ["type": NotificationKind.groceriesReminder.rawValue]

        var components = DateComponents()
        components.hour = clock.hour
        components.minute = clock.minute
        let request = UNNotificationRequest(
            identifier: Self.groceriesReminderIdentifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        )
        addAskingPermissionFirst(request, failureLabel: "groceries reminder")
    }

    /// Parses the stored "HH:mm" reminder time; nil for anything out of range.
    static func hourAndMinute(from time: String) -> (hour: Int, minute: Int)? {
        let parts = time.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]),
              (0..<24).contains(hour), (0..<60).contains(minute) else { return nil }
        return (hour: hour, minute: minute)
    }

    func cancelNotification(identifier: String) {
        center.removePending([identifier])
        logger.debug("🗑️ Canceled notification: \(identifier)")
    }
    
    // MARK: - Pantry expiry notifications

    @discardableResult
    func scheduleExpiryNotification(for item: KitchenInventoryModel, now: Date = Date()) -> String? {
        guard let notifyDate = Self.expiryReminderDate(for: item.expiryDate, now: now) else { return nil }

        let identifier = Self.expiryIdentifier(for: item.id)
        let content = UNMutableNotificationContent()
        content.title = "Expiring Tomorrow"
        content.body = "\(item.name) expires tomorrow — use it up tonight."
        content.sound = .default
        content.userInfo = ["type": NotificationKind.expiry.rawValue, "itemId": item.id.uuidString]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: notifyDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        addAskingPermissionFirst(request, failureLabel: "expiry notification")
        return identifier
    }

    /// 18:00 the evening before expiry, so the cook can plan dinner — nil when there is no date or that evening has
    /// already passed (an item added after 18:00 the day before would otherwise get a past trigger and no alert).
    static func expiryReminderDate(for expiryDate: Date?, now: Date, calendar: Calendar = .current) -> Date? {
        guard let expiryDate,
              let dayBefore = calendar.date(byAdding: .day, value: -1, to: expiryDate),
              let evening = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: dayBefore),
              evening > now else { return nil }
        return evening
    }

    func cancelExpiryNotification(for itemId: UUID) {
        center.removePending([Self.expiryIdentifier(for: itemId)])
    }
}

extension NotificationManager {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
        
        logger.debug("📬 Received notification while app is foreground: \(notification.request.content.title)")
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let rawType = userInfo["type"] as? String ?? "unknown"
        
        logger.debug("👆 User tapped notification of type: \(rawType)")
        
        switch NotificationKind(rawValue: rawType) {
        case .timer:
            NotificationCenter.default.post(
                name: .openTimer,
                object: nil,
                userInfo: userInfo
            )
            
        case .meal, .planNudge:
            NotificationCenter.default.post(
                name: .openMealPlan,
                object: nil,
                userInfo: userInfo
            )
            
        case .expiry, .groceriesReminder:
            NotificationCenter.default.post(
                name: .openGroceries,
                object: nil,
                userInfo: userInfo
            )

        case .streak, nil:
            break
        }
        
        completionHandler()
    }
}

extension UNAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
}
