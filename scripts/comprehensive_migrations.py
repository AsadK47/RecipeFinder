#!/usr/bin/env python3
"""
Comprehensive Magic Number Migration Script
Migrates all magic numbers (colors, fonts, spacing) to AppTheme constants.
"""

import re
import os
from pathlib import Path

# Files to skip (intentional design/splash screens, scripts, etc.)
SKIP_FILES = {
    "AppTheme.swift",
    "ThemeManager.swift",
    "QueenEasterEggView.swift",
    "OnboardingView.swift",
    "WelcomeSplashView.swift",
    "FaceIDOnboardingSplash.swift",
    "PasswordReminderSplashView.swift",
    "AuthenticationView.swift",
    # Skip scripts folder
}

SKIP_DIRS = {"scripts", ".git", "build", "DerivedData"}


def should_process_file(filepath: Path) -> bool:
    """Check if file should be processed."""
    if filepath.name in SKIP_FILES:
        return False
    if any(skip_dir in filepath.parts for skip_dir in SKIP_DIRS):
        return False
    return filepath.suffix == ".swift"


# MARK: - ColorScheme Ternary Patterns
# Order matters: most specific patterns first!
COLOR_SCHEME_PATTERNS = [
    # Complex nested patterns with existing constants
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*AppTheme\.cardDarkMediumOpacity\)\.opacity\(0\.8\)\s*:\s*Color\(white:\s*0\.9\)\.opacity\(0\.9\)',
     'AppTheme.adaptiveFilterChip(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*0\.2\)\.opacity\(0\.8\)\s*:\s*Color\(white:\s*0\.9\)\.opacity\(0\.9\)',
     'AppTheme.adaptiveFilterChip(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*AppTheme\.cardDarkOpacity\)\.opacity\(0\.6\)\s*:\s*Color\.white\.opacity\(0\.85\)',
     'AppTheme.adaptiveCardMedium(for: colorScheme).opacity(0.7)'),
    
    # Subtitle pattern (0.7 dark / 0.6 light or 0.7 / primary)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\(0\.7\)\s*:\s*\.black\.opacity\(0\.6\)',
     'AppTheme.adaptiveSubtitle(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\.white\.opacity\(0\.7\)\s*:\s*Color\.black\.opacity\(0\.6\)',
     'AppTheme.adaptiveSubtitle(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\(0\.7\)\s*:\s*\.primary',
     'AppTheme.adaptiveSubtitle(for: colorScheme)'),
    
    # Card text emphasis (0.95 dark / 0.75 light or 0.9 / 0.7)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\(AppTheme\.cardLightOpacity\)\s*:\s*\.black\.opacity\(0\.7\)',
     'AppTheme.adaptiveCardTextEmphasis(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\.white\.opacity\(AppTheme\.cardLightOpacity\)\s*:\s*Color\.black\.opacity\(0\.7\)',
     'AppTheme.adaptiveCardTextEmphasis(for: colorScheme)'),
    
    # High emphasis text (0.8 dark / 0.6 light)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\(0\.8\)\s*:\s*\.black\.opacity\(0\.6\)',
     'AppTheme.adaptiveHighEmphasis(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\.white\.opacity\(0\.8\)\s*:\s*Color\.black\.opacity\(0\.6\)',
     'AppTheme.adaptiveHighEmphasis(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\(AppTheme\.highEmphasisOpacity\)\s*:\s*\.black\.opacity\(AppTheme\.mediumEmphasisOpacity\)',
     'AppTheme.adaptiveHighEmphasis(for: colorScheme)'),
    
    # Medium emphasis text (0.6 dark / 0.4 light)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\(0\.6\)\s*:\s*\.black\.opacity\(0\.4\)',
     'AppTheme.adaptiveMediumEmphasis(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\.white\.opacity\(0\.6\)\s*:\s*Color\.black\.opacity\(0\.4\)',
     'AppTheme.adaptiveMediumEmphasis(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\(AppTheme\.mediumEmphasisOpacity\)\s*:\s*\.black\.opacity\(AppTheme\.mediumEmphasisOpacity\)',
     'AppTheme.adaptiveMediumEmphasis(for: colorScheme)'),
    
    # Secondary indicator (0.5 dark / 0.4 light)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\(0\.5\)\s*:\s*\.black\.opacity\(0\.4\)',
     'AppTheme.adaptiveSecondaryIndicator(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\.white\.opacity\(0\.5\)\s*:\s*Color\.black\.opacity\(0\.4\)',
     'AppTheme.adaptiveSecondaryIndicator(for: colorScheme)'),
    
    # Standard card backgrounds (0.15 dark / 0.9 light)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*0\.15\)\s*:\s*Color\.white\.opacity\(0\.9\)',
     'AppTheme.adaptiveCard(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*AppTheme\.cardDarkOpacity\)\s*:\s*Color\.white\.opacity\(AppTheme\.cardLightOpacity\)',
     'AppTheme.adaptiveCard(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*AppTheme\.cardDarkOpacity\)\s*:\s*Color\.white\.opacity\(0\.9\)',
     'AppTheme.adaptiveCard(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*AppTheme\.cardDarkOpacity\)\s*:\s*AppTheme\.adaptiveCard\(for:\s*colorScheme\)',
     'AppTheme.adaptiveCard(for: colorScheme)'),
    
    # Medium card backgrounds (0.2 dark / 0.9 light)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*0\.2\)\s*:\s*Color\.white\.opacity\(0\.9\)',
     'AppTheme.adaptiveCardMedium(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*AppTheme\.cardDarkMediumOpacity\)\s*:\s*Color\.white\.opacity\(AppTheme\.cardLightOpacity\)',
     'AppTheme.adaptiveCardMedium(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*AppTheme\.cardDarkMediumOpacity\)\s*:\s*AppTheme\.adaptiveCard\(for:\s*colorScheme\)',
     'AppTheme.adaptiveCardMedium(for: colorScheme)'),
    
    # High card backgrounds (0.15 dark / 0.95 light)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*0\.15\)\s*:\s*Color\.white\.opacity\(0\.95\)',
     'AppTheme.adaptiveCardHigh(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*AppTheme\.cardDarkOpacity\)\s*:\s*Color\.white\.opacity\(AppTheme\.cardLightHighOpacity\)',
     'AppTheme.adaptiveCardHigh(for: colorScheme)'),
    
    # Glass backgrounds (0.15 dark / 0.5 light)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*0\.15\)\s*:\s*Color\.white\.opacity\(0\.5\)',
     'AppTheme.adaptiveGlass(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\(white:\s*AppTheme\.cardDarkOpacity\)\s*:\s*Color\.white\.opacity\(AppTheme\.glassLightOpacity\)',
     'AppTheme.adaptiveGlass(for: colorScheme)'),
    
    # Shadows (0.3 dark / 0.1 light or 0.3 dark / 0.15 light)
    (r'Color\.black\.opacity\(colorScheme\s*==\s*\.dark\s*\?\s*0\.3\s*:\s*0\.1\)',
     'AppTheme.adaptiveShadow(for: colorScheme)'),
    (r'Color\.black\.opacity\(colorScheme\s*==\s*\.dark\s*\?\s*0\.3\s*:\s*0\.15\)',
     'Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15)'),  # Keep for now, might need custom helper
    (r'Color\.black\.opacity\(colorScheme\s*==\s*\.dark\s*\?\s*AppTheme\.shadowDarkOpacity\s*:\s*AppTheme\.shadowLightOpacity\)',
     'AppTheme.adaptiveShadow(for: colorScheme)'),
    
    # Simple background overlays (0.1 dark / 0.05 light)
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\.white\.opacity\(0\.1\)\s*:\s*Color\.black\.opacity\(0\.05\)',
     'Color.white.opacity(colorScheme == .dark ? AppTheme.dividerOpacity : 0.05)'),
    
    # Generic white/black toggles with opacity using constants
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\(AppTheme\.cardLightOpacity\)\s*:\s*\.primary',
     'AppTheme.adaptiveEmphasis(for: colorScheme, level: AppTheme.cardLightOpacity)'),
    
    # Simple white/black toggles (no opacity) - LAST since most generic
    (r'colorScheme\s*==\s*\.dark\s*\?\s*\.white\s*:\s*\.black(?!\.)',
     'AppTheme.adaptiveEmphasis(for: colorScheme)'),
    (r'colorScheme\s*==\s*\.dark\s*\?\s*Color\.white\s*:\s*Color\.black(?!\.)',
     'AppTheme.adaptiveEmphasis(for: colorScheme)'),
]


