import SwiftUI
import UserNotifications

struct CookTimerView: View {
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var isRunning: Bool = false
    @State private var isPaused: Bool = false
    @State private var timeRemaining: Int = 0
    @State private var timer: Timer?
    @State private var currentTime = Date()
    @State private var clockTimer: Timer?
    
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @AppStorage("cookModeEnabled") private var cookModeEnabled: Bool = true
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) var scenePhase
    
    var totalSeconds: Int {
        hours * 3600 + minutes * 60
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Cook Timer")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Current Time Clock (always visible)
                            currentTimeSection
                            
                            // Time Picker Section (always visible)
                            timePickerSection
                            
                            // Control Buttons
                            controlButtonsSection
                            
                            // Running Timer Display (appears below when started)
                            if isRunning {
                                runningTimerSection
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onAppear {
            if cookModeEnabled {
                UIApplication.shared.isIdleTimerDisabled = true
            }
            startClockTimer()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            clockTimer?.invalidate()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && isRunning {
                // Resume timer when app comes back to foreground
                startTimer()
            } else if newPhase == .inactive || newPhase == .background {
                // Pause timer when app goes to background
                timer?.invalidate()
            }
        }
    }
    
    // MARK: - Current Time Section
    private var currentTimeSection: some View {
        VStack(spacing: 8) {
            Text("Current Time")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Text(currentTime, style: .time)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            }
        }
    }
    
    // MARK: - Time Picker Section
    private var timePickerSection: some View {
        VStack(spacing: 20) {
            // Quick Presets
            quickPresetsSection
        }
    }
    
    // MARK: - Quick Presets
    private var quickPresetsSection: some View {
        VStack(spacing: 16) {
            Text("Set Timer")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                presetButton(minutes: 1, title: "1 min")
                presetButton(minutes: 5, title: "5 min")
                presetButton(minutes: 10, title: "10 min")
                presetButton(minutes: 15, title: "15 min")
                presetButton(minutes: 30, title: "30 min")
                presetButton(minutes: 60, title: "1 hour")
            }
        }
    }
    
    private func presetButton(minutes: Int, title: String) -> some View {
        let isSelected = (self.minutes == minutes % 60) && (self.hours == minutes / 60)
        
        return Button(action: {
            setTime(minutes: minutes)
            HapticManager.shared.light()
        }) {
            VStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.title2)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.9))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected 
                              ? AppTheme.accentColor(for: selectedTheme)
                              : (colorScheme == .dark ? Color(white: 0.2) : Color.white.opacity(0.85)))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected 
                              ? AppTheme.accentColor(for: selectedTheme).opacity(0.8)
                              : Color.white.opacity(0.1))
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppTheme.accentColor(for: selectedTheme), lineWidth: 2)
                }
            }
        }
    }
    
    // MARK: - Running Timer Section
    private var runningTimerSection: some View {
        VStack(spacing: 16) {
            Divider()
                .background(Color.white.opacity(0.3))
                .padding(.vertical, 8)
            
            Text("Timer Running")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            
            // Circular Progress
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 16)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppTheme.accentColor(for: selectedTheme),
                                AppTheme.accentColor(for: selectedTheme).opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: progress)
                
                VStack(spacing: 8) {
                    Text(timeString)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if isPaused {
                        Text("Paused")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(8)
                    } else {
                        Text("Cooking")
                            .font(.caption)
                            .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    }
                }
            }
            .frame(width: 240, height: 240)
            .padding(.vertical, 16)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color(white: 0.12) : Color.white.opacity(0.85))
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                }
            }
        }
    }
    
    // MARK: - Control Buttons
    private var controlButtonsSection: some View {
        HStack(spacing: 16) {
            if !isRunning {
                // Start Button
                Button(action: startTimer) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppTheme.accentColor(for: selectedTheme))
                    .cornerRadius(16)
                }
                .disabled(totalSeconds == 0)
                .opacity(totalSeconds == 0 ? 0.5 : 1.0)
            } else {
                // Pause/Resume Button
                Button(action: togglePause) {
                    HStack {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        Text(isPaused ? "Resume" : "Pause")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.orange)
                    .cornerRadius(16)
                }
                
                // Stop Button
                Button(action: stopTimer) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.red)
                    .cornerRadius(16)
                }
            }
        }
    }
    
    // MARK: - Clock Functions
    private func startClockTimer() {
        clockTimer?.invalidate()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    // MARK: - Timer Functions
    private func setTime(minutes: Int) {
        self.hours = minutes / 60
        self.minutes = minutes % 60
    }
    
    private func startTimer() {
        if !isRunning {
            timeRemaining = totalSeconds
            isRunning = true
            isPaused = false
        }
        
        if !isPaused {
            HapticManager.shared.success()
        }
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 && !isPaused {
                timeRemaining -= 1
            } else if timeRemaining == 0 {
                timerCompleted()
            }
        }
    }
    
    private func togglePause() {
        isPaused.toggle()
        HapticManager.shared.light()
        
        if !isPaused {
            startTimer()
        } else {
            timer?.invalidate()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        timeRemaining = 0
        HapticManager.shared.light()
    }
    
    private func timerCompleted() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        
        HapticManager.shared.celebrate()
        sendNotification()
    }
    
    private func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Cook Timer"
        content.body = "Your timer has finished!"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Helper Properties
    private var timeString: String {
        let h = timeRemaining / 3600
        let m = (timeRemaining % 3600) / 60
        let s = timeRemaining % 60
        
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
    
    private var progress: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        return CGFloat(timeRemaining) / CGFloat(totalSeconds)
    }
}

#Preview {
    CookTimerView()
}
