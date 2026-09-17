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
        identifier: String? = nil
    ) -> String {
        let notificationId = identifier ?? "meal-\(UUID().uuidString)"
        
        let content = UNMutableNotificationContent()
        content.title = "🍽️ Meal Reminder"
        content.body = "Time for \(mealName): \(recipeName)"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "meal", "identifier": notificationId]
        
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
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
        content.title = "🛒 Shopping List Updated"
        content.body = "You have \(itemsCount) items in your shopping list"
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
        components.hour = 18  // 6 PM
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                logger.error("❌ Failed to schedule expiry notification: \(error.localizedDescription)")
            } else {
                logger.debug("✅ Expiry notification scheduled for \(item.name)")
            }
        }
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
                name: NSNotification.Name("OpenTimer"),
                object: nil,
                userInfo: userInfo
            )
            
        case "meal":
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenMealPlan"),
                object: nil,
                userInfo: userInfo
            )
            
        case "expiry":
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenGroceries"),
                object: nil,
                userInfo: userInfo
            )

        case "daily-reminder":
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenRecipes"),
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
