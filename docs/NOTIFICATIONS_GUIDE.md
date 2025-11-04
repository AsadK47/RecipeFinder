# iOS Notifications Guide for RecipeFinder

## 📱 What Are Notifications?

Notifications are alerts that appear on a user's device to inform them about something important, even when your app isn't open. In RecipeFinder, we use notifications for:

- **Cook timers** - Alert when cooking time is complete
- **Meal reminders** - Remind users about planned meals
- **Shopping lists** - Updates about shopping list items
- **Daily cooking reminders** - Encourage daily engagement

---

## 🎯 How iOS Notifications Work

### The Basic Flow

```
1. Request Permission → 2. Create Content → 3. Set Trigger → 4. Schedule → 5. User Sees It
```

### 1. **Request Permission** (Required First!)

Before you can send ANY notifications, you must ask the user for permission. This happens once:

```swift
NotificationManager.shared.requestPermission { granted in
    if granted {
        print("User said YES to notifications!")
    } else {
        print("User said NO to notifications")
    }
}
```

**When to request:**
- ✅ After user completes onboarding
- ✅ When user enables a feature that needs notifications
- ❌ Immediately on app launch (too aggressive)

### 2. **Create Notification Content**

This is what the notification says and how it looks:

```swift
let content = UNMutableNotificationContent()
content.title = "Timer Complete!"        // Bold title
content.body = "Your pasta is ready"     // Regular text
content.sound = .default                 // Play sound
content.badge = 1                        // Red badge on app icon
```

### 3. **Set a Trigger** (When to Show)

Three types of triggers:

#### **Immediate** (Show Right Now)
```swift
let trigger = nil  // No trigger = immediate
```

#### **Time Interval** (Show After X Seconds)
```swift
let trigger = UNTimeIntervalNotificationTrigger(
    timeInterval: 600,  // 10 minutes (600 seconds)
    repeats: false      // Only show once
)
```

#### **Calendar Date** (Show at Specific Time)
```swift
var dateComponents = DateComponents()
dateComponents.hour = 18    // 6 PM
dateComponents.minute = 30  // 6:30 PM

let trigger = UNCalendarNotificationTrigger(
    dateMatching: dateComponents,
    repeats: true  // Repeat daily at 6:30 PM
)
```

### 4. **Schedule the Notification**

Combine content + trigger:

```swift
let request = UNNotificationRequest(
    identifier: "unique-id-123",  // Unique ID to cancel later
    content: content,
    trigger: trigger
)

UNUserNotificationCenter.current().add(request)
```

---

## 🛠️ Using NotificationManager in RecipeFinder

We've created `NotificationManager.swift` to make notifications super easy!

### Example 1: Timer Notification

```swift
// When user starts a 10-minute timer
NotificationManager.shared.scheduleTimerNotification(
    title: "Timer Done!",
    body: "Your cookies are ready 🍪",
    timeInterval: 600  // 10 minutes
)
```

### Example 2: Meal Reminder

```swift
// Remind user about dinner at 6:30 PM
let dinnerTime = Calendar.current.date(
    bySettingHour: 18,
    minute: 30,
    second: 0,
    of: Date()
)!

NotificationManager.shared.scheduleMealReminder(
    mealName: "Dinner",
    recipeName: "Spaghetti Bolognese",
    date: dinnerTime
)
```

### Example 3: Daily Reminder

```swift
// Every day at 7 PM, remind user to check meal plan
NotificationManager.shared.scheduleDailyCookingReminder(
    hour: 19,  // 7 PM
    minute: 0
)
```

### Example 4: Cancel a Notification

```swift
// Save the identifier when scheduling
let notificationId = NotificationManager.shared.scheduleTimerNotification(
    title: "Timer",
    body: "Done!",
    timeInterval: 300,
    identifier: "my-timer-123"
)

// Later, cancel it if timer is stopped
NotificationManager.shared.cancelNotification(identifier: notificationId)
```

---

## 🎨 Notification Best Practices

### ✅ DO's

1. **Be Clear and Concise**
   ```swift
   ✅ "Timer Complete! Your pasta is ready"
   ❌ "Hey! Something happened in the app!"
   ```

2. **Use Emojis Wisely**
   ```swift
   ✅ "⏰ Timer Complete!"
   ✅ "🍽️ Dinner Reminder"
   ❌ "🎉🎊🎈🎁 Timer Done! 🎉🎊🎈"
   ```

3. **Provide Context**
   ```swift
   ✅ "Pasta timer (10 min) complete"
   ❌ "Timer finished"
   ```

4. **Allow Users to Control**
   - Let users turn notifications on/off in settings
   - Cancel notifications when user stops a timer
   - Clear badge count when user opens app

### ❌ DON'Ts

1. **Don't Spam**
   - ❌ Send notification every minute
   - ❌ Send multiple notifications for same event
   - ✅ Send one clear notification at the right time

2. **Don't Be Vague**
   - ❌ "Something's ready!"
   - ✅ "Your 15-minute chicken timer is complete"

3. **Don't Forget to Cancel**
   - If user stops a timer, cancel the notification!
   - If user deletes a meal plan, cancel its reminder!

---

## 🔧 Testing Notifications

### Test in Simulator

