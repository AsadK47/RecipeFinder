//
//  BrokenFeatureLogger.swift
//  RecipeFinder
//
//  Centralized logging system for broken/incomplete features
//

import Foundation
import UIKit

/// Logger for tracking broken functionality and bugs
class BrokenFeatureLogger {
    static let shared = BrokenFeatureLogger()
    
    private let fileManager = FileManager.default
    private var logFileURL: URL?
    
    private init() {
        setupLogFile()
    }
    
    // MARK: - Setup
    
    private func setupLogFile() {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            debugLog("❌ Could not access documents directory")
            return
        }
        
        let errorLogsPath = documentsPath.appendingPathComponent("ErrorLogs", isDirectory: true)
        
        // Create ErrorLogs directory if it doesn't exist
        if !fileManager.fileExists(atPath: errorLogsPath.path) {
            do {
                try fileManager.createDirectory(at: errorLogsPath, withIntermediateDirectories: true)
                debugLog("✅ Created ErrorLogs directory at: \(errorLogsPath.path)")
            } catch {
                debugLog("❌ Failed to create ErrorLogs directory: \(error)")
            }
        }
        
        // Create log file
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())
        
        logFileURL = errorLogsPath.appendingPathComponent("broken_features_\(todayString).log")
        debugLog("📝 Log file: \(logFileURL?.path ?? "unknown")")
    }
    
    // MARK: - Logging Methods
    
    /// Log a broken feature with details
    func logBrokenFeature(
        featureName: String,
        category: FeatureCategory,
        status: FeatureStatus,
        errorMessage: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        screenshot: UIImage? = nil
    ) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = (file as NSString).lastPathComponent
        
        var logEntry = """
        
        ═══════════════════════════════════════════════════════════════
        🐛 BROKEN FEATURE REPORT
        ═══════════════════════════════════════════════════════════════
        Timestamp: \(timestamp)
        Feature: \(featureName)
        Category: \(category.rawValue)
        Status: \(status.emoji) \(status.rawValue)
        
        Error Message:
        \(errorMessage)
        
        Location:
        File: \(filename)
        Function: \(function)
        Line: \(line)
        
        Device Info:
        iOS: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.model)
        Name: \(UIDevice.current.name)
        
        """
        
        // Save screenshot if provided
        if let screenshot = screenshot {
            let screenshotSaved = saveScreenshot(screenshot, featureName: featureName)
            logEntry += "Screenshot: \(screenshotSaved ? "✅ Saved" : "❌ Failed")\n"
        }
        
        logEntry += "═══════════════════════════════════════════════════════════════\n"
        
        // Write to log file
        writeToLogFile(logEntry)
        
        // Also log to console in debug mode
        #if DEBUG
        print(logEntry)
        #endif
    }
    
    /// Log a quick issue
    func logIssue(_ message: String, category: FeatureCategory = .other) {
        logBrokenFeature(
            featureName: "Quick Issue",
            category: category,
            status: .broken,
            errorMessage: message
        )
    }
    
    // MARK: - Screenshot Management
    
    /// Save a screenshot of the current screen
    func saveScreenshot(_ image: UIImage, featureName: String) -> Bool {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let screenshotsPath = documentsPath
            .appendingPathComponent("ErrorLogs", isDirectory: true)
            .appendingPathComponent("Screenshots", isDirectory: true)
        
        // Create Screenshots directory if it doesn't exist
        if !fileManager.fileExists(atPath: screenshotsPath.path) {
            do {
                try fileManager.createDirectory(at: screenshotsPath, withIntermediateDirectories: true)
            } catch {
                debugLog("❌ Failed to create Screenshots directory: \(error)")
                return false
            }
        }
        
        // Create filename with timestamp
        let timestamp = Date().timeIntervalSince1970
        let sanitizedFeatureName = featureName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        let filename = "\(sanitizedFeatureName)_\(Int(timestamp)).png"
        let fileURL = screenshotsPath.appendingPathComponent(filename)
        
        // Save image
        guard let data = image.pngData() else {
            return false
        }
        
        do {
            try data.write(to: fileURL)
            debugLog("📸 Screenshot saved: \(fileURL.path)")
            return true
        } catch {
            debugLog("❌ Failed to save screenshot: \(error)")
            return false
        }
    }
    
    /// Capture screenshot of current window
    func captureScreenshot() -> UIImage? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else {
            return nil
        }
        
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        return renderer.image { context in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }
    
    // MARK: - File Operations
    
    private func writeToLogFile(_ content: String) {
        guard let logFileURL = logFileURL else {
            debugLog("❌ Log file URL not set")
            return
        }
        
        do {
            if fileManager.fileExists(atPath: logFileURL.path) {
                // Append to existing file
                let fileHandle = try FileHandle(forWritingTo: logFileURL)
                fileHandle.seekToEndOfFile()
                if let data = content.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            } else {
                // Create new file
                try content.write(to: logFileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            debugLog("❌ Failed to write to log file: \(error)")
        }
    }
    
    /// Get the log file URL for sharing
    func getLogFileURL() -> URL? {
        return logFileURL
    }
    
    /// Get all log files
    func getAllLogFiles() -> [URL] {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }
        
        let errorLogsPath = documentsPath.appendingPathComponent("ErrorLogs", isDirectory: true)
        
        do {
            let files = try fileManager.contentsOfDirectory(at: errorLogsPath, includingPropertiesForKeys: nil)
            return files.filter { $0.pathExtension == "log" }
        } catch {
            debugLog("❌ Failed to list log files: \(error)")
            return []
        }
    }
    
    /// Clear old log files (older than 30 days)
    func clearOldLogs() {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        
        getAllLogFiles().forEach { fileURL in
            do {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let creationDate = attributes[.creationDate] as? Date,
                   creationDate < thirtyDaysAgo {
                    try fileManager.removeItem(at: fileURL)
                    debugLog("🗑️ Deleted old log file: \(fileURL.lastPathComponent)")
                }
            } catch {
                debugLog("❌ Failed to delete log file: \(error)")
            }
        }
    }
}

// MARK: - Supporting Types

enum FeatureCategory: String {
    case authentication = "Authentication"
    case recipes = "Recipes"
    case shoppingList = "Shopping List"
    case kitchenInventory = "Kitchen Inventory"
    case mealPlanning = "Meal Planning"
    case notes = "Notes"
    case timer = "Timer"
    case settings = "Settings"
    case import = "Import"
    case export = "Export"
    case ui = "UI/UX"
    case performance = "Performance"
    case other = "Other"
}

enum FeatureStatus: String {
    case broken = "Broken - Not Working"
    case incomplete = "Incomplete - Partially Working"
    case underConstruction = "Under Construction"
    case disabled = "Temporarily Disabled"
    case deprecated = "Deprecated"
    
    var emoji: String {
        switch self {
        case .broken: return "🔴"
        case .incomplete: return "🟡"
        case .underConstruction: return "🔧"
        case .disabled: return "⏸️"
        case .deprecated: return "⚠️"
        }
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Log a broken feature when this view appears
    func logBrokenFeature(
        _ featureName: String,
        category: FeatureCategory,
        status: FeatureStatus = .broken,
        errorMessage: String
    ) -> some View {
        self.onAppear {
            BrokenFeatureLogger.shared.logBrokenFeature(
                featureName: featureName,
                category: category,
                status: status,
                errorMessage: errorMessage
            )
        }
    }
}