# MARK: - Font Size Patterns
FONT_SIZE_PATTERNS = [
    # Hero/Display sizes
    (r'\.font\(\.system\(size:\s*80\b', f'.font(.system(size: AppTheme.fontSizeHero'),
    (r'\.font\(\.system\(size:\s*75\b', f'.font(.system(size: AppTheme.fontSizeHero - 5'),  # Close to hero
    (r'\.font\(\.system\(size:\s*60\b', f'.font(.system(size: AppTheme.fontSizeDisplay'),
    (r'\.font\(\.system\(size:\s*50\b', f'.font(.system(size: AppTheme.fontSizeEmoji'),
    (r'\.font\(\.system\(size:\s*42\b', f'.font(.system(size: AppTheme.fontSizeLarge'),
    (r'\.font\(\.system\(size:\s*38\b', f'.font(.system(size: AppTheme.fontSizeMediumLarge'),
    (r'\.font\(\.system\(size:\s*36\b', f'.font(.system(size: AppTheme.fontSizeMediumLarge - 2'),
    (r'\.font\(\.system\(size:\s*34\b', f'.font(.system(size: AppTheme.fontSizeLargeTitle'),
    (r'\.font\(\.system\(size:\s*32\b', f'.font(.system(size: AppTheme.fontSizeMedium'),
    (r'\.font\(\.system\(size:\s*28\b', f'.font(.system(size: AppTheme.fontSizeTitle1'),
    (r'\.font\(\.system\(size:\s*24\b', f'.font(.system(size: AppTheme.fontSizeIcon'),
    (r'\.font\(\.system\(size:\s*22\b', f'.font(.system(size: AppTheme.fontSizeTitle2'),
    (r'\.font\(\.system\(size:\s*20\b', f'.font(.system(size: AppTheme.fontSizeTitle3'),
    (r'\.font\(\.system\(size:\s*19\b', f'.font(.system(size: AppTheme.fontSizeTitle3 - 1'),
    (r'\.font\(\.system\(size:\s*18\b', f'.font(.system(size: AppTheme.fontSizeBody + 2'),  # Between headline and body
    (r'\.font\(\.system\(size:\s*17\b', f'.font(.system(size: AppTheme.fontSizeHeadline'),
    (r'\.font\(\.system\(size:\s*16\b', f'.font(.system(size: AppTheme.fontSizeBody'),
    (r'\.font\(\.system\(size:\s*15\b', f'.font(.system(size: AppTheme.fontSizeCallout'),
    (r'\.font\(\.system\(size:\s*14\b', f'.font(.system(size: AppTheme.fontSizeSubheadline'),
    (r'\.font\(\.system\(size:\s*13\b', f'.font(.system(size: AppTheme.fontSizeFootnote'),
    (r'\.font\(\.system\(size:\s*12\b', f'.font(.system(size: AppTheme.fontSizeCaption1'),
    (r'\.font\(\.system\(size:\s*11\b', f'.font(.system(size: AppTheme.fontSizeCaption2'),
    (r'\.font\(\.system\(size:\s*10\b', f'.font(.system(size: AppTheme.fontSizeTiny'),
    (r'\.font\(\.system\(size:\s*7\b', f'.font(.system(size: AppTheme.fontSizeTinyText'),
    (r'\.font\(\.system\(size:\s*6\b', f'.font(.system(size: AppTheme.fontSizeTinyIcon'),
]


