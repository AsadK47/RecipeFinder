#!/usr/bin/env python3
"""
Comprehensive Design Token Migration - Replace ALL colorScheme Ternaries

This script aggressively replaces ALL instances of verbose colorScheme ternaries
with clean AppTheme helper methods throughout the entire codebase.
"""

import os
import re

BASE_DIR = "/Users/asad.e.khan/Documents/Personal/app_ideas/RecipeFinder/RecipeFinder"

SKIP_FILES = {
    "AppTheme.swift",
    "QueenEasterEggView.swift",
    "OnboardingView.swift",
    "WelcomeSplashView.swift",
    "FaceIDOnboardingSplash.swift",
    "BiometricSetupView.swift",
    "PasswordReminderSplashView.swift",
    "EmailConfirmationSplashView.swift",
    "AuthenticationView.swift",  # Has specific glass effects
}

def should_skip_file(file_path):
    return any(skip in file_path for skip in SKIP_FILES)

# COMPREHENSIVE PATTERN LIST (ORDER MATTERS!)
PATTERNS = [
    # ===== COMPLEX BACKGROUND PATTERNS =====
    
    # Double opacity filter chips
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*(?:AppTheme\.)?cardDarkMediumOpacity\)\.opacity\((?:0\.8|AppTheme\.highEmphasisOpacity)\)\s*:\s*Color\(white:\s*(?:0\.9|AppTheme\.cardLightOpacity)\)\.opacity\((?:0\.9|AppTheme\.cardLightOpacity)\)',
     'AppTheme.adaptiveFilterChip(for: colorScheme)'),
    
    # ===== TEXT/FOREGROUND COLOR PATTERNS =====
    
    # Subtitle text (0.7 dark / 0.6 light)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\(0\.7\)\s*:\s*\.black\.opacity\((?:0\.6|AppTheme\.mediumEmphasisOpacity)\)',
     'AppTheme.adaptiveSubtitle(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\.white\.opacity\(0\.7\)\s*:\s*Color\.black\.opacity\((?:0\.6|AppTheme\.mediumEmphasisOpacity)\)',
     'AppTheme.adaptiveSubtitle(for: colorScheme)'),
    
    # Secondary indicators (0.5 dark / 0.4 light or with constants)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\((?:0\.5|AppTheme\.glassLightOpacity)\)\s*:\s*\.black\.opacity\((?:0\.4|AppTheme\.lowEmphasisOpacity)\)',
     'AppTheme.adaptiveSecondaryIndicator(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\.white\.opacity\((?:0\.5|AppTheme\.glassLightOpacity)\)\s*:\s*Color\.black\.opacity\((?:0\.4|AppTheme\.lowEmphasisOpacity)\)',
     'AppTheme.adaptiveSecondaryIndicator(for: colorScheme)'),
    
    # High emphasis (0.8 dark / 0.6 light)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\((?:0\.8|AppTheme\.highEmphasisOpacity)\)\s*:\s*\.black\.opacity\((?:0\.6|AppTheme\.mediumEmphasisOpacity)\)',
     'AppTheme.adaptiveHighEmphasis(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\.white\.opacity\((?:0\.8|AppTheme\.highEmphasisOpacity)\)\s*:\s*Color\.black\.opacity\((?:0\.6|AppTheme\.mediumEmphasisOpacity)\)',
     'AppTheme.adaptiveHighEmphasis(for: colorScheme)'),
    
    # Medium emphasis (0.6 dark / 0.4 light)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\((?:0\.6|AppTheme\.mediumEmphasisOpacity)\)\s*:\s*\.black\.opacity\((?:0\.4|AppTheme\.lowEmphasisOpacity)\)',
     'AppTheme.adaptiveMediumEmphasis(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\.white\.opacity\((?:0\.6|AppTheme\.mediumEmphasisOpacity)\)\s*:\s*Color\.black\.opacity\((?:0\.4|AppTheme\.lowEmphasisOpacity)\)',
     'AppTheme.adaptiveMediumEmphasis(for: colorScheme)'),
    
    # Other common text emphasis patterns
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\(0\.85\)\s*:\s*\.black\.opacity\(0\.75\)',
     'AppTheme.adaptiveEmphasis(for: colorScheme, level: colorScheme == .dark ? 0.85 : 0.75)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\.white\.opacity\(0\.85\)\s*:\s*Color\.black\.opacity\(0\.75\)',
     'AppTheme.adaptiveEmphasis(for: colorScheme, level: colorScheme == .dark ? 0.85 : 0.75)'),
    
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\((?:0\.7|AppTheme\.(?:highEmphasisOpacity|mediumEmphasisOpacity))?\)\s*:\s*\.black\.opacity\((?:0\.5|AppTheme\.(?:glassLightOpacity|lowEmphasisOpacity))?\)',
     'AppTheme.adaptiveSubtitle(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\.white\.opacity\((?:0\.7|AppTheme\.(?:highEmphasisOpacity|mediumEmphasisOpacity))?\)\s*:\s*Color\.black\.opacity\((?:0\.5|AppTheme\.(?:glassLightOpacity|lowEmphasisOpacity))?\)',
     'AppTheme.adaptiveSubtitle(for: colorScheme)'),
    
    # Generic white/black toggle (no opacity)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\s*:\s*\.black',
     'AppTheme.adaptiveEmphasis(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\.white\s*:\s*Color\.black',
     'AppTheme.adaptiveEmphasis(for: colorScheme)'),
    
    # ===== BACKGROUND FILL PATTERNS =====
    
    # Standard card (0.15 dark / 0.9 light)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*(?:0\.15|AppTheme\.cardDarkOpacity)\)\s*:\s*Color\.white\.opacity\((?:0\.9|AppTheme\.cardLightOpacity)\)',
     'AppTheme.adaptiveCard(for: colorScheme)'),
    
    # High card (0.15 dark / 0.95 light)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*(?:0\.15|AppTheme\.cardDarkOpacity)\)\s*:\s*Color\.white\.opacity\((?:0\.95|AppTheme\.cardLightHighOpacity)\)',
     'AppTheme.adaptiveCardHigh(for: colorScheme)'),
    
    # Medium card (0.2 dark / 0.9 light)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*(?:0\.2|AppTheme\.cardDarkMediumOpacity)\)\s*:\s*Color\.white\.opacity\((?:0\.9|AppTheme\.cardLightOpacity)\)',
     'AppTheme.adaptiveCardMedium(for: colorScheme)'),
    
    # Glass (0.15 dark / 0.5 light)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*(?:0\.15|AppTheme\.cardDarkOpacity)\)\s*:\s*Color\.white\.opacity\((?:0\.5|AppTheme\.glassLightOpacity)\)',
     'AppTheme.adaptiveGlass(for: colorScheme)'),
    
    # AppTheme named backgrounds
    (r'colorScheme\s*==\s*\.dark\s*\?\s*AppTheme\.cardBackgroundDark\s*:\s*AppTheme\.cardBackground',
     'AppTheme.cardBackground(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*AppTheme\.elevatedCardDark\s*:\s*AppTheme\.elevatedCardLight',
     'AppTheme.elevatedCard(for: colorScheme)'),
    
    # ===== SHADOW PATTERNS =====
    (r'Color\.black\.opacity\(colorScheme\s*==\s*\.dark\s*\?\s*(?:0\.3|AppTheme\.shadowDarkOpacity)\s*:\s*(?:0\.1|AppTheme\.shadowLightOpacity)\)',
     'AppTheme.adaptiveShadow(for: colorScheme)'),
    
    # ===== STANDALONE OPACITY REPLACEMENTS =====
    (r'Color\(white:\s*0\.15\)', 'Color(white: AppTheme.cardDarkOpacity)'),
    (r'Color\(white:\s*0\.2\)', 'Color(white: AppTheme.cardDarkMediumOpacity)'),
    (r'Color\(white:\s*0\.9\)', 'Color(white: AppTheme.cardLightOpacity)'),
    
    (r'\.white\.opacity\(0\.95\)', '.white.opacity(AppTheme.cardLightHighOpacity)'),
    (r'\.white\.opacity\(0\.9\)(?!\))', '.white.opacity(AppTheme.cardLightOpacity)'),
    (r'\.white\.opacity\(0\.85\)', '.white.opacity(0.85)'),  # Keep context-specific
    (r'\.white\.opacity\(0\.8\)(?!\))', '.white.opacity(AppTheme.highEmphasisOpacity)'),
    (r'\.white\.opacity\(0\.75\)', '.white.opacity(0.75)'),  # Keep context-specific
    (r'\.white\.opacity\(0\.7\)(?!\))', '.white.opacity(0.7)'),  # Context-dependent
    (r'\.white\.opacity\(0\.6\)', '.white.opacity(AppTheme.mediumEmphasisOpacity)'),
    (r'\.white\.opacity\(0\.5\)', '.white.opacity(AppTheme.glassLightOpacity)'),
    (r'\.white\.opacity\(0\.4\)', '.white.opacity(AppTheme.lowEmphasisOpacity)'),
    (r'\.white\.opacity\(0\.3\)', '.white.opacity(0.3)'),  # Uncommon, keep as is
    (r'\.white\.opacity\(0\.2\)', '.white.opacity(AppTheme.overlayLightOpacity)'),
    (r'\.white\.opacity\(0\.1\)(?=\s*\))', '.white.opacity(AppTheme.dividerOpacity)'),
    
    (r'Color\.white\.opacity\(0\.95\)', 'Color.white.opacity(AppTheme.cardLightHighOpacity)'),
    (r'Color\.white\.opacity\(0\.9\)(?!\))', 'Color.white.opacity(AppTheme.cardLightOpacity)'),
    (r'Color\.white\.opacity\(0\.8\)', 'Color.white.opacity(AppTheme.highEmphasisOpacity)'),
    (r'Color\.white\.opacity\(0\.6\)', 'Color.white.opacity(AppTheme.mediumEmphasisOpacity)'),
    (r'Color\.white\.opacity\(0\.5\)', 'Color.white.opacity(AppTheme.glassLightOpacity)'),
    (r'Color\.white\.opacity\(0\.2\)', 'Color.white.opacity(AppTheme.overlayLightOpacity)'),
    
    (r'\.black\.opacity\(0\.9\)', '.black.opacity(0.9)'),  # High contrast, keep
    (r'\.black\.opacity\(0\.8\)', '.black.opacity(AppTheme.highEmphasisOpacity)'),
    (r'\.black\.opacity\(0\.75\)', '.black.opacity(0.75)'),  # Context-specific
    (r'\.black\.opacity\(0\.6\)', '.black.opacity(AppTheme.mediumEmphasisOpacity)'),
    (r'\.black\.opacity\(0\.5\)', '.black.opacity(AppTheme.glassLightOpacity)'),
    (r'\.black\.opacity\(0\.4\)', '.black.opacity(AppTheme.lowEmphasisOpacity)'),
    (r'\.black\.opacity\(0\.3\)(?!\))', '.black.opacity(AppTheme.shadowDarkOpacity)'),
    (r'\.black\.opacity\(0\.2\)', '.black.opacity(AppTheme.overlayLightOpacity)'),
    (r'\.black\.opacity\(0\.1\)(?=\s*\))', '.black.opacity(AppTheme.dividerOpacity)'),
]

