import Foundation
import UserNotifications

private let logger = AppLogger.logger(category: "Notification")

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate, Sendable {
    static let shared = NotificationManager()

    static var notificationManager: NotificationManager { shared }
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }
    
    func requestPermission(completion: @escaping @Sendable (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
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
    
    /// Asks for permission in context (the system only prompts the first time; afterwards it returns the saved
    /// choice), then schedules. Replaces the old ask-on-every-launch prompt.
    private func addAskingPermissionFirst(_ request: UNNotificationRequest, failureLabel: String) {
        requestPermission { _ in }
        // Scheduled regardless of the answer: iOS delivers it only if notifications are allowed when it fires.
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                logger.error("❌ Failed to schedule \(failureLabel): \(error.localizedDescription)")
            }
        }
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
        
        content.userInfo = ["type": "timer", "identifier": notificationId]
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                logger.error("❌ Failed to schedule notification: \(error.localizedDescription)")
            } else {
                logger.debug("✅ Notification scheduled: \(title) in \(timeInterval)s")
            }
        }
        
        return notificationId
    }
    
    func sendImmediateNotification(title: String, body: String, identifier: String? = nil) {
        let notificationId = identifier ?? "immediate-\(UUID().uuidString)"
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                logger.error("❌ Failed to send immediate notification: \(error)")
            }
        }
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
        content.userInfo = ["type": "meal", "identifier": notificationId]
        
        // Weekly repeat matches on weekday+time only; a one-off fires at the exact date.
        let fields: Set<Calendar.Component> = repeatsWeekly
            ? [.weekday, .hour, .minute]
            : [.year, .month, .day, .hour, .minute]
        let dateComponents = Calendar.current.dateComponents(fields, from: date)
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: repeatsWeekly
        )
        
        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                logger.error("❌ Failed to schedule meal reminder: \(error)")
            } else {
                logger.debug("✅ Meal reminder scheduled for \(date)")
            }
        }
        
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
        content.userInfo = ["type": "streak", "identifier": identifier]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        addAskingPermissionFirst(request, failureLabel: "streak reminder")
    }

    @discardableResult
    func scheduleDailyCookingReminder(
        hour: Int,
        minute: Int,
        identifier: String = "daily-cooking-reminder"
    ) -> String {
        let content = UNMutableNotificationContent()
        content.title = "👨‍🍳 Time to Cook!"
        content.body = "Check your meal plan and start preparing your delicious meal"
        content.sound = .default
        content.userInfo = ["type": "daily-reminder"]
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                logger.error("❌ Failed to schedule daily reminder: \(error)")
            } else {
                logger.debug("✅ Daily reminder scheduled for \(hour):\(minute)")
            }
        }
        
        return identifier
    }
    
    func notifyShoppingListUpdate(itemsCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🛒 Groceries Updated"
        content.body = "You have \(itemsCount) items in your groceries"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "shopping-list-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        logger.debug("🗑️ Canceled notification: \(identifier)")
    }
    
    func cancelAllTimerNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { @Sendable requests in
            let timerIds = requests
                .filter { ($0.content.userInfo["type"] as? String) == "timer" }
                .map { $0.identifier }
            
            Task {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: timerIds)
                logger.debug("🗑️ Canceled \(timerIds.count) timer notifications")
            }
        }
    }
    
    // MARK: - Pantry expiry notifications

    @discardableResult
    func scheduleExpiryNotification(for item: KitchenInventoryModel) -> String? {
        guard let expiryDate = item.expiryDate else { return nil }
        // Notify the evening before expiry so the user can plan dinner.
        guard let notifyDate = Calendar.current.date(byAdding: .day, value: -1, to: expiryDate),
              notifyDate > Date() else { return nil }

        let identifier = "expiry-\(item.id.uuidString)"
        let content = UNMutableNotificationContent()
        content.title = "Expiring Tomorrow"
        content.body = "\(item.name) expires tomorrow — use it up tonight."
        content.sound = .default
        content.userInfo = ["type": "expiry", "itemId": item.id.uuidString]

        var components = Calendar.current.dateComponents([.year, .month, .day], from: notifyDate)
        components.hour = 18
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        addAskingPermissionFirst(request, failureLabel: "expiry notification")
        return identifier
    }

    func cancelExpiryNotification(for itemId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["expiry-\(itemId.uuidString)"]
        )
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        logger.debug("🗑️ Canceled all notifications")
    }
    
    func getPendingNotifications(completion: @escaping @Sendable ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { @Sendable requests in
            completion(requests)
        }
    }
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
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
        let notificationType = userInfo["type"] as? String ?? "unknown"
        
        logger.debug("👆 User tapped notification of type: \(notificationType)")
        
        switch notificationType {
        case "timer":
            NotificationCenter.default.post(
                name: .openTimer,
                object: nil,
                userInfo: userInfo
            )
            
        case "meal":
            NotificationCenter.default.post(
                name: .openMealPlan,
                object: nil,
                userInfo: userInfo
            )
            
        case "expiry":
            NotificationCenter.default.post(
                name: .openGroceries,
                object: nil,
                userInfo: userInfo
            )

        case "daily-reminder":
            NotificationCenter.default.post(
                name: .openRecipes,
                object: nil
            )

        default:
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
