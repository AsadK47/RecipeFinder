import SwiftUI

/// Cooking timer co-located with a recipe's steps: a Start button when idle, a live pill with actions when active.
struct RecipeTimerControl: View {
    /// The recipe's cook time as written ("30 minutes"); 0 parsed minutes means "pick a time".
    let cookingTime: String
    /// Opens the time picker (no cook time to start from, or "Set New Timer").
    let onPickTime: () -> Void
    @Environment(\.recipeTimer) private var recipeTimer

    /// Minutes from the recipe's cook time; 0 when unparseable.
    nonisolated static func cookMinutes(from cookingTime: String) -> Int {
        TimeExtractor.extractMinutes(from: cookingTime)
    }

    var body: some View {
        if recipeTimer.isActive {
            Menu {
                Button(action: onPickTime) {
                    Label("Set New Timer", systemImage: "clock")
                }
                Divider()
                Button(action: { recipeTimer.togglePause() }) {
                    Label(recipeTimer.isPaused ? "Resume" : "Pause",
                          systemImage: recipeTimer.isPaused ? "play.fill" : "pause.fill")
                }
                Button(role: .destructive, action: { recipeTimer.stop() }) {
                    Label("Stop", systemImage: "stop.fill")
                }
            } label: {
                rowLabel(
                    icon: recipeTimer.isPaused ? "play.fill" : "pause.fill",
                    text: recipeTimer.displayTime,
                    monospaced: true
                )
            }
            .accessibilityLabel("Recipe timer, \(recipeTimer.displayTime)")
            .accessibilityHint("Open timer actions")
        } else {
            let minutes = Self.cookMinutes(from: cookingTime)
            Button(action: startCookTimer) {
                rowLabel(icon: "timer", text: RecipeDetailCopy.timerStartTitle(minutes: minutes), monospaced: false)
            }
            .buttonStyle(.plain)
            .accessibilityHint(RecipeDetailCopy.timerStartHint(minutes: minutes))
        }
    }

    // One-tap start from the recipe's cook time; falls back to the picker sheet when there's none.
    private func startCookTimer() {
        let minutes = Self.cookMinutes(from: cookingTime)
        guard minutes > 0 else {
            onPickTime()
            return
        }
        HapticManager.shared.light()
        recipeTimer.start(hours: minutes / 60, minutes: minutes % 60, seconds: 0)
    }

    private func rowLabel(icon: String, text: String, monospaced: Bool) -> some View {
        HStack(spacing: AppTheme.spacing8) {
            Image(systemName: icon)
                .font(.subheadline)
            Text(text)
                .font(monospaced ? .system(.subheadline, design: .monospaced).weight(.semibold) : .subheadline.weight(.medium))
            Spacer(minLength: 0)
        }
        .adaptiveForegroundColor()
        .padding(.horizontal, AppTheme.spacing12)
        .padding(.vertical, AppTheme.spacing10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                .fill(AppTheme.adaptive(light: Color.black.opacity(AppTheme.dividerOpacity), dark: Color.white.opacity(AppTheme.overlayLightOpacity)))
        )
    }
}
