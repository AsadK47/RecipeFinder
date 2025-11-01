import SwiftUI
import UserNotifications

// Timer Instance Model
struct TimerInstance: Identifiable {
    let id = UUID()
    var name: String
    var totalSeconds: Int
    var timeRemaining: Int
    var isRunning: Bool = false
    var isPaused: Bool = false
    var startTime: Date?
}

// Completed Timer Banner Model
struct CompletedTimerBanner: Identifiable {
    let id = UUID()
    let timerName: String
    let completionDate: Date = Date()
}

struct CookTimerView: View {
    @State private var timers: [TimerInstance] = []
    @State private var completedTimers: [CompletedTimerBanner] = []
    @State private var showCustomInput = false
    @State private var customHours: Int = 0
    @State private var customMinutes: Int = 0
    @State private var customSeconds: Int = 0
    @State private var customName: String = ""
    @State private var timer: Timer?
    @State private var vibrationTimer: Timer?
    
    @AppStorage("cardStyle") private var cardStyleString: String = "frosted"
    @AppStorage("keepScreenAwake") private var keepScreenAwake: Bool = false
    @AppStorage("defaultTimerDuration") private var defaultTimerDuration: Int = 300 // 5 minutes in seconds
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @Environment(\.scenePhase) var scenePhase
    
    let maxTimers = 5
    
