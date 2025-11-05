# Notification System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    RecipeFinder App                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    │
│  │ CookTimerView│    │ MealPlanView │    │ SettingsView │    │
│  │              │    │              │    │              │    │
│  │ Start Timer  │    │ Schedule     │    │ Daily        │    │
│  │ ⏱ 10 min    │    │ Meal 6:30 PM │    │ Reminders    │    │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘    │
│         │                   │                    │             │
│         └───────────────────┼────────────────────┘             │
│                             ▼                                  │
│                  ┌─────────────────────┐                       │
│                  │ NotificationManager │                       │
│                  │    (Singleton)      │                       │
│                  ├─────────────────────┤                       │
│                  │ • Request Permission│                       │
│                  │ • Schedule          │                       │
│                  │ • Cancel            │                       │
│                  │ • Manage            │                       │
│                  └──────────┬──────────┘                       │
│                             │                                  │
└─────────────────────────────┼──────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    iOS System                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│              UNUserNotificationCenter                           │
│              ┌─────────────────────┐                            │
│              │  Pending Queue      │                            │
│              ├─────────────────────┤                            │
│              │ 1. Pasta Timer      │ → Shows at 6:10 PM        │
│              │ 2. Dinner Reminder  │ → Shows at 6:30 PM        │
│              │ 3. Daily Alert      │ → Shows at 7:00 PM        │
│              └─────────────────────┘                            │
│                       │                                         │
│                       ▼                                         │
│              ┌─────────────────────┐                            │
│              │  When Trigger Fires │                            │
│              └─────────────────────┘                            │
│                       │                                         │
└───────────────────────┼─────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    User's Device                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   Lock Screen               Notification Center                │
│  ┌─────────────────┐       ┌─────────────────┐                │
│  │ ⏰ Timer Done!  │       │ 3 Notifications │                │
│  │ Pasta is ready  │       │ ⏰ Timer Done!   │                │
│  │ Slide to view   │       │ 🍽️ Dinner Time  │                │
│  └─────────────────┘       │ 👨‍🍳 Daily Alert │                │
│                             └─────────────────┘                │
│                                     │                           │
│                                     ▼                           │
│                            User Taps Notification               │
│                                     │                           │
│                                     ▼                           │
│                          Opens RecipeFinder App                 │
│                                     │                           │
└─────────────────────────────────────┼───────────────────────────┘
                                      │
                                      ▼
                         App handles notification tap
                         (navigates to relevant screen)
```

## Flow Breakdown

### 1️⃣ Schedule Phase
```
User Action → Your View → NotificationManager → iOS System → Queued
```

### 2️⃣ Trigger Phase
```
Time Arrives → iOS Checks Queue → Shows Notification → User Sees It
```

### 3️⃣ Interaction Phase
```
User Taps → Opens App → Delegate Method → Navigate to Screen
```

## Example Timeline

```
10:00 AM  User starts 10-minute pasta timer
          ├─ App calls: scheduleTimerNotification(timeInterval: 600)
          ├─ iOS adds to pending queue
          └─ Returns identifier: "timer-abc-123"

10:05 AM  User exits app (goes to home screen)
          └─ App backgrounded, timer continues in iOS

10:10 AM  Timer completes!
          ├─ iOS shows notification on lock screen
          ├─ Plays sound 🔊
          ├─ Shows banner with "Pasta is ready"
          └─ Adds badge to app icon

10:12 AM  User taps notification
          ├─ Opens RecipeFinder
          ├─ Calls didReceive delegate method
          └─ Can navigate to timer screen automatically
```

## Permission Flow

```
First Launch
     │
     ▼
┌──────────────────┐
│ Request          │
│ Permission       │ ────► User Sees System Alert
└──────────────────┘              │
                                  ├─ Allow ───► isAuthorized = true
                                  │
                                  └─ Don't Allow ───► isAuthorized = false
                                                            │
                                                            ▼
                                                   Must go to Settings
                                                   to enable manually
```

## Notification States

```
SCHEDULED
    │
    │  (time passes)
    ▼
DELIVERED ──► On lock screen
    │        In notification center
    │
    ├─ User Taps ──► OPENED (app opens)
    │
    ├─ User Swipes Away ──► DISMISSED
    │
    └─ Expires ──► REMOVED
```

## Code Flow Example

```swift
// 1. User starts timer in CookTimerView
func startTimer() {
    // 2. Call notification manager
    let notificationId = NotificationManager.shared.scheduleTimerNotification(
        title: "Timer Done!",
        body: "Pasta is ready",
        timeInterval: 600
    )
    
    // 3. Save ID to cancel later if needed
    timer.notificationId = notificationId
}

// If user stops timer early:
func stopTimer() {
    // 4. Cancel the notification
    if let id = timer.notificationId {
        NotificationManager.shared.cancelNotification(identifier: id)
    }
}

// When notification fires:
// 5. iOS shows notification automatically
// 6. User taps notification
// 7. Delegate method called:
func userNotificationCenter(didReceive response:...) {
    // 8. Handle the tap (navigate, etc.)
    if response.notification.request.content.userInfo["type"] == "timer" {
        // Navigate to timer screen
    }
}
```

## Integration Points in RecipeFinder

```
RecipeFinder App
├── RecipeFinderApp.swift ──────── Requests permission on launch
├── Utilities/
│   └── NotificationManager.swift ─ Core notification logic
├── Views/
│   ├── Timer/
│   │   └── CookTimerView.swift ─── Timer notifications ✓
│   ├── MealPlanning/
│   │   └── MealPlanView.swift ──── Meal reminders (v0.2)
│   └── Settings/
│       └── SettingsView.swift ──── Notification preferences (v0.2)
└── docs/
    ├── NOTIFICATIONS_GUIDE.md ──── Full documentation
    └── NOTIFICATIONS_SUMMARY.md ─ Quick reference
```

## Key Classes

```
NotificationManager (Singleton)
├── requestPermission()
├── scheduleTimerNotification()
├── scheduleMealReminder()
├── scheduleDailyCookingReminder()
├── cancelNotification()
└── cancelAllNotifications()

UNUserNotificationCenter (iOS)
├── add(request) ──────────────── Schedule notification
├── remove(identifiers) ───────── Cancel notification
└── getPendingNotifications() ─── List scheduled

Delegates
├── willPresent ───────────────── Show while app open
└── didReceive ────────────────── Handle user tap
```
