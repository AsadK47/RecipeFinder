#!/usr/bin/env python3
"""
Analyze AccountView.swift to identify state management issues.
This script identifies:
1. Duplicate @State variables
2. Shared properties across managers
3. Redundant computed properties
4. Suggested consolidation
"""

import re
from pathlib import Path

def analyze_account_view():
    account_view_path = Path(__file__).parent.parent / "RecipeFinder" / "Views" / "Account" / "AccountView.swift"
    
    if not account_view_path.exists():
        print(f"Error: {account_view_path} not found")
        return
    
    content = account_view_path.read_text()
    
    print("=" * 80)
    print("ACCOUNT VIEW STATE ANALYSIS")
    print("=" * 80)
    
    # Find all state properties
    state_vars = re.findall(r'@State\s+private\s+var\s+(\w+):\s*([^=\n]+)', content)
    app_storage = re.findall(r'@AppStorage\([^)]+\)\s+private\s+var\s+(\w+):\s*([^=\n]+)', content)
    state_objects = re.findall(r'@StateObject\s+private\s+var\s+(\w+)\s*=\s*([^\n]+)', content)
    
    print("\n1. STATE VARIABLES (@State):")
    print("-" * 80)
    for name, type_info in state_vars:
        print(f"  • {name}: {type_info.strip()}")
    
    print(f"\n  Total: {len(state_vars)} state variables")
    
    print("\n2. APP STORAGE (@AppStorage):")
    print("-" * 80)
    for name, type_info in app_storage:
        print(f"  • {name}: {type_info.strip()}")
    
    print("\n3. STATE OBJECTS (@StateObject):")
    print("-" * 80)
    for name, init in state_objects:
        print(f"  • {name} = {init.strip()}")
    
    # Find computed properties
    computed = re.findall(r'private\s+var\s+(\w+):\s*String\s*\{[^}]+\}', content, re.DOTALL)
    
    print("\n4. COMPUTED PROPERTIES (String):")
    print("-" * 80)
    for prop in computed:
        print(f"  • {prop}")
    
    # Identify issues
    print("\n" + "=" * 80)
    print("IDENTIFIED ISSUES")
    print("=" * 80)
    
    issues = []
    
    # Issue 1: Too many state variables
    if len(state_vars) > 10:
        issues.append(f"⚠️  Too many @State variables ({len(state_vars)})")
        issues.append("   → Consider grouping related state into view models or structs")
    
    # Issue 2: Multiple managers
    manager_count = len([s for s in state_objects if 'Manager' in s[1]])
    if manager_count > 2:
        issues.append(f"⚠️  Multiple managers ({manager_count})")
        issues.append("   → Consider consolidating into a single view model")
    
    # Issue 3: Duplicate data sources
    if 'displayName' in computed and 'displayEmail' in computed:
        issues.append("⚠️  Duplicate data sources detected")
        issues.append("   → authManager.currentUser vs accountManager properties")
        issues.append("   → Choose one source of truth")
    
    # Issue 4: Show-related booleans
    show_vars = [name for name, _ in state_vars if name.startswith('showing') or name.startswith('show')]
    if len(show_vars) > 5:
        issues.append(f"⚠️  Too many 'show' state variables ({len(show_vars)})")
        issues.append("   → Consider using an enum for modal/sheet state")
    
    for issue in issues:
        print(issue)
    
    # Recommendations
    print("\n" + "=" * 80)
    print("RECOMMENDATIONS")
    print("=" * 80)
    
    recommendations = [
        "1. Create AccountViewState struct to group related @State variables",
        "2. Consolidate authManager.currentUser as single source of truth",
        "3. Create enum for sheet presentation instead of multiple booleans",
        "4. Move profile editing logic to separate view/view model",
        "5. Consider extracting sections into separate SwiftUI views"
    ]
    
    for rec in recommendations:
        print(f"✓ {rec}")
    
    print("\n" + "=" * 80)
    print("SUGGESTED REFACTORING")
    print("=" * 80)
    
    refactoring = """
// BEFORE: Multiple @State variables
@State private var showingSignOutAlert = false
@State private var showingDeleteAccountAlert = false
@State private var showingPrivacyPolicy = false
@State private var showImagePicker = false
@State private var showPasswordVerification = false

// AFTER: Single enum-based state
enum AccountSheet: Identifiable {
    case signOutAlert
    case deleteAccountAlert
    case privacyPolicy
    case imagePicker
    case passwordVerification
    
    var id: Int { hashValue }
}

@State private var activeSheet: AccountSheet?

// Usage:
.sheet(item: $activeSheet) { sheet in
    switch sheet {
    case .privacyPolicy: PrivacyPolicyView()
    case .imagePicker: ImagePicker(image: $profileImage)
    case .passwordVerification: PasswordVerificationSheet(...)
    // ...
    }
}
"""
    
    print(refactoring)
    
    print("\n" + "=" * 80)

if __name__ == "__main__":
    analyze_account_view()