    private var cardStyle: CardStyle {
        CardStyle(rawValue: cardStyleString) ?? .frosted
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        GeometryReader { geometry in
                            HStack(spacing: 0) {
                                // Left spacer for balance - 15% of width or fixed size
                                Color.clear
                                    .frame(width: max(44, geometry.size.width * 0.15))
                                
                                Spacer(minLength: 8)
                                
                                Text("Cook Timers")
                                    .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                
                                Spacer(minLength: 8)
                                
                                // Right menu - 15% of width or fixed size
                                Menu {
                                    Button(action: {
                                        HapticManager.shared.light()
                                        showCustomInput = true
                                    }) {
                                        Label("Custom Timer", systemImage: "timer")
                                    }
                                    
                                    if !timers.isEmpty {
                                        Divider()
                                        
                                        Button(action: {
                                            pauseAllTimers()
                                            HapticManager.shared.light()
                                        }) {
                                            Label("Pause All", systemImage: "pause.circle")
                                        }
                                        
                                        Button(action: {
                                            resumeAllTimers()
                                            HapticManager.shared.light()
                                        }) {
                                            Label("Resume All", systemImage: "play.circle")
                                        }
                                        
                                        Divider()
                                        
                                        Button(role: .destructive, action: {
                                            timers.removeAll()
                                            HapticManager.shared.light()
                                        }) {
                                            Label("Clear All Timers", systemImage: "trash")
                                        }
                                    }
                                } label: {
                                    ModernCircleButton(icon: "line.3.horizontal") {}
                                        .allowsHitTesting(false)
                                }
                                .frame(width: max(44, geometry.size.width * 0.15))
                            }
                        }
                        .frame(height: 44)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Quick Presets - Always show, but disable when max reached
                            quickPresetsSection
                            
                            // Custom Time Input Button - Always show, but disable when max reached
                            customTimeButton
                            
                            // Max timers warning (show when at max)
                            if timers.count >= maxTimers {
                                maxTimersWarning
                            }
                            
                            // Active Timers
                            if !timers.isEmpty {
                                activeTimersSection
                            }
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showCustomInput) {
                customTimeInputSheet
            }
            .overlay(alignment: .top) {
                // Stackable completion banners
                VStack(spacing: 8) {
                    ForEach(completedTimers) { completedTimer in
                        CompletedTimerBannerView(
                            timerName: completedTimer.timerName,
                            onDismiss: {
                                withAnimation {
                                    dismissCompletedTimer(completedTimer)
                                }
                            },
                            appTheme: appTheme,
                            colorScheme: colorScheme
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            if keepScreenAwake {
                UIApplication.shared.isIdleTimerDisabled = true
            }
            startTimerUpdates()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            timer?.invalidate()
            stopVibration()
        }
        .onChange(of: keepScreenAwake) { _, newValue in
            if newValue {
                UIApplication.shared.isIdleTimerDisabled = true
            } else {
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                startTimerUpdates()
            } else if newPhase == .inactive || newPhase == .background {
                timer?.invalidate()
            }
        }
    }
    
    // Quick Presets
    private var quickPresetsSection: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                defaultPresetButton()
                presetButton(seconds: 30, title: "30 sec")
                presetButton(minutes: 1, title: "1 min")
                presetButton(minutes: 10, title: "10 min")
                presetButton(minutes: 15, title: "15 min")
                presetButton(minutes: 30, title: "30 min")
            }
        }
    }
    
    private func defaultPresetButton() -> some View {
        let isDisabled = timers.count >= maxTimers
        let minutes = defaultTimerDuration / 60
        let title = minutes < 60 ? "\(minutes) min" : "\(minutes / 60) hr"
        
        return Button(action: {
            guard !isDisabled else { return }
            addTimer(name: "Default (\(title))", seconds: defaultTimerDuration)
            HapticManager.shared.light()
        }) {
            VStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.title2)
                
                Text("Default")
                    .font(.caption2)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isDisabled ? (colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.3)) : AppTheme.accentColor(for: appTheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 16)
                        .fill((colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground).opacity(isDisabled ? 0.5 : 1.0))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial.opacity(isDisabled ? 0.5 : 1.0))
                }
            }
        }
        .disabled(isDisabled)
    }
    
    private func presetButton(seconds: Int = 0, minutes: Int = 0, title: String) -> some View {
        let isDisabled = timers.count >= maxTimers
        let totalSeconds = minutes * 60 + seconds
        
        return Button(action: {
            guard !isDisabled else { return }
            addTimer(name: title, seconds: totalSeconds)
            HapticManager.shared.light()
        }) {
            VStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.title2)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isDisabled ? (colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.3)) : (colorScheme == .dark ? .white : .black))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 16)
                        .fill((colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground).opacity(isDisabled ? 0.5 : 1.0))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial.opacity(isDisabled ? 0.5 : 1.0))
                }
            }
        }
        .disabled(isDisabled)
    }
    
    // Custom Time Button
    private var customTimeButton: some View {
        let isDisabled = timers.count >= maxTimers
        
        return Button(action: {
            guard !isDisabled else { return }
            showCustomInput = true
            HapticManager.shared.light()
        }) {
            HStack {
                Image(systemName: "clock.badge.plus")
                    .font(.title3)
                Text("Custom Timer")
                    .fontWeight(.semibold)
            }
            .foregroundColor(isDisabled ? (colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.3)) : (colorScheme == .dark ? .white : .black))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 16)
                        .fill((colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground).opacity(isDisabled ? 0.5 : 1.0))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial.opacity(isDisabled ? 0.5 : 1.0))
                }
            }
        }
        .disabled(isDisabled)
    }
    
    // Custom Time Input Sheet
    private var customTimeInputSheet: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 12) {
                        GeometryReader { geometry in
                            HStack {
                                Button(action: {
                                    showCustomInput = false
                                }) {
                                    Text("Cancel")
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(.regularMaterial)
                                        .cornerRadius(12)
                                }
                                
                                Spacer()
                                
                                Text("Create Custom Timer")
                                    .font(.system(size: min(24, geometry.size.width * 0.06), weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Invisible button for balance
                                Button(action: {}) {
                                    Text("Cancel")
                                        .font(.body)
                                        .foregroundColor(.clear)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                }
                                .disabled(true)
                            }
                        }
                        .frame(height: 44)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    ScrollView {
                        VStack(spacing: 32) {
                            // Timer Name Input
                            VStack(alignment: .leading, spacing: 8) {
                        Text("Timer Name (Optional)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        TextField("e.g., Pasta, Cookies", text: $customName)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 20)
                    
                    // Time Pickers
                    HStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text("Hours")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Picker("Hours", selection: $customHours) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 120)
                            .clipped()
                        }
                        
                        Text(":")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        VStack(spacing: 8) {
                            Text("Minutes")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Picker("Minutes", selection: $customMinutes) {
                                ForEach(0..<60) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 120)
                            .clipped()
                        }
                        
                        Text(":")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        VStack(spacing: 8) {
                            Text("Seconds")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Picker("Seconds", selection: $customSeconds) {
                                ForEach(0..<60) { second in
                                    Text("\(second)").tag(second)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80, height: 120)
                            .clipped()
                        }
                    }
                    .padding()
                    .background {
                        if cardStyle == .solid {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
                        } else {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.regularMaterial)
                        }
                    }
                    
                    // Start Button
                    Button(action: {
                        let totalSeconds = customHours * 3600 + customMinutes * 60 + customSeconds
                        if totalSeconds > 0 {
                            let name = customName.isEmpty ? formatTime(totalSeconds) : customName
                            addTimer(name: name, seconds: totalSeconds)
                            customName = ""
                            customHours = 0
                            customMinutes = 0
                            customSeconds = 0
                        }
                        showCustomInput = false
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Timer")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppTheme.accentColor(for: appTheme))
                        .cornerRadius(16)
                    }
                    .disabled(customHours == 0 && customMinutes == 0 && customSeconds == 0)
                    .opacity((customHours == 0 && customMinutes == 0 && customSeconds == 0) ? 0.5 : 1.0)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // Active Timers Section
    private var activeTimersSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Active Timers")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(timers.count)/\(maxTimers)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            ForEach(timers) { timer in
                TimerCard(
                    timer: timer,
                    onTogglePause: { togglePause(timer.id) },
                    onStop: { stopTimer(timer.id) },
                    cardStyle: cardStyle,
                    colorScheme: colorScheme,
                    appTheme: appTheme
                )
            }
        }
    }
    
    // Max timers warning banner
    private var maxTimersWarning: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.body)
                .foregroundColor(.orange)
            
            Text("Maximum timers reached (\(maxTimers)/\(maxTimers))")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
        .padding(16)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    // Timer Functions
    private func addTimer(name: String, seconds: Int) {
        guard timers.count < maxTimers else { return }
        
        var newTimer = TimerInstance(
            name: name,
            totalSeconds: seconds,
            timeRemaining: seconds
        )
        newTimer.isRunning = true
        newTimer.startTime = Date()
        timers.append(newTimer)
        HapticManager.shared.success()
    }
    
    private func pauseAllTimers() {
        for index in timers.indices {
            timers[index].isPaused = true
        }
    }
    
    private func resumeAllTimers() {
        for index in timers.indices {
            timers[index].isPaused = false
        }
    }
    
    private func togglePause(_ id: UUID) {
        guard let index = timers.firstIndex(where: { $0.id == id }) else { return }
        timers[index].isPaused.toggle()
        HapticManager.shared.light()
    }
    
    private func stopTimer(_ id: UUID) {
        timers.removeAll { $0.id == id }
        HapticManager.shared.light()
    }
    
    private func startTimerUpdates() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTimers()
        }
    }
    
    private func updateTimers() {
        for index in timers.indices {
            if timers[index].isRunning && !timers[index].isPaused {
                if timers[index].timeRemaining > 0 {
                    timers[index].timeRemaining -= 1
                } else {
                    // Timer completed
                    timerCompleted(timers[index])
                    timers.remove(at: index)
                    return
                }
            }
        }
    }
    
    private func timerCompleted(_ timer: TimerInstance) {
        // Add to completed timers list
        let completedTimer = CompletedTimerBanner(timerName: timer.name)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            completedTimers.append(completedTimer)
        }
        
        // Start vibration if not already vibrating
        if vibrationTimer == nil {
            startContinuousVibration()
        }
        
        // Send notification
        sendNotification(for: timer)
        
        // Auto-dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation {
                dismissCompletedTimer(completedTimer)
            }
        }
    }
    
    private func dismissCompletedTimer(_ completedTimer: CompletedTimerBanner) {
        completedTimers.removeAll { $0.id == completedTimer.id }
        
        // Stop vibration if no more completed timers
        if completedTimers.isEmpty {
            stopVibration()
        }
    }
    
    private func startContinuousVibration() {
        // Initial strong vibration
        HapticManager.shared.celebrate()
        
        // Continue vibrating every 2 seconds until stopped
        vibrationTimer?.invalidate()
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            HapticManager.shared.celebrate()
        }
    }
    
    private func stopVibration() {
        vibrationTimer?.invalidate()
        vibrationTimer = nil
    }
    
    private func sendNotification(for timer: TimerInstance) {
        let content = UNMutableNotificationContent()
        content.title = "Timer Complete!"
        content.body = "\(timer.name) has finished"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
}

