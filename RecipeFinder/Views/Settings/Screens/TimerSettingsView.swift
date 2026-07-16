import SwiftUI

/// Default timer duration, completion sound, and alert behavior.
struct TimerSettingsView: View {
    @AppStorage("defaultTimerDuration") private var defaultTimerDuration: Int = 300
    @AppStorage("timerSound") private var timerSound: TimerSound = .default
    @AppStorage("timerVibration") private var timerVibration: Bool = true
    @AppStorage("showTimerInNotifications") private var showTimerInNotifications: Bool = true

    enum TimerSound: String, CaseIterable {
        case `default` = "Default"
        case chime = "Chime"
        case bell = "Bell"
        case buzz = "Buzz"
        case silent = "Silent"
    }

    private let durations = [60, 300, 600, 900, 1800, 3600]

    var body: some View {
        SettingsScreen("Timers") {
            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Default Timer Duration")

                SettingsCard {
                    VStack(spacing: 0) {
                        ForEach(Array(durations.enumerated()), id: \.element) { index, seconds in
                            SettingsChoiceRow(
                                icon: "timer",
                                iconColor: .orange,
                                title: formatDuration(seconds),
                                isSelected: defaultTimerDuration == seconds
                            ) {
                                defaultTimerDuration = seconds
                            }

                            if index < durations.count - 1 {
                                SettingsRowDivider()
                            }
                        }
                    }
                }
            }

            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Completion Sound")

                SettingsCard {
                    VStack(spacing: 0) {
                        ForEach(Array(TimerSound.allCases.enumerated()), id: \.element) { index, sound in
                            SettingsChoiceRow(
                                icon: sound == .silent ? "speaker.slash.fill" : "speaker.wave.2.fill",
                                iconColor: .pink,
                                title: sound.rawValue,
                                isSelected: timerSound == sound
                            ) {
                                timerSound = sound
                            }

                            if index < TimerSound.allCases.count - 1 {
                                SettingsRowDivider()
                            }
                        }
                    }
                }
            }

            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Alerts & Behavior")

                SettingsCard {
                    VStack(spacing: 0) {
                        SettingsToggleRow(
                            icon: "iphone.radiowaves.left.and.right",
                            iconColor: .purple,
                            title: "Vibration",
                            subtitle: "Vibrate when timer completes",
                            isOn: $timerVibration
                        )

                        SettingsRowDivider()

                        SettingsToggleRow(
                            icon: "app.badge",
                            iconColor: .red,
                            title: "Show in Notifications",
                            subtitle: "Display running timers in notification center",
                            isOn: $showTimerInNotifications
                        )
                    }
                }
            }
        }
    }

    func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) seconds"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            let hours = seconds / 3600
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
    }
}

#Preview {
    NavigationStack {
        TimerSettingsView()
    }
}
