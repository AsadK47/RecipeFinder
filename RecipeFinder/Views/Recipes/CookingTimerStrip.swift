import SwiftUI

/// Every running cooking timer as a row of pills ("Rice 12:00") above the step, on every step, so a timer started
/// earlier stays in sight. Tap a pill for Pause / +1 min / Stop.
struct CookingTimerStrip: View {
    @Environment(\.cookingTimers) private var cookingTimers

    var body: some View {
        if !cookingTimers.timers.isEmpty {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.spacing8) {
                        ForEach(cookingTimers.timers) { timer in
                            pill(timer, now: context.date)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onChange(of: CookingTimerBoard.doneIDs(cookingTimers.timers, at: context.date)) { old, new in
                    // In-app signal too: the notification may be off or not allowed.
                    if !new.subtracting(old).isEmpty { HapticManager.shared.celebrate() }
                }
            }
            .padding(.bottom, AppTheme.spacing12)
            .transition(.opacity)
        }
    }

    private func pill(_ timer: CookingTimerBoard.Timer, now: Date) -> some View {
        let left = timer.remaining(at: now)
        let done = left == 0
        return Menu {
            if !done {
                Button { cookingTimers.togglePause(timer.id) } label: {
                    Label(timer.isPaused ? "Resume" : "Pause", systemImage: timer.isPaused ? "play.fill" : "pause.fill")
                }
            }
            Button { cookingTimers.addMinute(timer.id) } label: {
                Label("Add 1 minute", systemImage: "plus")
            }
            Button(role: .destructive) { withAnimation(.appSnappy) { cookingTimers.stop(timer.id) } } label: {
                Label(done ? "Clear" : "Stop", systemImage: done ? "checkmark" : "stop.fill")
            }
        } label: {
            HStack(spacing: AppTheme.spacing6) {
                Image(systemName: done ? "bell.fill" : (timer.isPaused ? "pause.fill" : "timer"))
                    .foregroundStyle(done ? AnyShapeStyle(Color.green) : AnyShapeStyle(HierarchicalShapeStyle.primary))
                Text(timer.name)
                    .lineLimit(1)
                Text(done ? "Done" : CookingTimerBoard.clock(seconds: left))
                    .monospacedDigit()
            }
            .font(.subheadline.weight(.semibold))
            .adaptiveForegroundColor()
            .padding(.horizontal, AppTheme.spacing12)
            .padding(.vertical, AppTheme.spacing8)
            .appCard(in: Capsule())
        }
        .accessibilityIdentifier("cooking.timer")
        .accessibilityLabel(Self.accessibilityLabel(name: timer.name, left: left, paused: timer.isPaused))
        .accessibilityHint("Pause, add a minute or stop")
    }

    static func accessibilityLabel(name: String, left: Int, paused: Bool) -> String {
        if left == 0 { return "\(name) timer, done" }
        return "\(name) timer, \(CookingTimerBoard.spoken(seconds: left)) left\(paused ? ", paused" : "")"
    }
}