// Timer Card
struct TimerCard: View {
    let timer: TimerInstance
    let onTogglePause: () -> Void
    let onStop: () -> Void
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let appTheme: AppTheme.ThemeType
    
    private var progress: CGFloat {
        guard timer.totalSeconds > 0 else { return 0 }
        return CGFloat(timer.timeRemaining) / CGFloat(timer.totalSeconds)
    }
    
    private var timeString: String {
        let h = timer.timeRemaining / 3600
        let m = (timer.timeRemaining % 3600) / 60
        let s = timer.timeRemaining % 60
        
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Timer name and status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(timer.name)
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Text(timer.isPaused ? "Paused" : "Running")
                        .font(.caption)
                        .foregroundColor(timer.isPaused ? .orange : AppTheme.accentColor(for: appTheme))
                }
                
                Spacer()
            }
            
            // Circular Progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AppTheme.accentColor(for: appTheme),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: progress)
                
                Text(timeString)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .frame(width: 140, height: 140)
            
            // Control Buttons
            HStack(spacing: 12) {
                Button(action: onTogglePause) {
                    HStack {
                        Image(systemName: timer.isPaused ? "play.fill" : "pause.fill")
                        Text(timer.isPaused ? "Resume" : "Pause")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onStop) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
            }
        }
    }
}

// MARK: - Completed Timer Banner
struct CompletedTimerBannerView: View {
    let timerName: String
    let onDismiss: () -> Void
    let appTheme: AppTheme.ThemeType
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Animated checkmark icon
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Timer Complete!")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text(timerName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white)
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.green.opacity(0.3), lineWidth: 2)
        )
    }
}

#Preview {
    CookTimerView()
}