# MARK: - Spacing Patterns
SPACING_PATTERNS = [
    # HStack/VStack spacing
    (r'\bspacing:\s*48\b', f'spacing: AppTheme.spacing5XL'),
    (r'\bspacing:\s*40\b', f'spacing: AppTheme.spacing4XL'),
    (r'\bspacing:\s*32\b', f'spacing: AppTheme.spacing3XL'),
    (r'\bspacing:\s*24\b', f'spacing: AppTheme.spacingXXL'),
    (r'\bspacing:\s*20\b', f'spacing: AppTheme.spacingXL'),
    (r'\bspacing:\s*18\b', f'spacing: AppTheme.spacing18'),
    (r'\bspacing:\s*16\b', f'spacing: AppTheme.spacingLG'),
    (r'\bspacing:\s*12\b', f'spacing: AppTheme.spacingMD'),
    (r'\bspacing:\s*10\b', f'spacing: AppTheme.spacing10'),
    (r'\bspacing:\s*8\b', f'spacing: AppTheme.spacingSM'),
    (r'\bspacing:\s*6\b', f'spacing: AppTheme.spacing6'),
    (r'\bspacing:\s*5\b', f'spacing: AppTheme.spacing5'),
    (r'\bspacing:\s*4\b', f'spacing: AppTheme.spacingXS'),
    (r'\bspacing:\s*2\b', f'spacing: AppTheme.spacingXXS'),
    
    # Padding values - be more specific to avoid false positives
    (r'\.padding\((\w+,\s*)?48\)', r'.padding(\1AppTheme.spacing5XL)'),
    (r'\.padding\((\w+,\s*)?40\)', r'.padding(\1AppTheme.spacing4XL)'),
    (r'\.padding\((\w+,\s*)?32\)', r'.padding(\1AppTheme.spacing3XL)'),
    (r'\.padding\((\w+,\s*)?24\)', r'.padding(\1AppTheme.spacingXXL)'),
    (r'\.padding\((\w+,\s*)?20\)', r'.padding(\1AppTheme.spacingXL)'),
    (r'\.padding\((\w+,\s*)?16\)', r'.padding(\1AppTheme.spacingLG)'),
    (r'\.padding\((\w+,\s*)?12\)', r'.padding(\1AppTheme.spacingMD)'),
    (r'\.padding\((\w+,\s*)?10\)', r'.padding(\1AppTheme.spacing10)'),
    (r'\.padding\((\w+,\s*)?8\)', r'.padding(\1AppTheme.spacingSM)'),
    (r'\.padding\((\w+,\s*)?6\)', r'.padding(\1AppTheme.spacing6)'),
    (r'\.padding\((\w+,\s*)?4\)', r'.padding(\1AppTheme.spacingXS)'),
]


