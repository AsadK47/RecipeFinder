import SwiftUI
import UserNotifications

/// Notification type toggles plus the daily reminder time.
struct NotificationSettingsView: View {
    @AppStorage("timerNotifications") private var timerNotifications = true
    @AppStorage("mealPlanReminders") private var mealPlanReminders = true
    @AppStorage("shoppingListReminders") private var shoppingListReminders = false
    @AppStorage("reminderTime") private var reminderTimeString = "10:00"

    @State private var showingTimePicker = false
    @State private var notificationPermission: UNAuthorizationStatus = .notDetermined

    var reminderTime: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: reminderTimeString) ?? Date()
    }

    var body: some View {
        SettingsScreen("Notifications") {
            if notificationPermission != .authorized {
                permissionBanner
            }

            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Notification Types")

                SettingsCard {
                    VStack(spacing: 0) {
                        SettingsToggleRow(
                            icon: "timer",
                            iconColor: .orange,
                            title: "Timer Alerts",
                            subtitle: "Get notified when timers complete",
                            isOn: $timerNotifications
                        )

                        SettingsRowDivider()

                        SettingsToggleRow(
                            icon: "calendar",
                            iconColor: .green,
                            title: "Meal Plan Reminders",
                            subtitle: "Daily reminders for planned meals",
                            isOn: $mealPlanReminders
                        )

                        SettingsRowDivider()

                        SettingsToggleRow(
                            icon: "cart.fill",
                            iconColor: .blue,
                            title: "Shopping List Reminders",
                            subtitle: "Remind me about shopping list items",
                            isOn: $shoppingListReminders
                        )
                    }
                }
            }

            if mealPlanReminders || shoppingListReminders {
                SettingsSection(title: "Reminder Time", items: [
                    .init(
                        row: SettingsRow(icon: "clock.fill", iconColor: .teal, title: "Daily reminder at", value: reminderTimeString),
                        action: { showingTimePicker = true }
                    )
                ])
            }
        }
        .sheet(isPresented: $showingTimePicker) {
            TimePickerSheet(selectedTime: reminderTime) { newTime in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                reminderTimeString = formatter.string(from: newTime)
            }
        }
        .onAppear {
            checkNotificationPermission()
        }
    }

    private var permissionBanner: some View {
        SettingsCard {
            VStack(alignment: .center, spacing: AppTheme.spacing16) {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: AppTheme.fontSize60))
                    .foregroundColor(.orange)
                    .padding(.top, AppTheme.spacing10)

                VStack(spacing: AppTheme.spacing8) {
                    Text("Notifications Disabled")
                        .font(.title2)
                        .fontWeight(.bold)
                        .adaptiveForegroundColor()

                    Text("Enable notifications in Settings to receive reminders and alerts for timers, meal plans, and shopping lists.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Open Settings")
                    }
                    .font(.headline)
                    .adaptiveForegroundColor()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacing14)
                    .background(AppTheme.accentColor)
                    .cornerRadius(AppTheme.cornerRadius12)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, AppTheme.spacing10)
            }
            .padding(.horizontal, AppTheme.spacing20)
            .padding(.vertical, AppTheme.spacing16)
            .frame(maxWidth: .infinity)
        }
    }

    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let status = settings.authorizationStatus
            DispatchQueue.main.async {
                self.notificationPermission = status
            }
        }
    }
}

struct TimePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var selectedTime: Date
    let onSave: (Date) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Select Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
            }
            .navigationTitle("Reminder Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(selectedTime)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
