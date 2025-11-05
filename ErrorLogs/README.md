# 📁 Error Logs Directory

This folder contains error logs and screenshots for debugging broken functionality in RecipeFinder.

## 📂 Structure

```
ErrorLogs/
├── BROKEN_FEATURES_REPORT.md    # Comprehensive list of all broken features
├── broken_features_*.log         # Daily log files with error details
├── Screenshots/                  # Automatically captured screenshots
│   └── FeatureName_timestamp.png
└── README.md                     # This file
```

## 📝 Log Files

### Daily Logs
- **Format:** `broken_features_YYYY-MM-DD.log`
- **Content:** Timestamped entries with full error details
- **Retention:** 30 days (auto-cleaned)

### Example Log Entry
```
═══════════════════════════════════════════════════════════════
🐛 BROKEN FEATURE REPORT
═══════════════════════════════════════════════════════════════
Timestamp: 2025-11-05T04:30:11Z
Feature: Apple Sign In
Category: Authentication
Status: 🔧 Under Construction

Error Message:
Feature requires Apple Developer Program enrollment and
Sign in with Apple capability configuration.

Location:
File: AuthenticationView.swift
Function: signInWithApple()
Line: 65

Device Info:
iOS: 18.1
Device: iPhone
Name: Asad's iPhone

Screenshot: ✅ Saved
═══════════════════════════════════════════════════════════════
```

## 📸 Screenshots

### Automatic Capture
Screenshots are automatically saved when logged using:
```swift
BrokenFeatureLogger.shared.captureScreenshot()
```

### Manual Capture
```swift
if let screenshot = BrokenFeatureLogger.shared.captureScreenshot() {
    BrokenFeatureLogger.shared.logBrokenFeature(
        featureName: "Feature Name",
        category: .appropriate,
        status: .broken,
        errorMessage: "What went wrong",
        screenshot: screenshot
    )
}
```

### Naming Convention
`FeatureName_UnixTimestamp.png`

Example: `Apple_Sign_In_1699234211.png`

## 🔍 Accessing Logs

### In Code
```swift
// Get current log file
let logURL = BrokenFeatureLogger.shared.getLogFileURL()

// Get all log files
let allLogs = BrokenFeatureLogger.shared.getAllLogFiles()

// Clear old logs (30+ days)
BrokenFeatureLogger.shared.clearOldLogs()
```

### On Device
Logs are stored in:
```
App Container/Documents/ErrorLogs/
```

Access via:
1. Xcode → Window → Devices and Simulators
2. Select device → Installed Apps → RecipeFinder
3. Download Container → Documents → ErrorLogs

## 📋 Log Categories

- `Authentication` - Login, signup, Face ID issues
- `Recipes` - Recipe CRUD operations
- `Shopping List` - Shopping list functionality
- `Kitchen Inventory` - Kitchen management
- `Meal Planning` - Meal planning features
- `Notes` - Notes system
- `Timer` - Cook timer issues
- `Settings` - App settings
- `Import` - Recipe import problems
- `Export` - Export/sharing issues
- `UI/UX` - Interface problems
- `Performance` - Performance issues
- `Other` - Miscellaneous

## 🎯 Status Types

- 🔴 **Broken** - Feature completely not working
- 🟡 **Incomplete** - Feature partially working
- 🔧 **Under Construction** - Feature intentionally disabled
- ⏸️ **Disabled** - Temporarily turned off
- ⚠️ **Deprecated** - Being phased out

## 🛠️ Quick Usage Guide

### Log a Simple Issue
```swift
BrokenFeatureLogger.shared.logIssue(
    "Short description of problem",
    category: .recipes
)
```

### Log Detailed Issue with Screenshot
```swift
if let screenshot = BrokenFeatureLogger.shared.captureScreenshot() {
    BrokenFeatureLogger.shared.logBrokenFeature(
        featureName: "Apple Sign In",
        category: .authentication,
        status: .underConstruction,
        errorMessage: "Requires Apple Developer Program",
        screenshot: screenshot
    )
}
```

### Log in SwiftUI View
```swift
SomeView()
    .logBrokenFeature(
        "Feature Name",
        category: .recipes,
        status: .broken,
        errorMessage: "Description"
    )
```

## 🗑️ Maintenance

### Automatic Cleanup
- Logs older than 30 days are automatically deleted
- Call `clearOldLogs()` manually if needed

### Manual Cleanup
Delete files directly from:
```
Documents/ErrorLogs/
```

## 📊 Current Status

See [BROKEN_FEATURES_REPORT.md](./BROKEN_FEATURES_REPORT.md) for:
- Complete list of broken features
- Feature categories and priorities
- Testing checklist
- Fix roadmap

## 🔐 Privacy Note

⚠️ **Important:** Log files may contain:
- Device information
- App state details
- Error messages
- Screenshots of app UI

**Do NOT share logs publicly** without reviewing content first.

---

**Last Updated:** 5 November 2025
**Maintained by:** RecipeFinder Development Team
