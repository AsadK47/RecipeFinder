import SwiftUI
import UserNotifications

/// Notification type toggles plus the reminder time.
struct NotificationSettingsView: View {
    @AppStorage("timerNotifications") private var timerNotifications = true
    @AppStorage("shoppingListReminders") private var shoppingListReminders = false
    @AppStorage("reminderTime") private var reminderTimeString = "10:00"
    /// Namespaced like LocalStore's keys, so `MealPlanningManager` reads it and Reset turns it off.
    @AppStorage(LocalStore.keyPrefix + SundayPlanNudge.settingKey) private var sundayPlanNudge = false
    @Environment(\.mealPlanning) private var mealPlanning
    @Environment(\.scenePhase) private var scenePhase

    @State private var showingTimePicker = false
    @State private var notificationPermission: UNAuthorizationStatus = .notDetermined
    /// Set when the cook turned Sunday Planning on and iOS said no, so the switch flips back with a reason.
    @State private var sundayNudgeDenied = false

    /// Must use en_US_POSIX: with a 12/24-hour device override, a bare "HH:mm" formatter can emit unparseable "1:30 PM" strings, silently dropping the chosen time.
    static let reminderTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var reminderTime: Date {
        Self.reminderTimeFormatter.date(from: reminderTimeString) ?? Date()
    }

    var body: some View {
        SettingsScreen("Notifications") {
            if notificationPermission != .authorized && !showsSundayNudgeDeniedNote {
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
                            icon: "cart.fill",
                            iconColor: .blue,
                            title: "Groceries Reminders",
                            subtitle: "Remind me to pick up groceries",
                            isOn: $shoppingListReminders
                        )

                        SettingsRowDivider()

                        SettingsToggleRow(
                            icon: "calendar.badge.clock",
                            iconColor: .purple,
                            title: "Sunday Planning",
                            subtitle: "A Sunday-evening nudge when next week's dinners are still open",
                            isOn: $sundayPlanNudge
                        )
                        .accessibilityIdentifier("settings.sundayPlanNudge")
                    }
                }

                if showsSundayNudgeDeniedNote {
                    sundayNudgeDeniedNote
                }
            }

            if shoppingListReminders {
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
                reminderTimeString = Self.reminderTimeFormatter.string(from: newTime)
            }
        }
        .onAppear {
            checkNotificationPermission()
        }
        // Back from iOS Settings: a newly allowed app drops the banner and the note.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { checkNotificationPermission() }
        }
        .onChange(of: shoppingListReminders) { _, _ in syncGroceriesReminder() }
        .onChange(of: reminderTimeString) { _, _ in syncGroceriesReminder() }
        .onChange(of: sundayPlanNudge) { _, isOn in
            guard isOn else {
                mealPlanning.syncPlanNudge()
                return
            }
            sundayNudgeDenied = false
            Task { await confirmSundayNudge() }
        }
    }

    private var permissionBanner: some View {
        SettingsCard {
            VStack(alignment: .center, spacing: AppTheme.spacing16) {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: AppTheme.fontSize60))
                    .foregroundStyle(.orange)
                    .padding(.top, AppTheme.spacing10)

                VStack(spacing: AppTheme.spacing8) {
                    Text("Notifications Disabled")
                        .font(.title2)
                        .fontWeight(.bold)
                        .adaptiveForegroundColor()

                    Text("Enable notifications in Settings to receive reminders and alerts for timers, meal plans, and groceries.")
                        .font(.subheadline)
                        .adaptiveSecondaryForeground()
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: openSystemSettings) {
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

    private static let sundayNudgeDeniedText = "Turn on notifications for RecipeFinder in Settings to get the Sunday nudge."

    /// Shown in place of the top banner, next to the switch that just flipped back, until notifications are allowed.
    private var showsSundayNudgeDeniedNote: Bool {
        sundayNudgeDenied && notificationPermission != .authorized
    }

    /// Points the cook at iOS Settings after a denied Sunday Planning switch; the whole note is the button.
    private var sundayNudgeDeniedNote: some View {
        Button(action: openSystemSettings) {
            Label(Self.sundayNudgeDeniedText, systemImage: "bell.slash")
                .font(.footnote)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .adaptiveSecondaryForeground()
        .padding(.horizontal, AppTheme.spacing8)
        .accessibilityIdentifier("settings.sundayPlanNudge.denied")
        .accessibilityHint("Opens Settings")
    }

    /// Schedules only once iOS allows notifications; otherwise the switch goes back off (its onChange cancels any
    /// pending nudge) so it never claims a nudge iOS won't show. Syncing reads the stored switch, so a switch turned
    /// off before the answer arrived stays off and shows no note.
    private func confirmSundayNudge() async {
        let granted = await NotificationManager.shared.requestPermission()
        checkNotificationPermission()
        if granted {
            mealPlanning.syncPlanNudge()
        } else if sundayPlanNudge {
            sundayNudgeDenied = true
            sundayPlanNudge = false
            AccessibilityNotification.Announcement("Sunday Planning is off. " + Self.sundayNudgeDeniedText).post()
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func syncGroceriesReminder() {
        NotificationManager.shared.syncGroceriesReminder(isOn: shoppingListReminders, time: reminderTimeString)
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
