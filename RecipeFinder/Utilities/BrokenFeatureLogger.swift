//
//  BrokenFeatureLogger.swift
//  RecipeFinder
//
//  System Health Monitor - Tracks feature availability and status
//

import Foundation
import UIKit
import SwiftUI

/// System Health Monitor - Detects and tracks broken/unavailable features
@MainActor
class BrokenFeatureLogger: ObservableObject {
    nonisolated(unsafe) static let shared = BrokenFeatureLogger()
    
    // MARK: - Published State
    
    @Published private(set) var featureStatuses: [AppFeature: FeatureHealth] = [:]
    @Published private(set) var systemHealth: SystemHealth = .operational
    
    // MARK: - Admin Access
    
    /// Admin email - only this user sees detailed diagnostics
    private let adminEmail = "asadkhanruby@gmail.com"
    
    /// Check if current user is admin
    func isAdmin(email: String?) -> Bool {
        return email?.lowercased() == adminEmail.lowercased()
    }
    
    private let fileManager = FileManager.default
    private var logFileURL: URL?
    
    private init() {
        setupLogFile()
        initializeFeatureStatuses()
        performSystemHealthCheck()
    }
    
    // MARK: - Feature Status Management
    
    /// Initialize all features with healthy status
    private func initializeFeatureStatuses() {
        AppFeature.allCases.forEach { feature in
            featureStatuses[feature] = .operational
        }
    }
    
    /// Update a specific feature's health status
    func setFeatureStatus(_ feature: AppFeature, status: FeatureHealth) {
        featureStatuses[feature] = status
        updateSystemHealth()
        
        // Log the change
        if status != .operational {
            logBrokenFeature(
                featureName: feature.displayName,
                category: feature.category,
                status: status.toFeatureStatus(),
                errorMessage: "Feature marked as \(status.rawValue)"
            )
        }
    }
    
    /// Get status for a specific feature
    func getFeatureStatus(_ feature: AppFeature) -> FeatureHealth {
        return featureStatuses[feature] ?? .operational
    }
    
    /// Check if a feature is available
    func isFeatureAvailable(_ feature: AppFeature) -> Bool {
        let status = getFeatureStatus(feature)
        return status == .operational || status == .degraded
    }
    
    /// Update overall system health based on feature statuses
    private func updateSystemHealth() {
        let statuses = featureStatuses.values
        
        if statuses.contains(.broken) {
            systemHealth = .majorOutage
        } else if statuses.contains(.maintenance) {
            systemHealth = .underMaintenance
        } else if statuses.contains(.degraded) {
            systemHealth = .degraded
        } else {
            systemHealth = .operational
        }
    }
    
    /// Perform automatic health checks
    func performSystemHealthCheck() {
        // Check Core Data
        let persistenceHealthy = PersistenceController.shared.isStoreLoaded
        setFeatureStatus(.recipes, status: persistenceHealthy ? .operational : .broken)
        
        // Check Authentication
        let authHealthy = AuthenticationManager.shared.isAuthenticated || AuthenticationManager.shared.isGuestMode
        setFeatureStatus(.authentication, status: authHealthy ? .operational : .degraded)
        
        // Other features default to operational unless explicitly marked
    }
    
    // MARK: - Public Status Display
    
    /// Get simple status message for public users
    func getPublicStatusMessage() -> String {
        switch systemHealth {
        case .operational:
            return "All systems operational"
        case .degraded:
            return "Some features may be slower than usual"
        case .underMaintenance:
            return "Scheduled maintenance in progress"
        case .majorOutage:
            return "We're experiencing technical difficulties"
        }
    }
    
    /// Get status color for public display
    func getPublicStatusColor() -> Color {
        switch systemHealth {
        case .operational:
            return .green
        case .degraded:
            return .yellow
        case .underMaintenance:
            return .orange
        case .majorOutage:
            return .red
        }
    }
    
    // MARK: - Admin Diagnostics
    
    /// Get detailed diagnostics (admin only)
    func getDetailedDiagnostics() -> [FeatureDiagnostic] {
        return AppFeature.allCases.map { feature in
            FeatureDiagnostic(
                feature: feature,
                status: getFeatureStatus(feature),
                lastChecked: Date()
            )
        }
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
        
        logFileURL = errorLogsPath.appendingPathComponent("system_health_\(todayString).log")
        debugLog("📝 Log file: \(logFileURL?.path ?? "unknown")")
    }
    
    // MARK: - Logging Methods (Admin Only)
    
