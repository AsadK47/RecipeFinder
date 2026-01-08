#!/usr/bin/env python3
"""
Apply Design Tokens - Replace Magic Numbers with AppTheme Constants

Replaces hardcoded opacity values with semantic design tokens:
- 0.15 → cardDarkOpacity (dark mode backgrounds)
- 0.9 → cardLightOpacity (light mode backgrounds)
- 0.95 → cardLightHighOpacity (elevated cards)
- 0.5 → glassLightOpacity (glassmorphism)
- 0.1 → dividerOpacity or shadowLightOpacity (context-dependent)
- 0.3 → shadowDarkOpacity (dark mode shadows)
- 0.2 → overlayLightOpacity (light overlays)
"""

import os
import re

BASE_DIR = "/Users/asad.e.khan/Documents/Personal/app_ideas/RecipeFinder/RecipeFinder"

# Skip files with intentional design-specific values
SKIP_FILES = {
    "AppTheme.swift",  # Don't modify the definitions
    "QueenEasterEggView.swift",  # Easter egg animations
    "OnboardingView.swift",  # Specific onboarding design
    "WelcomeSplashView.swift",  # Splash screen effects
    "FaceIDOnboardingSplash.swift",  # Onboarding animations
    "BiometricSetupView.swift",  # Setup screen effects
    "PasswordReminderSplashView.swift",  # Reminder animations
    "EmailConfirmationSplashView.swift",  # Confirmation effects
}

# Patterns to replace with design tokens
REPLACEMENTS = [
    # Pattern 1: Color(white: 0.15) - Dark mode card backgrounds
    (r'Color\(white:\s*0\.15\)', 'Color(white: AppTheme.cardDarkOpacity)'),
    
    # Pattern 2: Color.white.opacity(0.9) - Light mode cards
    (r'Color\.white\.opacity\(0\.9\)', 'Color.white.opacity(AppTheme.cardLightOpacity)'),
    
    # Pattern 3: Color.white.opacity(0.95) - Elevated light cards
    (r'Color\.white\.opacity\(0\.95\)', 'Color.white.opacity(AppTheme.cardLightHighOpacity)'),
    
    # Pattern 4: Color.white.opacity(0.5) - Glassmorphism
    (r'Color\.white\.opacity\(0\.5\)', 'Color.white.opacity(AppTheme.glassLightOpacity)'),
    
    # Pattern 5: .opacity(0.1) in divider/border contexts (contextual)
    # Look for .opacity(0.1) after white or black in fill/stroke contexts
    (r'(Color\.white|Color\.black)\.opacity\(0\.1\)(?=\s*\))', r'\1.opacity(AppTheme.dividerOpacity)'),
    
    # Pattern 6: Color.black.opacity(0.3) - Dark mode shadows
    (r'Color\.black\.opacity\(0\.3\)', 'Color.black.opacity(AppTheme.shadowDarkOpacity)'),
    
    # Pattern 7: Color.black.opacity(0.1) - Light mode shadows (when in shadow context)
    # This is tricky - needs to be in shadow radius context
    (r'shadow\(color:\s*Color\.black\.opacity\(0\.1\)', 'shadow(color: Color.black.opacity(AppTheme.shadowLightOpacity)'),
    
    # Pattern 8: .opacity(0.2) for overlays/backgrounds
    (r'Color\.white\.opacity\(0\.2\)', 'Color.white.opacity(AppTheme.overlayLightOpacity)'),
]

def should_skip_file(file_path):
    """Check if file should be skipped"""
    return any(skip in file_path for skip in SKIP_FILES)

def apply_design_tokens(file_path):
    """Apply design token replacements to a file"""
    if should_skip_file(file_path):
        return False
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    original_content = content
    modifications = []
    
    for pattern, replacement in REPLACEMENTS:
        matches = list(re.finditer(pattern, content))
        if matches:
            content = re.sub(pattern, replacement, content)
            modifications.append(f"{len(matches)}x {pattern.split('(')[0]}")
    
    if content != original_content:
        with open(file_path, 'w') as f:
            f.write(content)
        return modifications
    
    return False

def scan_and_apply():
    """Scan all Swift files and apply design tokens"""
    fixed_files = {}
    skipped_files = []
    
    for root, dirs, files in os.walk(BASE_DIR):
        for file in files:
            if file.endswith('.swift'):
                file_path = os.path.join(root, file)
                
                if should_skip_file(file_path):
                    skipped_files.append(file)
                    continue
                
                modifications = apply_design_tokens(file_path)
                if modifications:
                    rel_path = os.path.relpath(file_path, BASE_DIR)
                    fixed_files[rel_path] = modifications
    
    return fixed_files, skipped_files

def main():
    print("=" * 70)
    print("Applying Design Tokens - Replacing Magic Numbers")
    print("=" * 70)
    print()
    print("Design Token Mappings:")
    print("  • 0.15  → AppTheme.cardDarkOpacity")
    print("  • 0.9   → AppTheme.cardLightOpacity")
    print("  • 0.95  → AppTheme.cardLightHighOpacity")
    print("  • 0.5   → AppTheme.glassLightOpacity")
    print("  • 0.1   → AppTheme.dividerOpacity / shadowLightOpacity")
    print("  • 0.3   → AppTheme.shadowDarkOpacity")
    print("  • 0.2   → AppTheme.overlayLightOpacity")
    print()
    
    fixed_files, skipped_files = scan_and_apply()
    
    if fixed_files:
        print(f"\n✅ Applied design tokens to {len(fixed_files)} files:\n")
        for file_path, modifications in sorted(fixed_files.items()):
            print(f"   📝 {file_path}")
            for mod in modifications:
                print(f"      • {mod}")
    
    if skipped_files:
        print(f"\n⏭️  Skipped {len(skipped_files)} files (intentional design):")
        for f in sorted(set(skipped_files)):
            print(f"   • {f}")
    
    if not fixed_files:
        print("\n✨ No changes needed - design tokens already applied!")
    
    print("\n" + "=" * 70)
    print("Benefits:")
    print("=" * 70)
    print("""
✨ Maintainability: Change opacity values in ONE place (AppTheme)
🎨 Consistency: Same semantic meaning = same value everywhere
📖 Readability: Named constants > magic numbers
🛡️  Type Safety: Prevents typos (0.15 vs 0.51)
🎯 Design System: Proper design token methodology
""")
    
    print("✅ Design token migration complete!")

if __name__ == "__main__":
    main()
