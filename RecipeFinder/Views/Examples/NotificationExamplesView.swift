import SwiftUI
import UserNotifications

/// Example view demonstrating notification usage in RecipeFinder
/// This is a reference/testing view - you can use these patterns in your actual features
struct NotificationExamplesView: View {
    @State private var showPermissionAlert = false
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @State private var isAuthorized = false
    
    private var notificationManager: NotificationManager {
        NotificationManager.shared
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient matching app theme
                LinearGradient(
                    colors: [Color.teal, Color.blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Permission Status
                        permissionStatusCard
                        
                        // Quick Test Notifications
                        quickTestSection
                        
                        // Timer Examples
                        timerExamplesSection
                        
                        // Meal Reminder Examples
                        mealReminderSection
                        
                        // Daily Reminder Examples
                        dailyReminderSection
                        
                        // Management Section
                        managementSection
                        
                        // Pending Notifications List
                        pendingNotificationsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Notification Examples")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                notificationManager.checkAuthorizationStatus()
                isAuthorized = notificationManager.isAuthorized
                loadPendingNotifications()
            }
            .alert("Enable Notifications", isPresented: $showPermissionAlert) {
                Button("Not Now", role: .cancel) {}
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Please enable notifications in Settings to receive timer alerts and meal reminders.")
            }
        }
    }
    
    // MARK: - Permission Status Card
    
    private var permissionStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(isAuthorized ? .green : .orange)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notification Permission")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(isAuthorized ? "Enabled ✓" : "Disabled")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            
            if !isAuthorized {
                Button(action: {
                    notificationManager.requestPermission { granted in
                        isAuthorized = granted
                        if !granted {
                            showPermissionAlert = true
                        }
                    }
                }) {
                    Text("Enable Notifications")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Quick Test Section
    
    private var quickTestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚡️ Quick Tests")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Send test notifications with short delays")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 10) {
                notificationButton(
                    title: "Immediate Test",
                    icon: "bolt.fill",
                    color: .yellow
                ) {
                    notificationManager.sendImmediateNotification(
                        title: "Test Notification",
                        body: "This shows up right away! 🎉"
                    )
                }
                
                notificationButton(
                    title: "5 Second Delay",
                    icon: "timer",
                    color: .blue
                ) {
                    notificationManager.scheduleTimerNotification(
                        title: "5 Second Timer",
                        body: "This appeared after 5 seconds ⏰",
                        timeInterval: 5
                    )
                }
                
                notificationButton(
                    title: "10 Second Delay",
                    icon: "clock",
                    color: .purple
                ) {
                    notificationManager.scheduleTimerNotification(
                        title: "10 Second Timer",
                        body: "Perfect for testing! 🧪",
                        timeInterval: 10
                    )
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Timer Examples
    
    private var timerExamplesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⏱ Timer Notifications")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Examples of cooking timer notifications")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 10) {
                notificationButton(
                    title: "Pasta Timer (10 min)",
                    icon: "🍝",
                    color: .orange
                ) {
                    let timerId = notificationManager.scheduleTimerNotification(
                        title: "🍝 Pasta Ready!",
                        body: "Your pasta timer (10 minutes) is complete",
                        timeInterval: 600,  // 10 minutes
                        identifier: "pasta-timer"
                    )
                    print("Scheduled pasta timer: \(timerId)")
                }
                
                notificationButton(
                    title: "Cookie Timer (15 min)",
                    icon: "🍪",
                    color: .brown
                ) {
                    notificationManager.scheduleTimerNotification(
                        title: "🍪 Cookies Ready!",
                        body: "Your cookies are done baking",
                        timeInterval: 900  // 15 minutes
                    )
                }
                
                notificationButton(
                    title: "Steak Timer (5 min)",
                    icon: "🥩",
                    color: .red
                ) {
                    notificationManager.scheduleTimerNotification(
                        title: "🥩 Steak Done!",
                        body: "Time to flip or serve your steak",
                        timeInterval: 300  // 5 minutes
                    )
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Meal Reminder Section
    
    private var mealReminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🍽 Meal Reminders")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Schedule reminders for meal times")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 10) {
                notificationButton(
                    title: "Dinner in 1 Hour",
                    icon: "clock.fill",
                    color: .green
                ) {
                    let dinnerTime = Date().addingTimeInterval(3600)  // 1 hour from now
                    notificationManager.scheduleMealReminder(
                        mealName: "Dinner",
                        recipeName: "Spaghetti Bolognese",
                        date: dinnerTime,
                        identifier: "dinner-reminder"
                    )
                }
                
                notificationButton(
                    title: "Lunch Tomorrow (12:30 PM)",
                    icon: "sun.max.fill",
                    color: .yellow
                ) {
                    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                    components.day! += 1  // Tomorrow
                    components.hour = 12
                    components.minute = 30
                    
                    if let lunchTime = Calendar.current.date(from: components) {
                        notificationManager.scheduleMealReminder(
                            mealName: "Lunch",
                            recipeName: "Caesar Salad",
                            date: lunchTime,
                            identifier: "lunch-reminder"
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Daily Reminder Section
    
    private var dailyReminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📅 Daily Reminders")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Set up recurring daily notifications")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 10) {
                notificationButton(
                    title: "Daily at 7:00 PM",
                    icon: "bell.fill",
                    color: .indigo
                ) {
                    notificationManager.scheduleDailyCookingReminder(
                        hour: 19,  // 7 PM
                        minute: 0
                    )
                }
                
                notificationButton(
                    title: "Cancel Daily Reminder",
                    icon: "bell.slash.fill",
                    color: .red
                ) {
                    notificationManager.cancelNotification(
                        identifier: "daily-cooking-reminder"
                    )
                    loadPendingNotifications()
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Management Section
    
    private var managementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🛠 Management")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Clear and manage notifications")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 10) {
                notificationButton(
                    title: "Refresh List",
                    icon: "arrow.clockwise",
                    color: .blue
                ) {
                    loadPendingNotifications()
                }
                
                notificationButton(
                    title: "Cancel All Timers",
                    icon: "trash.fill",
                    color: .orange
                ) {
                    notificationManager.cancelAllTimerNotifications()
                    loadPendingNotifications()
                }
                
                notificationButton(
                    title: "Cancel ALL Notifications",
                    icon: "trash.circle.fill",
                    color: .red
                ) {
                    notificationManager.cancelAllNotifications()
                    loadPendingNotifications()
                }
                
                notificationButton(
                    title: "Clear App Badge",
                    icon: "app.badge.fill",
                    color: .gray
                ) {
                    notificationManager.clearBadge()
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Pending Notifications
    
    private var pendingNotificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📬 Pending Notifications")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(pendingNotifications.count)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if pendingNotifications.isEmpty {
                Text("No pending notifications")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(pendingNotifications, id: \.identifier) { request in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(request.content.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text(request.content.body)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                                Text("In \(Int(trigger.timeInterval))s")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            } else if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                                if let nextDate = trigger.nextTriggerDate() {
                                    Text(nextDate, style: .relative)
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            notificationManager.cancelNotification(identifier: request.identifier)
                            loadPendingNotifications()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Views
    
    private func notificationButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            action()
            HapticManager.shared.light()
            loadPendingNotifications()
        }) {
            HStack {
                if icon.count == 1 {
                    // It's an emoji
                    Text(icon)
                        .font(.title3)
                } else {
                    // It's a SF Symbol
                    Image(systemName: icon)
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(color.opacity(0.3))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadPendingNotifications() {
        notificationManager.getPendingNotifications { requests in
            pendingNotifications = requests
        }
    }
}

#Preview {
    NotificationExamplesView()
}
