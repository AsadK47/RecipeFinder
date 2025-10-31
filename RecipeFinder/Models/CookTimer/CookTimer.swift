import Foundation

struct CookTimer: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var duration: TimeInterval // in seconds
    var remainingTime: TimeInterval
    var isRunning: Bool
    var isPaused: Bool
    var startTime: Date?
    var endTime: Date?
    var createdDate: Date
    var recipeName: String?
    var recipeId: UUID?
    var soundEnabled: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        duration: TimeInterval,
        remainingTime: TimeInterval? = nil,
        isRunning: Bool = false,
        isPaused: Bool = false,
        startTime: Date? = nil,
        endTime: Date? = nil,
        createdDate: Date = Date(),
        recipeName: String? = nil,
        recipeId: UUID? = nil,
        soundEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.duration = duration
        self.remainingTime = remainingTime ?? duration
        self.isRunning = isRunning
        self.isPaused = isPaused
        self.startTime = startTime
        self.endTime = endTime
        self.createdDate = createdDate
        self.recipeName = recipeName
        self.recipeId = recipeId
        self.soundEnabled = soundEnabled
    }
    
    var isCompleted: Bool {
        remainingTime <= 0
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return 1.0 - (remainingTime / duration)
    }
    
    var formattedTimeRemaining: String {
        formatTime(remainingTime)
    }
    
    var formattedDuration: String {
        formatTime(duration)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

// Preset timer durations
enum TimerPreset: String, CaseIterable {
    case oneMinute = "1 Minute"
    case threeMinutes = "3 Minutes"
    case fiveMinutes = "5 Minutes"
    case tenMinutes = "10 Minutes"
    case fifteenMinutes = "15 Minutes"
    case twentyMinutes = "20 Minutes"
    case thirtyMinutes = "30 Minutes"
    case fortyFiveMinutes = "45 Minutes"
    case oneHour = "1 Hour"
    case custom = "Custom"
    
    var duration: TimeInterval {
        switch self {
        case .oneMinute: return 60
        case .threeMinutes: return 180
        case .fiveMinutes: return 300
        case .tenMinutes: return 600
        case .fifteenMinutes: return 900
        case .twentyMinutes: return 1200
        case .thirtyMinutes: return 1800
        case .fortyFiveMinutes: return 2700
        case .oneHour: return 3600
        case .custom: return 0
        }
    }
    
    var icon: String {
        switch self {
        case .oneMinute, .threeMinutes, .fiveMinutes: return "clock.fill"
        case .tenMinutes, .fifteenMinutes, .twentyMinutes: return "timer"
        case .thirtyMinutes, .fortyFiveMinutes: return "clock.arrow.circlepath"
        case .oneHour: return "hourglass"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// Common cooking timer presets
struct CookingTimerPreset {
    let name: String
    let duration: TimeInterval
    let category: String
    
    static let commonPresets = [
        CookingTimerPreset(name: "Soft Boiled Egg", duration: 360, category: "Eggs"),
        CookingTimerPreset(name: "Hard Boiled Egg", duration: 720, category: "Eggs"),
        CookingTimerPreset(name: "Poached Egg", duration: 180, category: "Eggs"),
        CookingTimerPreset(name: "Pasta Al Dente", duration: 480, category: "Pasta"),
        CookingTimerPreset(name: "Rice (White)", duration: 1080, category: "Grains"),
        CookingTimerPreset(name: "Rice (Brown)", duration: 2400, category: "Grains"),
        CookingTimerPreset(name: "Steak (Rare)", duration: 240, category: "Meat"),
        CookingTimerPreset(name: "Steak (Medium)", duration: 420, category: "Meat"),
        CookingTimerPreset(name: "Steak (Well Done)", duration: 600, category: "Meat"),
        CookingTimerPreset(name: "Bread Proofing", duration: 3600, category: "Baking"),
        CookingTimerPreset(name: "Pizza Dough Rest", duration: 1800, category: "Baking"),
        CookingTimerPreset(name: "Tea Steep", duration: 180, category: "Beverages"),
        CookingTimerPreset(name: "Coffee Brew", duration: 240, category: "Beverages")
    ]
}