    /// Log a broken feature with details (internal use)
    private func logBrokenFeature(
        featureName: String,
        category: FeatureCategory,
        status: FeatureStatus,
        errorMessage: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = (file as NSString).lastPathComponent
        
        let logEntry = """
        
        ═══════════════════════════════════════════════════════════════
        🔍 SYSTEM HEALTH REPORT
        ═══════════════════════════════════════════════════════════════
        Timestamp: \(timestamp)
        Feature: \(featureName)
        Category: \(category.rawValue)
        Status: \(status.emoji) \(status.rawValue)
        
        Details:
        \(errorMessage)
        
        Location:
        File: \(filename)
        Function: \(function)
        Line: \(line)
        
        Device Info:
        iOS: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.model)
        
        ═══════════════════════════════════════════════════════════════
        
        """
        
        // Write to log file
        writeToLogFile(logEntry)
        
        // Also log to console in debug mode
        #if DEBUG
        print(logEntry)
        #endif
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
    
    /// Get the log file URL for sharing (admin only)
    func getLogFileURL() -> URL? {
        return logFileURL
    }
    
    /// Get all log files (admin only)
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

/// All app features that can be monitored
enum AppFeature: String, CaseIterable, Identifiable {
    case authentication = "Authentication"
    case recipes = "Recipes"
    case recipeSearch = "Recipe Search"
    case recipeImport = "Recipe Import"
    case favorites = "Favorites"
    case shoppingList = "Shopping List"
    case kitchenInventory = "Kitchen Inventory"
    case mealPlanning = "Meal Planning"
    case notes = "Notes"
    case timer = "Cook Timer"
    case notifications = "Notifications"
    case sharing = "Recipe Sharing"
    case export = "Export/PDF"
    case settings = "Settings"
    case account = "Account Management"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var category: FeatureCategory {
        switch self {
        case .authentication, .account:
            return .authentication
        case .recipes, .recipeSearch, .recipeImport, .favorites:
            return .recipes
        case .shoppingList:
            return .shoppingList
        case .kitchenInventory:
            return .kitchenInventory
        case .mealPlanning:
            return .mealPlanning
        case .notes:
            return .notes
        case .timer, .notifications:
            return .timer
        case .sharing, .export:
            return .export
        case .settings:
            return .settings
        }
    }
}

/// Feature health status
enum FeatureHealth: String, Codable {
    case operational = "Operational"
    case degraded = "Degraded Performance"
    case maintenance = "Under Maintenance"
    case broken = "Not Available"
    
    var emoji: String {
        switch self {
        case .operational: return "✅"
        case .degraded: return "🟡"
        case .maintenance: return "🔧"
        case .broken: return "🔴"
        }
    }
    
    var color: Color {
        switch self {
        case .operational: return .green
        case .degraded: return .yellow
        case .maintenance: return .orange
        case .broken: return .red
        }
    }
    
    func toFeatureStatus() -> FeatureStatus {
        switch self {
        case .operational: return .incomplete
        case .degraded: return .incomplete
        case .maintenance: return .underConstruction
        case .broken: return .broken
        }
    }
}

/// Overall system health
enum SystemHealth: String {
    case operational = "All Systems Operational"
    case degraded = "Degraded Performance"
    case underMaintenance = "Scheduled Maintenance"
    case majorOutage = "Service Disruption"
}

/// Diagnostic information for admin view
struct FeatureDiagnostic: Identifiable {
    let id = UUID()
    let feature: AppFeature
    let status: FeatureHealth
    let lastChecked: Date
}

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

// MARK: - SwiftUI Views

/// Public-facing status banner (shown to all users)
struct SystemStatusBanner: View {
    @ObservedObject var healthMonitor = BrokenFeatureLogger.shared
    @State private var isExpanded = false
    
    var body: some View {
        if healthMonitor.systemHealth != .operational {
            VStack(spacing: 0) {
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Circle()
                            .fill(healthMonitor.getPublicStatusColor())
                            .frame(width: 8, height: 8)
                        
                        Text(healthMonitor.getPublicStatusMessage())
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(healthMonitor.getPublicStatusColor().opacity(0.1))
                }
                .buttonStyle(.plain)
                
                if isExpanded {
                    Text("We're working to resolve this as quickly as possible. Thank you for your patience.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .background(healthMonitor.getPublicStatusColor().opacity(0.05))
                }
            }
        }
    }
}

/// Admin-only diagnostics view
struct SystemHealthDiagnosticsView: View {
    @ObservedObject var healthMonitor = BrokenFeatureLogger.shared
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("System Status")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(healthMonitor.systemHealth.rawValue)
                        .foregroundColor(healthMonitor.getPublicStatusColor())
                        .fontWeight(.bold)
                }
                
                Button("Run Health Check") {
                    healthMonitor.performSystemHealthCheck()
                }
            } header: {
                Text("Overall Health")
            }
            
            Section {
                ForEach(healthMonitor.getDetailedDiagnostics()) { diagnostic in
                    HStack {
                        Text(diagnostic.status.emoji)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(diagnostic.feature.displayName)
                                .fontWeight(.medium)
                            Text(diagnostic.feature.category.rawValue)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(diagnostic.status.rawValue)
                            .font(.caption)
                            .foregroundColor(diagnostic.status.color)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Feature Status")
            }
            
            Section {
                Button("View Logs") {
                    // Open logs viewer
                }
                
                Button("Clear Old Logs") {
                    healthMonitor.clearOldLogs()
                }
                .foregroundColor(.red)
            } header: {
                Text("Admin Tools")
            }
        }
        .navigationTitle("System Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
    }
}