def migrate_file(filepath: Path) -> tuple[int, int, int]:
    """Migrate a single file. Returns (color_changes, font_changes, spacing_changes)."""
    try:
        content = filepath.read_text(encoding='utf-8')
        original_content = content
        
        color_count = 0
        font_count = 0
        spacing_count = 0
        
        # Apply color scheme patterns
        for pattern, replacement in COLOR_SCHEME_PATTERNS:
            matches = len(re.findall(pattern, content, re.MULTILINE))
            if matches > 0:
                content = re.sub(pattern, replacement, content, flags=re.MULTILINE)
                color_count += matches
        
        # Apply font size patterns
        for pattern, replacement in FONT_SIZE_PATTERNS:
            matches = len(re.findall(pattern, content))
            if matches > 0:
                content = re.sub(pattern, replacement, content)
                font_count += matches
        
        # Apply spacing patterns
        for pattern, replacement in SPACING_PATTERNS:
            matches = len(re.findall(pattern, content))
            if matches > 0:
                content = re.sub(pattern, replacement, content)
                spacing_count += matches
        
        # Write back if changed
        if content != original_content:
            filepath.write_text(content, encoding='utf-8')
            return color_count, font_count, spacing_count
        
        return 0, 0, 0
        
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return 0, 0, 0


def main():
    """Run migration on all Swift files."""
    recipe_finder = Path("RecipeFinder")
    
    if not recipe_finder.exists():
        print("Error: RecipeFinder directory not found")
        return
    
    print("=" * 80)
    print("COMPREHENSIVE MAGIC NUMBER MIGRATION")
    print("=" * 80)
    print("\nProcessing Swift files...")
    print(f"Skipping: {', '.join(SKIP_FILES)}\n")
    
    total_color = 0
    total_font = 0
    total_spacing = 0
    files_modified = []
    
    # Process all Swift files
    for swift_file in recipe_finder.rglob("*.swift"):
        if should_process_file(swift_file):
            color_changes, font_changes, spacing_changes = migrate_file(swift_file)
            
            if color_changes > 0 or font_changes > 0 or spacing_changes > 0:
                relative_path = swift_file.relative_to(recipe_finder)
                files_modified.append((relative_path, color_changes, font_changes, spacing_changes))
                total_color += color_changes
                total_font += font_changes
                total_spacing += spacing_changes
    
    # Print results
    print("\n" + "=" * 80)
    print("MIGRATION RESULTS")
    print("=" * 80)
    
    if files_modified:
        print(f"\n✅ Modified {len(files_modified)} files:\n")
        for path, c, f, s in sorted(files_modified):
            changes = []
            if c > 0:
                changes.append(f"{c} colors")
            if f > 0:
                changes.append(f"{f} fonts")
            if s > 0:
                changes.append(f"{s} spacing")
            print(f"  • {path}: {', '.join(changes)}")
        
        print(f"\n📊 Total Changes:")
        print(f"  • Color scheme patterns: {total_color}")
        print(f"  • Font sizes: {total_font}")
        print(f"  • Spacing/padding: {total_spacing}")
        print(f"  • GRAND TOTAL: {total_color + total_font + total_spacing}")
    else:
        print("\n✅ No changes needed - all files already use AppTheme constants!")
    
    print("\n" + "=" * 80)
    print("NEXT STEPS")
    print("=" * 80)
    print("\n1. Build project: Cmd+B in Xcode")
    print("2. Verify remaining colorScheme patterns:")
    print("   grep -r 'colorScheme ==' RecipeFinder/ --include='*.swift' | grep -v 'AppTheme.swift' | wc -l")
    print("3. Check for any remaining magic numbers:")
    print("   grep -r '\\.font(.system(size: [0-9]' RecipeFinder/ --include='*.swift' | wc -l")
    print("\n" + "=" * 80)


if __name__ == "__main__":
    main()
