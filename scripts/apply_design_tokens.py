#!/usr/bin/env python3
"""
Apply Design Tokens - Replace Magic Numbers with AppTheme Constants

Replaces hardcoded opacity values and verbose ternaries with semantic helpers:
- colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9) 
  → AppTheme.adaptiveCard(for: colorScheme)
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

# Patterns to replace (ORDER MATTERS - most specific first!)
REPLACEMENTS = [
    # ========== HELPER METHOD REPLACEMENTS (Complex Ternaries) ==========
    
    # Pattern 1: Filter chip background (double opacity)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*(?:AppTheme\.)?cardDarkMediumOpacity\)\.opacity\(0\.8\)\s*:\s*Color\(white:\s*0\.9\)\.opacity\(0\.9\)',
     'AppTheme.adaptiveFilterChip(for: colorScheme)'),
    
    # Pattern 2: Subtitle text (0.7 dark / 0.6 light) - BEFORE other 0.7/0.6 patterns
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\(0\.7\)\s*:\s*\.black\.opacity\((?:0\.6|AppTheme\.mediumEmphasisOpacity)\)',
     'AppTheme.adaptiveSubtitle(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\.white\.opacity\(0\.7\)\s*:\s*Color\.black\.opacity\((?:0\.6|AppTheme\.mediumEmphasisOpacity)\)',
     'AppTheme.adaptiveSubtitle(for: colorScheme)'),
    
    # Pattern 3: Secondary indicators like chevrons (0.5 dark / 0.4 light)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\((?:0\.5|AppTheme\.glassLightOpacity)\)\s*:\s*\.black\.opacity\((?:0\.4|AppTheme\.lowEmphasisOpacity)\)',
     'AppTheme.adaptiveSecondaryIndicator(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\.white\.opacity\((?:0\.5|AppTheme\.glassLightOpacity)\)\s*:\s*Color\.black\.opacity\((?:0\.4|AppTheme\.lowEmphasisOpacity)\)',
     'AppTheme.adaptiveSecondaryIndicator(for: colorScheme)'),
    
    # Pattern 4: High emphasis text (0.8 dark / 0.6 light)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\(0\.8\)\s*:\s*\.black\.opacity\(0\.6\)',
     'AppTheme.adaptiveHighEmphasis(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\.white\.opacity\(0\.8\)\s*:\s*Color\.black\.opacity\(0\.6\)',
     'AppTheme.adaptiveHighEmphasis(for: colorScheme)'),
    
    # Pattern 3: Standard card backgrounds
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*0\.15\)\s*:\s*Color\.white\.opacity\(0\.9\)',
     'AppTheme.adaptiveCard(for: colorScheme)'),
    
    # Pattern 4: High opacity cards
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*0\.15\)\s*:\s*Color\.white\.opacity\(0\.95\)',
     'AppTheme.adaptiveCardHigh(for: colorScheme)'),
    
    # Pattern 5: Medium cards (search bars)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*0\.2\)\s*:\s*Color\.white\.opacity\(0\.9\)',
     'AppTheme.adaptiveCardMedium(for: colorScheme)'),
    
    # Pattern 6: Glass effect
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*0\.15\)\s*:\s*Color\.white\.opacity\(0\.5\)',
     'AppTheme.adaptiveGlass(for: colorScheme)'),
    
    # Pattern 7: Adaptive shadow
    (r'Color\.black\.opacity\(colorScheme\s*==\s*\.dark\s*\?\s*0\.3\s*:\s*0\.1\)',
     'AppTheme.adaptiveShadow(for: colorScheme)'),
    
    # Pattern 8: Generic emphasis with ternary (catch-all for text colors)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\s*:\s*\.black',
     'AppTheme.adaptiveEmphasis(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\.white\s*:\s*Color\.black',
     'AppTheme.adaptiveEmphasis(for: colorScheme)'),
    
    # ========== STANDALONE CONSTANT REPLACEMENTS ==========
    
    # Pattern 9: Standalone Color(white:) values
    (r'Color\(white:\s*0\.15\)', 'Color(white: AppTheme.cardDarkOpacity)'),
    (r'Color\(white:\s*0\.2\)', 'Color(white: AppTheme.cardDarkMediumOpacity)'),
    (r'Color\(white:\s*0\.9\)', 'Color(white: AppTheme.cardLightOpacity)'),
    
    # Pattern 10: Standalone opacity values (non-ternary contexts)
    (r'\.white\.opacity\(0\.9\)(?!\))', '.white.opacity(AppTheme.cardLightOpacity)'),
    (r'\.white\.opacity\(0\.95\)', '.white.opacity(AppTheme.cardLightHighOpacity)'),
    (r'\.white\.opacity\(0\.8\)(?!\))', '.white.opacity(AppTheme.highEmphasisOpacity)'),
    (r'\.white\.opacity\(0\.7\)(?!\))', '.white.opacity(0.7)'),  # Subtitle - keep for now, context dependent
    (r'\.white\.opacity\(0\.6\)', '.white.opacity(AppTheme.mediumEmphasisOpacity)'),
    (r'\.white\.opacity\(0\.5\)', '.white.opacity(AppTheme.glassLightOpacity)'),
    (r'\.white\.opacity\(0\.4\)', '.white.opacity(AppTheme.lowEmphasisOpacity)'),
    (r'\.white\.opacity\(0\.2\)', '.white.opacity(AppTheme.overlayLightOpacity)'),
    (r'\.white\.opacity\(0\.1\)(?=\s*\))', '.white.opacity(AppTheme.dividerOpacity)'),
    
    (r'\.black\.opacity\(0\.8\)', '.black.opacity(AppTheme.highEmphasisOpacity)'),
    (r'\.black\.opacity\(0\.6\)', '.black.opacity(AppTheme.mediumEmphasisOpacity)'),
    (r'\.black\.opacity\(0\.4\)', '.black.opacity(AppTheme.lowEmphasisOpacity)'),
    (r'\.black\.opacity\(0\.3\)(?!\))', '.black.opacity(AppTheme.shadowDarkOpacity)'),
    (r'\.black\.opacity\(0\.2\)', '.black.opacity(AppTheme.overlayLightOpacity)'),
    (r'\.black\.opacity\(0\.1\)(?=\s*\))', '.black.opacity(AppTheme.dividerOpacity)'),
    
    # Pattern 11: Color.white/black.opacity patterns
    (r'Color\.white\.opacity\(0\.9\)(?!\))', 'Color.white.opacity(AppTheme.cardLightOpacity)'),
    (r'Color\.white\.opacity\(0\.95\)', 'Color.white.opacity(AppTheme.cardLightHighOpacity)'),
    (r'Color\.white\.opacity\(0\.8\)', 'Color.white.opacity(AppTheme.highEmphasisOpacity)'),
    (r'Color\.white\.opacity\(0\.6\)', 'Color.white.opacity(AppTheme.mediumEmphasisOpacity)'),
    (r'Color\.white\.opacity\(0\.5\)', 'Color.white.opacity(AppTheme.glassLightOpacity)'),
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
    print("Applying Design Tokens - Replacing Magic Numbers & Verbose Ternaries")
    print("=" * 70)
    print()
    print("Simplifications:")
    print("  Before: colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9)")
    print("  After:  AppTheme.adaptiveCard(for: colorScheme)")
    print()
    print("Design Token Mappings:")
    print("  • adaptiveCard()       → Standard card backgrounds")
    print("  • adaptiveCardMedium() → Search bars, inputs (0.2 dark)")
    print("  • adaptiveCardHigh()   → Elevated cards (0.95 light)")
    print("  • adaptiveGlass()      → Glassmorphism (0.5 light)")
    print("  • adaptiveShadow()     → Smart shadow colors")
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
