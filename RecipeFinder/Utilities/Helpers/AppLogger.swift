import OSLog

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.recipefinder.app"
    
    static func logger(category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }
}
