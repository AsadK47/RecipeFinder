import Foundation
import UserNotifications

/// NotificationManager - Handles all local notifications in the app
///
/// HOW NOTIFICATIONS WORK IN iOS:
/// ================================
/// 1. REQUEST PERMISSION: First, you must ask the user for permission to send notifications
/// 2. CREATE CONTENT: Define what the notification says (title, body, sound, badge)
/// 3. CREATE TRIGGER: Define when to show it (time-based, location-based, or immediately)
/// 4. SCHEDULE: Combine content + trigger into a request and add to notification center
/// 5. HANDLE RESPONSE: Optional - respond when user taps the notification
///
/// TYPES OF NOTIFICATIONS:
/// - Time-based: Show after X seconds/minutes (UNTimeIntervalNotificationTrigger)
/// - Calendar-based: Show at specific date/time (UNCalendarNotificationTrigger)
/// - Location-based: Show at specific location (UNLocationNotificationTrigger)
/// - Immediate: Show right now (trigger = nil)
///
/// EXAMPLE USAGE:
/// ```
/// // Request permission first (usually on app launch)
/// NotificationManager.shared.requestPermission { granted in
///     print("Permission: \(granted)")
/// }
///
/// // Schedule a notification
/// NotificationManager.shared.scheduleTimerNotification(
///     title: "Timer Done!",
///     body: "Your pasta is ready",
///     timeInterval: 600 // 10 minutes
/// )
/// ```

import Foundation
import UserNotifications

 
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate, Sendable {
    /// Shared singleton instance for global access
    static let shared = NotificationManager()

    /// Backwards-compatible alias used in some files
    static var notificationManager: NotificationManager { shared }
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Permission Management
    
    /// Request permission to send notifications
    /// Call this when the app launches or when user enables notifications in settings
    func requestPermission(completion: @escaping @Sendable (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    debugLog("❌ Notification permission error: \(error.localizedDescription)")
                } else if granted {
                    debugLog("✅ Notification permission granted")
                } else {
                    debugLog("⚠️ Notification permission denied")
                }
                completion(granted)
            }
        }
    }
    
    /// Check current notification permission status
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { @Sendable settings in
            // Extract values before crossing actor boundary
            let authStatus = settings.authorizationStatus
            let alertSetting = settings.alertSetting
            let soundSetting = settings.soundSetting
            let badgeSetting = settings.badgeSetting
            
            DispatchQueue.main.async {
                debugLog("📱 Notification Status: \(authStatus.rawValue)")
                debugLog("   - Alert: \(alertSetting.rawValue)")
                debugLog("   - Sound: \(soundSetting.rawValue)")
                debugLog("   - Badge: \(badgeSetting.rawValue)")
            }
        }
    }
    
    // MARK: - Timer Notifications
    
    /// Schedule a timer completion notification
    /// - Parameters:
    ///   - title: Notification title (e.g., "Timer Complete!")
    ///   - body: Notification message (e.g., "Pasta timer is done")
    ///   - timeInterval: Seconds until notification (e.g., 600 for 10 minutes)
    ///   - identifier: Unique ID to cancel later (optional, auto-generated if not provided)
    /// - Returns: The notification identifier (useful for canceling later)
    @discardableResult
    func scheduleTimerNotification(
        title: String,
        body: String,
        timeInterval: TimeInterval,
        identifier: String? = nil
    ) -> String {
        let notificationId = identifier ?? "timer-\(UUID().uuidString)"
        
        // 1. Create the notification content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1 // Show badge on app icon
        
        // Add custom data (useful for handling different notification types)
        content.userInfo = ["type": "timer", "identifier": notificationId]
        
        // 2. Create the trigger (when to show the notification)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        // 3. Create the request combining content + trigger
        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: trigger
        )
        
        // 4. Schedule it!
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                debugLog("❌ Failed to schedule notification: \(error.localizedDescription)")
            } else {
                debugLog("✅ Notification scheduled: \(title) in \(timeInterval)s")
            }
        }
        
        return notificationId
    }
    
    /// Send an immediate notification (no delay)
    /// Useful for when a timer completes while app is in foreground
    func sendImmediateNotification(title: String, body: String, identifier: String? = nil) {
        let notificationId = identifier ?? "immediate-\(UUID().uuidString)"
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // trigger = nil means "show immediately"
        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                debugLog("❌ Failed to send immediate notification: \(error)")
            }
        }
    }
    
    // MARK: - Meal Planning Notifications
    
    /// Schedule a meal reminder notification
    /// - Parameters:
    ///   - mealName: Name of the meal (e.g., "Dinner")
    ///   - recipeName: Name of the recipe (e.g., "Spaghetti Bolognese")
    ///   - date: When to show the notification
    ///   - identifier: Unique ID (optional)
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
        
        // Use calendar trigger for specific date/time
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
                debugLog("❌ Failed to schedule meal reminder: \(error)")
            } else {
                debugLog("✅ Meal reminder scheduled for \(date)")
            }
        }
        
        return notificationId
    }
    
    /// Schedule a daily cooking reminder
    /// - Parameters:
    ///   - hour: Hour of day (0-23)
    ///   - minute: Minute of hour (0-59)
    ///   - identifier: Unique ID
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
        
        // Daily repeating trigger
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true // Repeats daily!
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                debugLog("❌ Failed to schedule daily reminder: \(error)")
            } else {
                debugLog("✅ Daily reminder scheduled for \(hour):\(minute)")
            }
        }
        
        return identifier
    }
    
    // MARK: - Shopping List Notifications
    
    /// Send notification when shopping list is updated
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
    
    // MARK: - Notification Management
    
    /// Cancel a specific notification by ID
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        debugLog("🗑️ Canceled notification: \(identifier)")
    }
    
    /// Cancel all timer notifications
    func cancelAllTimerNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { @Sendable requests in
            let timerIds = requests
                .filter { ($0.content.userInfo["type"] as? String) == "timer" }
                .map { $0.identifier }
            
            Task {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: timerIds)
                debugLog("🗑️ Canceled \(timerIds.count) timer notifications")
            }
        }
    }
    
    /// Cancel ALL pending notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        debugLog("🗑️ Canceled all notifications")
    }
    
    /// Get list of all pending notifications
    func getPendingNotifications(completion: @escaping @Sendable ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { @Sendable requests in
            completion(requests)
        }
    }
    
    /// Remove badge from app icon
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager {
    /// Called when notification is received while app is in FOREGROUND
    /// By default, notifications don't show when app is open - this allows them to show
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even when app is open
        completionHandler([.banner, .sound, .badge])
        
        debugLog("📬 Received notification while app is foreground: \(notification.request.content.title)")
    }
    
    /// Called when user TAPS on a notification
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let notificationType = userInfo["type"] as? String ?? "unknown"
        
        debugLog("👆 User tapped notification of type: \(notificationType)")
        
        // Handle different notification types
        switch notificationType {
        case "timer":
            // Navigate to timer tab or show timer screen
            // You can post a NotificationCenter notification to handle navigation
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenTimer"),
                object: nil,
                userInfo: userInfo
            )
            
        case "meal":
            // Navigate to meal planning screen
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenMealPlan"),
                object: nil,
                userInfo: userInfo
            )
            
        case "daily-reminder":
            // Open main recipes screen
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

// MARK: - Helper Extensions

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
