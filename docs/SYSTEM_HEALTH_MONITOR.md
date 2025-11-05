# 🏥 System Health Monitor Guide

## Overview

The System Health Monitor automatically tracks the status of all app features and provides:
- **Admin View** (you only): Full diagnostics, feature-by-feature status, logs
- **Public View** (all users): Simple status message (operational/maintenance/issues)

## Quick Start

### 1. Add to Settings Menu

In your `MoreView.swift` or settings screen:

```swift
NavigationLink {
    SystemHealthView()
        .environmentObject(authManager)
} label: {
    HStack {
        Image(systemName: "heart.text.square")
        Text("System Status")
        Spacer()
        // Show status indicator
        Circle()
            .fill(BrokenFeatureLogger.shared.getPublicStatusColor())
            .frame(width: 8, height: 8)
    }
}
```

### 2. Add Status Banner (Optional)

Add to top of main view to show issues to all users:

```swift
VStack(spacing: 0) {
    SystemStatusBanner()  // Only shows when there are issues
    
    // Your existing content
    TabView {
        // ...
    }
}
```

## Usage Examples

### Mark a Feature as Down

```swift
// When you detect an issue
BrokenFeatureLogger.shared.setFeatureStatus(.recipes, status: .broken)

// When it's under maintenance
BrokenFeatureLogger.shared.setFeatureStatus(.mealPlanning, status: .maintenance)

// When it's slow but working
BrokenFeatureLogger.shared.setFeatureStatus(.recipeImport, status: .degraded)

// When fixed
BrokenFeatureLogger.shared.setFeatureStatus(.recipes, status: .operational)
```

### Check Feature Availability

```swift
// Before using a feature
if BrokenFeatureLogger.shared.isFeatureAvailable(.shoppingList) {
    // Show feature normally
} else {
    // Show "Feature temporarily unavailable" message
}
```

### Automatic Health Checks

The system automatically checks:
- ✅ Core Data (Persistence) → `.recipes` status
- ✅ Authentication state → `.authentication` status

Add more automatic checks in `performSystemHealthCheck()`.

## Admin Access

**Admin Email:** `asadkhanruby@gmail.com`

When you're logged in with this email:
- ✅ See detailed diagnostics for each feature
- ✅ View all logs
- ✅ Run manual health checks
- ✅ Clear old logs

## Features Monitored

All features tracked:

| Feature | Category | Auto-Check |
|---------|----------|-----------|
| Authentication | Auth | ✅ Yes |
| Recipes | Recipes | ✅ Yes |
| Recipe Search | Recipes | Manual |
| Recipe Import | Recipes | Manual |
| Favorites | Recipes | Manual |
| Shopping List | Shopping | Manual |
| Kitchen Inventory | Inventory | Manual |
| Meal Planning | Planning | Manual |
| Notes | Notes | Manual |
| Cook Timer | Timer | Manual |
| Notifications | Timer | Manual |
| Recipe Sharing | Export | Manual |
| Export/PDF | Export | Manual |
| Settings | Settings | Manual |
| Account Management | Auth | Manual |

## Status Levels

### Feature Health
- **🟢 Operational** - Working perfectly
- **🟡 Degraded** - Slower than usual, but working
- **🟠 Maintenance** - Under active maintenance
- **🔴 Broken** - Not available

### System Health
- **All Systems Operational** - Everything working
- **Degraded Performance** - Some features slow
- **Scheduled Maintenance** - Some features under maintenance
- **Service Disruption** - Critical issues

## Public vs Admin Views

### What Users See (Public)
```
┌─────────────────────────────┐
│ System Status               │
├─────────────────────────────┤
│ 🟢 All systems operational  │
└─────────────────────────────┘
```

### What You See (Admin)
```
┌─────────────────────────────────────────┐
│ System Diagnostics                      │
├─────────────────────────────────────────┤
│ Overall Health                          │
│ System Status: All Systems Operational  │
│ [Run Health Check]                      │
├─────────────────────────────────────────┤
│ Feature Status                          │
│ ✅ Authentication - Operational         │
│ ✅ Recipes - Operational                │
│ 🟡 Recipe Import - Degraded Performance │
│ 🔴 Meal Planning - Not Available        │
│ ...                                     │
├─────────────────────────────────────────┤
│ Admin Tools                             │
│ View Logs                               │
│ Clear Old Logs                          │
└─────────────────────────────────────────┘
```

## Integration Examples

### Show Maintenance Message

```swift
if !BrokenFeatureLogger.shared.isFeatureAvailable(.mealPlanning) {
    ContentUnavailableView(
        "Feature Under Maintenance",
        systemImage: "wrench.and.screwdriver",
        description: Text("Meal planning is temporarily unavailable while we make improvements.")
    )
} else {
    MealPlanningView()
}
```

### Conditional Feature Access

```swift
Button("Import Recipe") {
    if BrokenFeatureLogger.shared.isFeatureAvailable(.recipeImport) {
        showImporter = true
    } else {
        showMaintenanceAlert = true
    }
}
```

### Log Issues Automatically

```swift
// In your PersistenceController or error handling
do {
    try context.save()
} catch {
    BrokenFeatureLogger.shared.setFeatureStatus(.recipes, status: .broken)
}
```

## Best Practices

1. **Set Status When Issues Occur**
   - Detect errors → mark feature as degraded/broken
   - Before maintenance → mark as maintenance
   - After fix → mark as operational

2. **Use Automatic Checks**
   - Call `performSystemHealthCheck()` on app launch
   - Run periodically in background

3. **Keep Users Informed**
   - Show `SystemStatusBanner` when issues exist
   - Provide clear messages about what's affected

4. **Admin Monitoring**
   - Check diagnostics regularly
   - Review logs for patterns
   - Clear old logs monthly

## Files

- **BrokenFeatureLogger.swift** - Core monitoring system
- **SystemHealthView.swift** - UI for viewing status
- **Logs** - Stored in Documents/ErrorLogs/

## Future Enhancements

- [ ] Remote config for feature flags
- [ ] Push notifications to admin when critical features fail
- [ ] Analytics integration
- [ ] Automated health checks on timer
- [ ] In-app incident reports

---

**Last Updated:** 5 November 2025  
**Admin:** asadkhanruby@gmail.com
