#!/usr/bin/env python3
"""
Fix Build Errors - Round 3

Fixes three distinct build errors:
1. CookingTipsManager: Add explicit self references (lines 127, 132)
2. AuthenticationManager: Move logger declaration inside class
3. AppErrorHandler: Add CustomStringConvertible conformance to ErrorSeverity enum
"""

import os
import re

# Base directory
BASE_DIR = "/Users/asad.e.khan/Documents/Personal/app_ideas/RecipeFinder"

def fix_cooking_tips_manager():
    """Fix implicit self issues in CookingTipsManager.swift"""
    file_path = os.path.join(BASE_DIR, "RecipeFinder/Persistence/Managers/CookingTipsManager.swift")
    
    print("\n📝 Fixing CookingTipsManager.swift...")
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix line 127: tips = decoded -> self.tips = decoded
    content = content.replace(
        '            tips = decoded',
        '            self.tips = decoded'
    )
    
    # Fix line 132: tips = CookingTipModel.samples -> self.tips = CookingTipModel.samples
    content = content.replace(
        '            tips = CookingTipModel.samples',
        '            self.tips = CookingTipModel.samples'
    )
    
    # Fix line 145: tips = CookingTipModel.samples (in resetToSamples)
    content = content.replace(
        '        tips = CookingTipModel.samples',
        '        self.tips = CookingTipModel.samples'
    )
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("  ✅ Fixed implicit self references in loadTips() and resetToSamples()")

def fix_authentication_manager():
    """Move logger declaration inside AuthenticationManager class"""
    file_path = os.path.join(BASE_DIR, "RecipeFinder/Persistence/Managers/AuthenticationManager.swift")
    
    print("\n📝 Fixing AuthenticationManager.swift...")
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Remove the file-scope logger declaration
    content = content.replace(
        'private let logger = AppLogger.logger(category: "Authentication")\n\n\n@MainActor',
        '@MainActor'
    )
    
    # Add logger inside the class after the shared singleton
    content = content.replace(
        '    static let shared = AuthenticationManager()\n    private let credentialManager = SecureCredentialManager.shared',
        '    static let shared = AuthenticationManager()\n    private let logger = AppLogger.logger(category: "Authentication")\n    private let credentialManager = SecureCredentialManager.shared'
    )
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("  ✅ Moved logger declaration inside class scope")

def fix_error_severity():
    """Add CustomStringConvertible conformance to ErrorSeverity enum"""
    file_path = os.path.join(BASE_DIR, "RecipeFinder/Utilities/Errors/AppErrorHandler.swift")
    
    print("\n📝 Fixing AppErrorHandler.swift...")
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Add CustomStringConvertible conformance to enum
    content = content.replace(
        'enum ErrorSeverity {',
        'enum ErrorSeverity: CustomStringConvertible {'
    )
    
    # Add description property before the icon property
    description_impl = '''    
    var description: String {
        switch self {
        case .warning: return "Warning"
        case .error: return "Error"
        case .critical: return "Critical"
        case .security: return "Security"
        }
    }
'''
    
    content = content.replace(
        '    var icon: String {',
        description_impl + '    var icon: String {'
    )
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print("  ✅ Added CustomStringConvertible conformance to ErrorSeverity")

def main():
    print("=" * 60)
    print("Build Error Fixes - Round 3")
    print("=" * 60)
    
    fix_cooking_tips_manager()
    fix_authentication_manager()
    fix_error_severity()
    
    print("\n" + "=" * 60)
    print("✅ All fixes applied successfully!")
    print("=" * 60)
    print("\nNext steps:")
    print("1. Rebuild the project in Xcode (Cmd+B)")
    print("2. Verify all build errors are resolved")

if __name__ == "__main__":
    main()
