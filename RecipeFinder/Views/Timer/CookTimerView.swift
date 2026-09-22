import SwiftUI

struct CookTimerView: View {
    @Environment(\.recipeTimer) private var timerManager
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0

    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    private var selectedTotalSeconds: Int {
        (hours * 3600) + (minutes * 60) + seconds
    }

    private var selectedTimeText: String {
        String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.spacing24) {
                    currentTimerCard
                    pickerCard
                }
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.top, AppTheme.spacing16)
                .padding(.bottom, AppTheme.spacing100)
            }
        }
        .navigationTitle("Recipe Timer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var currentTimerCard: some View {
        VStack(spacing: AppTheme.spacing16) {
            HStack {
                Text("Current Timer")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()
                Spacer()
                Text(timerManager.isActive ? (timerManager.isPaused ? "Paused" : "Running") : "Stopped")
                    .font(.caption)
                    .foregroundColor(timerManager.isPaused ? .orange : AppTheme.accentColor(for: selectedTheme))
            }

            Text(timerManager.displayTime)
                .font(.system(size: AppTheme.fontSize40, weight: .bold, design: .monospaced))
                .adaptiveForegroundColor()
                .frame(maxWidth: .infinity)

            HStack(spacing: AppTheme.spacing12) {
                Button(action: {
                    timerManager.togglePause()
                }) {
                    Label(timerManager.isPaused ? "Resume" : "Pause", systemImage: timerManager.isPaused ? "play.fill" : "pause.fill")
                        .fontWeight(.semibold)
                        .adaptiveForegroundColor()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.spacing12)
                        .background(AppTheme.warning)
                        .cornerRadius(AppTheme.cornerRadius12)
                }
                .buttonStyle(.plain)
                .disabled(!timerManager.isActive)
                .opacity(timerManager.isActive ? 1 : 0.5)

                Button(action: {
                    timerManager.stop()
                }) {
                    Label("Stop", systemImage: "stop.fill")
                        .fontWeight(.semibold)
                        .adaptiveForegroundColor()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.spacing12)
                        .background(AppTheme.error)
                        .cornerRadius(AppTheme.cornerRadius12)
                }
                .buttonStyle(.plain)
                .disabled(!timerManager.isActive)
                .opacity(timerManager.isActive ? 1 : 0.5)
            }
        }
        .padding(AppTheme.spacing24)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                    .fill(AppTheme.cardBackground(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                    .fill(.regularMaterial)
            }
        }
    }

    private var pickerCard: some View {
        VStack(spacing: AppTheme.spacing20) {
            HStack {
                Text("Set Duration")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()
                Spacer()
                Text(selectedTimeText)
                    .font(.system(.headline, design: .monospaced))
                    .adaptiveForegroundColor()
            }

            HStack(spacing: AppTheme.spacing12) {
                wheelPicker(title: "HH", selection: $hours, range: 0..<24)
                wheelPicker(title: "MM", selection: $minutes, range: 0..<60)
                wheelPicker(title: "SS", selection: $seconds, range: 0..<60)
            }

            Button(action: {
                timerManager.start(hours: hours, minutes: minutes, seconds: seconds)
            }) {
                Label(timerManager.isActive ? "Restart Timer" : "Start Timer", systemImage: "play.fill")
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacing14)
                    .background(AppTheme.accentColor(for: selectedTheme))
                    .cornerRadius(AppTheme.cornerRadius12)
            }
            .buttonStyle(.plain)
            .disabled(selectedTotalSeconds == 0)
            .opacity(selectedTotalSeconds == 0 ? 0.5 : 1)
        }
        .padding(AppTheme.spacing24)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                    .fill(AppTheme.cardBackground(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                    .fill(.regularMaterial)
            }
        }
    }

    private func wheelPicker(title: String, selection: Binding<Int>, range: Range<Int>) -> some View {
        VStack(spacing: AppTheme.spacing6) {
            Text(title)
                .font(.caption)
                .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)

            Picker(title, selection: selection) {
                ForEach(Array(range), id: \.self) { value in
                    Text(String(format: "%02d", value)).tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.height120)
            .clipped()
        }
    }
}

#Preview {
    NavigationStack {
        CookTimerView()
    }
}
