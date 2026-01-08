#!/usr/bin/env python3
"""
Fix Remaining Hardcoded Colors

Converts hardcoded Color literals to AppTheme equivalents:
- Color.white/black opacity variations
- Color.gray for placeholders
- Color.blue/green for status indicators
- Preserves intentional design colors (easter eggs, onboarding animations)
"""

import os
import re

BASE_DIR = "/Users/asad.e.khan/Documents/Personal/app_ideas/RecipeFinder/RecipeFinder"

# Files to skip (intentional design/animation colors)
SKIP_FILES = {
    "QueenEasterEggView.swift",  # Easter egg with specific design
}

def should_skip_file(file_path):
    """Check if file should be skipped"""
    return any(skip in file_path for skip in SKIP_FILES)

def fix_color_references(file_path):
    """Fix hardcoded color references in a file"""
    if should_skip_file(file_path):
        return False
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    original_content = content
    modified = False
    
    # Pattern 1: Color.white.opacity(...) -> adaptive white
    # But keep very specific opacity values for onboarding/splash screens
    if "OnboardingView" not in file_path and "SplashView" not in file_path and "BiometricSetupView" not in file_path:
        # Generic white backgrounds
        if "Color.white.opacity(0.9)" in content:
            content = content.replace(
                "Color.white.opacity(0.9)",
                "colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9)"
            )
            modified = True
        
        if "Color.white.opacity(0.95)" in content:
            content = content.replace(
                "Color.white.opacity(0.95)",
                "colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.95)"
            )
            modified = True
    
    # Pattern 2: Color.gray.opacity(...) for placeholders
    content = re.sub(
        r'Color\.gray\.opacity\((0\.\d+)\)',
        r'AppTheme.secondaryText.opacity(\1)',
        content
    )
    
    # Pattern 3: Color.black.opacity(...) for shadows (keep as is, shadows are intentional)
    # Pattern 4: Color.blue for status/accent
    if "Color.blue" in content and "DifficultyBarsView" in file_path:
        content = content.replace(
            "Color.blue",
            "AppTheme.accent"
        )
        modified = True
    
    if "Color.blue" in content and "ModernCircleButton" in file_path:
        content = content.replace(
            "Color.blue",
            "AppTheme.accent"
        )
        modified = True
    
    # Pattern 5: Color.orange for warnings
    if "Color.orange" in content and "OfflineBanner" in file_path:
        content = content.replace(
            ".background(Color.orange)",
            ".background(AppTheme.warning)"
        )
        modified = True
    
    # Pattern 6: Color.green for success states
    content = re.sub(
        r'Color\.green\.opacity\((0\.\d+)\)',
        r'AppTheme.success.opacity(\1)',
        content
    )
    
    # Pattern 7: Color.secondary (system) usage - keep as is, it's adaptive
    
    # Pattern 8: UIColor.white/black - keep for UIKit components
    
    if content != original_content:
        with open(file_path, 'w') as f:
            f.write(content)
        return True
    
    return False

def scan_and_fix():
    """Scan all Swift files and fix color references"""
    fixed_files = []
    skipped_files = []
    
    for root, dirs, files in os.walk(BASE_DIR):
        for file in files:
            if file.endswith('.swift'):
                file_path = os.path.join(root, file)
                
                if should_skip_file(file_path):
                    skipped_files.append(file)
                    continue
                
                if fix_color_references(file_path):
                    rel_path = os.path.relpath(file_path, BASE_DIR)
                    fixed_files.append(rel_path)
    
    return fixed_files, skipped_files

def main():
    print("=" * 70)
    print("Fixing Remaining Hardcoded Colors")
    print("=" * 70)
    print()
    
    fixed_files, skipped_files = scan_and_fix()
    
    if fixed_files:
        print(f"\n✅ Fixed {len(fixed_files)} files:")
        for f in sorted(fixed_files):
            print(f"   • {f}")
    
    if skipped_files:
        print(f"\n⏭️  Skipped {len(skipped_files)} files (intentional design):")
        for f in sorted(skipped_files):
            print(f"   • {f}")
    
    if not fixed_files:
        print("\n✨ No automatic fixes applied")
        print("   Remaining hardcoded colors are intentional design choices")
    
    print("\n" + "=" * 70)
    print("Summary of Remaining Hardcoded Colors:")
    print("=" * 70)
    print("""
The following hardcoded colors are INTENTIONAL and should NOT be changed:

1. Onboarding/Splash Screens:
   - Use specific white.opacity() values for glassmorphism effects
   - These are carefully tuned for visual design
   
2. Easter Eggs (QueenEasterEggView):
   - Uses vibrant colors (yellow, orange, pink, purple) for specific effects
   - Part of the design identity of the easter egg
   
3. Shadow Colors:
   - Color.black.opacity(...) for shadows is standard and intentional
   - Shadows should remain as black with opacity
   
4. UIColor usage:
   - UIColor.white/black in UIKit contexts (navigation bars, etc.)
   - These are system-level UI that needs specific colors

5. Gradient Effects:
   - Some views use color gradients for visual effects
   - These are part of the designed experience
""")
    print("\n✅ Color refactoring complete!")
    print("   Core functionality now uses AppTheme system")
    print("   Design-specific colors preserved for UX")

if __name__ == "__main__":
    main()
