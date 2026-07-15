import SwiftUI
import AudioToolbox

/// Hold-to-vibrate easter egg tucked behind Appearance & Theme.
struct PartyTimeView: View {
    @Environment(\.appTheme) var appTheme
    @State private var isVibrating = false
    @State private var vibrationTimer: Timer?

    var body: some View {
        SettingsScreen("Party Time") {
            VStack(spacing: AppTheme.spacing12) {
                Image(systemName: "party.popper.fill")
                    .font(.system(size: AppTheme.fontSize60))
                    .foregroundColor(AppTheme.accentColor(for: appTheme))
                    .symbolEffect(.bounce, value: isVibrating)

                Text("Party Time")
                    .font(.title)
                    .fontWeight(.bold)
                    .adaptiveForegroundColor()

                Text("Press and hold the button below for continuous vibration")
                    .font(.subheadline)
                    .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.spacing40)
            }
            .padding(.top, AppTheme.spacing20)

            VStack(spacing: AppTheme.spacing16) {
                ZStack {
                    if isVibrating {
                        ForEach(0..<3) { index in
                            Circle()
                                .stroke(AppTheme.accentColor(for: appTheme).opacity(0.3), lineWidth: 2)
                                .frame(width: AppTheme.width200, height: AppTheme.height200)
                                .scaleEffect(isVibrating ? AppTheme.scaleEffectBounce : AppTheme.scaleNeutral)
                                .opacity(isVibrating ? AppTheme.zeroOpacity : AppTheme.highEmphasisOpacity)
                                .animation(
                                    .easeOut(duration: AppTheme.animationDelayXLong)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.3),
                                    value: isVibrating
                                )
                        }
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isVibrating ?
                                    [AppTheme.accentColor(for: appTheme), AppTheme.accentColor(for: appTheme).opacity(0.7)] :
                                    [AppTheme.accentColor(for: appTheme).opacity(0.8), AppTheme.accentColor(for: appTheme).opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: AppTheme.width200, height: AppTheme.height200)
                        .shadow(color: AppTheme.accentColor(for: appTheme).opacity(0.5), radius: isVibrating ? AppTheme.shadowRadiusGlowActive : AppTheme.shadowRadiusGlow)
                        .scaleEffect(isVibrating ? AppTheme.transitionScaleUp : AppTheme.scaleNeutral)
                        .animation(.easeInOut(duration: AppTheme.animationDelayMedium).repeatForever(autoreverses: true), value: isVibrating)

                    Image(systemName: isVibrating ? "iphone.radiowaves.left.and.right" : "hand.tap.fill")
                        .font(.system(size: AppTheme.fontSize60))
                        .adaptiveForegroundColor()
                        .symbolEffect(.bounce, options: .repeating, value: isVibrating)
                }
                .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                    if pressing {
                        startVibration()
                    } else {
                        stopVibration()
                    }
                }, perform: {})

                Text(isVibrating ? "Release to stop" : "Press and hold to start")
                    .font(.caption)
                    .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
            }
            .padding(.vertical, AppTheme.spacing40)

            SettingsCard {
                VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("How it works")
                            .font(.headline)
                            .adaptiveForegroundColor()
                    }

                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        BulletPoint("Press and hold the button")
                        BulletPoint("Your device will vibrate continuously")
                        BulletPoint("Release to stop the vibration")
                        BulletPoint("Perfect for getting attention or just having fun!")
                    }
                }
                .padding(AppTheme.spacing20)
            }
        }
        .onDisappear {
            stopVibration()
        }
    }

    private func startVibration() {
        isVibrating = true

        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)

        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }

    private func stopVibration() {
        isVibrating = false
        vibrationTimer?.invalidate()
        vibrationTimer = nil
    }
}

private struct BulletPoint: View {
    let text: String
    @Environment(\.colorScheme) var colorScheme

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.spacing8) {
            Text("•")
                .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
            Text(text)
                .font(.subheadline)
                .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
        }
    }
}

#Preview {
    NavigationStack {
        PartyTimeView()
    }
}
