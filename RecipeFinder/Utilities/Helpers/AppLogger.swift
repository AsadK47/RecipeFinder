import OSLog

/// Centralized logging utility for the RecipeFinder app
enum AppLogger {
    /// App subsystem identifier (bundle ID)
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.recipefinder.app"
    
    /// Create a logger with a specific category
    /// - Parameter category: Category name for filtering logs (e.g., "AccountManager", "RecipeImporter")
    /// - Returns: Configured Logger instance
    static func logger(category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }
}