def apply_comprehensive_tokens(file_path):
    """Apply all design token patterns to a file"""
    if should_skip_file(file_path):
        return False
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    original_content = content
    modifications = []
    
    for pattern, replacement in PATTERNS:
        matches = list(re.finditer(pattern, content))
        if matches:
            content = re.sub(pattern, replacement, content)
            modifications.append(f"{len(matches)}× matched pattern")
    
    if content != original_content:
        with open(file_path, 'w') as f:
            f.write(content)
        return len(modifications)
    
    return False

def main():
    print("=" * 80)
    print("COMPREHENSIVE Design Token Migration")
    print("=" * 80)
    print("\nReplacing ALL colorScheme ternaries with AppTheme helpers...")
    print()
    
    fixed_files = {}
    total_replacements = 0
    
    for root, dirs, files in os.walk(BASE_DIR):
        for file in files:
            if file.endswith('.swift'):
                file_path = os.path.join(root, file)
                
                if should_skip_file(file_path):
                    continue
                
                count = apply_comprehensive_tokens(file_path)
                if count:
                    rel_path = os.path.relpath(file_path, BASE_DIR)
                    fixed_files[rel_path] = count
                    total_replacements += count
    
    if fixed_files:
        print(f"\n✅ Modified {len(fixed_files)} files ({total_replacements} pattern groups):\n")
        for file_path, count in sorted(fixed_files.items()):
            print(f"   📝 {file_path} ({count} groups)")
    else:
        print("\n✨ No changes needed - all patterns already applied!")
    
    print("\n" + "=" * 80)
    print("✅ COMPREHENSIVE migration complete!")
    print("=" * 80)
    print("\nNext steps:")
    print("1. Build the project (Cmd+B)")
    print("2. Verify all colorScheme ternaries are replaced")
    print("3. Run grep search: grep -r 'colorScheme ==' RecipeFinder/ | wc -l")

if __name__ == "__main__":
    main()