1. Run the app in Simulator
2. When notification is scheduled, **go to Home Screen** (Cmd+Shift+H)
3. Wait for notification to appear
4. **Important:** Notifications DON'T show when app is in foreground by default
   - We handle this in `NotificationManager` with the delegate methods

### Test on Real Device

1. Build and run on your iPhone
2. Allow notification permissions
3. Close the app or go to home screen
4. Wait for notification

### Quick Test Without Waiting

```swift
// Test with 5-second delay instead of 10 minutes
NotificationManager.shared.scheduleTimerNotification(
    title: "Test Notification",
    body: "This is a test",
    timeInterval: 5  // Just 5 seconds!
)
```

---

## 🚨 Common Issues & Solutions

### Issue 1: "Notifications Don't Show"

**Check:**
1. Did you request permission? 
   ```swift
   NotificationManager.shared.checkAuthorizationStatus()
   ```
2. Did user grant permission? (Check Settings > RecipeFinder > Notifications)
3. Is app in background? (Foreground notifications need special handling)

### Issue 2: "Permission Request Doesn't Appear"

**Reason:** You can only ask ONCE. If user denied it, they must enable in Settings.

**Solution:**
```swift
// Check if we should show settings prompt
NotificationManager.shared.checkAuthorizationStatus()

if !NotificationManager.shared.isAuthorized {
    // Show alert telling user to go to Settings > RecipeFinder > Notifications
}
```

### Issue 3: "Notification Shows Multiple Times"

**Reason:** You're scheduling the same notification multiple times.

**Solution:** Use unique identifiers and cancel old ones:
```swift
// Cancel old timer notification before scheduling new one
NotificationManager.shared.cancelNotification(identifier: "timer-123")

// Then schedule new one
NotificationManager.shared.scheduleTimerNotification(
    title: "New Timer",
    body: "Ready!",
    timeInterval: 300,
    identifier: "timer-123"
)
```

---

## 📊 Notification States

Notifications can be in different states:

```
┌─────────────┐
│  SCHEDULED  │ ← Waiting to be shown
└─────────────┘
      ↓
┌─────────────┐
│  DELIVERED  │ ← Shown on lock screen/notification center
└─────────────┘
      ↓
┌─────────────┐
│   TAPPED    │ ← User tapped, app opens
└─────────────┘
```

**Pending** = Scheduled but not shown yet
```swift
NotificationManager.shared.getPendingNotifications { requests in
    print("Pending notifications: \(requests.count)")
}
```

**Delivered** = Already shown, in notification center
```swift
UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
    print("Delivered notifications: \(notifications.count)")
}
```

---

## 🎯 Real Examples in RecipeFinder

### 1. Timer Completes

```swift
// In CookTimerView.swift
private func timerDidComplete(_ timer: TimerInstance) {
    // Send notification
    NotificationManager.shared.sendImmediateNotification(
        title: "⏰ Timer Complete!",
        body: "\(timer.name) has finished",
        identifier: "timer-\(timer.id)"
    )
    
    // Play sound, vibrate, show banner
    HapticManager.shared.notification(.success)
    
    // Add to completed list
    completedTimers.append(CompletedTimerBanner(timerName: timer.name))
}
```

### 2. Schedule Meal Reminder

```swift
// In MealPlanningView.swift
func scheduleMealReminders(for mealPlan: MealPlanModel) {
    guard let date = mealPlan.date else { return }
    
    // Remind 30 minutes before meal time
    let reminderTime = date.addingTimeInterval(-30 * 60)
    
    NotificationManager.shared.scheduleMealReminder(
        mealName: mealPlan.mealType.rawValue,
        recipeName: mealPlan.recipeName,
        date: reminderTime,
        identifier: "meal-\(mealPlan.id)"
    )
}
```

### 3. Daily Cooking Reminder

```swift
// In SettingsView.swift
Toggle("Daily Cooking Reminder", isOn: $dailyReminder)
    .onChange(of: dailyReminder) { _, enabled in
        if enabled {
            NotificationManager.shared.scheduleDailyCookingReminder(
                hour: 19,  // 7 PM
                minute: 0
            )
        } else {
            NotificationManager.shared.cancelNotification(
                identifier: "daily-cooking-reminder"
            )
        }
    }
```

---

## 🎓 Key Takeaways

1. **Always request permission first** - No permission = No notifications
2. **Use meaningful identifiers** - Makes canceling specific notifications easy
3. **Cancel when needed** - Don't leave old notifications scheduled
4. **Test in background** - Notifications behave differently when app is closed
5. **Be user-friendly** - Let users control notification settings
6. **Handle errors gracefully** - Check permission status before scheduling

---

## 📚 Additional Resources

- [Apple's User Notifications Framework](https://developer.apple.com/documentation/usernotifications)
- [Human Interface Guidelines - Notifications](https://developer.apple.com/design/human-interface-guidelines/notifications)
- [NotificationManager.swift](../RecipeFinder/Utilities/NotificationManager.swift) - Our implementation

---

## 🆘 Need Help?

If something's not working:

1. Check console logs for error messages
2. Verify permission status:
   ```swift
   NotificationManager.shared.checkAuthorizationStatus()
   ```
3. List pending notifications:
   ```swift
   NotificationManager.shared.getPendingNotifications { requests in
       print("Pending: \(requests)")
   }
   ```
4. Check device Settings > RecipeFinder > Notifications

Happy notifying! 🎉
