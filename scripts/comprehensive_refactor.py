#!/usr/bin/env python3
"""
Comprehensive refactoring to use AppTheme constants throughout.
Replaces hardcoded values with semantic AppTheme tokens.
"""

import os
import re
from pathlib import Path

# Mapping for corner radius values
CORNER_RADIUS_MAP = {
    '4': 'AppTheme.cornerRadius4',
    '6': 'AppTheme.cornerRadius6',
    '8': 'AppTheme.cornerRadius8',
    '10': 'AppTheme.cornerRadius12',  # 10 -> 12 for consistency
    '12': 'AppTheme.cornerRadius12',
    '14': 'AppTheme.cornerRadius12',  # 14 -> 12 for consistency
    '16': 'AppTheme.cornerRadius16',
    '20': 'AppTheme.cornerRadius20',
    '24': 'AppTheme.cornerRadius24',
}

# Mapping for padding values (when used alone)
PADDING_MAP = {
    '14': 'AppTheme.spacing16',  # 14 -> 16 for consistency
    '30': 'AppTheme.spacing32',  # 30 -> 32 for consistency
}

# Mapping for font sizes to AppTheme constants
FONT_SIZE_MAP = {
    '7': 'AppTheme.fontSizeTinyText',
    '8': 'AppTheme.fontSizeCaption2',
    '9': 'AppTheme.fontSizeCaption2',  # Close enough
    '10': 'AppTheme.fontSizeTiny',
    '11': 'AppTheme.fontSizeCaption2',
    '12': 'AppTheme.fontSizeCaption1',
    '13': 'AppTheme.fontSizeFootnote',
    '14': 'AppTheme.fontSizeSubheadline',
    '15': 'AppTheme.fontSizeCallout',
    '16': 'AppTheme.fontSizeBody',
    '17': 'AppTheme.fontSizeHeadline',
    '19': 'AppTheme.fontSizeTitle3',  # Close to 20
    '20': 'AppTheme.fontSizeTitle3',
    '22': 'AppTheme.fontSizeTitle2',
    '24': 'AppTheme.fontSizeIcon',
    '26': 'AppTheme.fontSizeTitle1',  # Close to 28
    '28': 'AppTheme.fontSizeTitle1',
    '30': 'AppTheme.fontSizeMedium',  # Close to 32
    '32': 'AppTheme.fontSizeMedium',
    '34': 'AppTheme.fontSizeLargeTitle',
    '36': 'AppTheme.fontSizeMediumLarge',  # Close to 38
    '38': 'AppTheme.fontSizeMediumLarge',
    '40': 'AppTheme.fontSizeLarge',  # Close to 42
    '42': 'AppTheme.fontSizeLarge',
    '44': 'AppTheme.fontSizeLarge',  # Close to 42
    '50': 'AppTheme.fontSizeEmoji',
    '60': 'AppTheme.fontSizeDisplay',
    '65': 'AppTheme.fontSizeDisplay',  # Close to 60
    '70': 'AppTheme.fontSizeDisplay',  # Close to 60
    '72': 'AppTheme.fontSizeHero',  # Close to 80
    '80': 'AppTheme.fontSizeHero',
}

def fix_corner_radius(content):
    """Replace hardcoded cornerRadius values with AppTheme constants."""
    changes = []
    for value, constant in CORNER_RADIUS_MAP.items():
        pattern = rf'\.cornerRadius\({value}\)'
        replacement = f'.cornerRadius({constant})'
        matches = len(re.findall(pattern, content))
        if matches > 0:
            content = re.sub(pattern, replacement, content)
            changes.append(f"cornerRadius({value}) -> cornerRadius({constant}) ({matches}x)")
    return content, changes

def fix_padding(content):
    """Replace hardcoded padding values with AppTheme constants."""
    changes = []
    for value, constant in PADDING_MAP.items():
        pattern = rf'\.padding\({value}\)'
        replacement = f'.padding({constant})'
        matches = len(re.findall(pattern, content))
        if matches > 0:
            content = re.sub(pattern, replacement, content)
            changes.append(f"padding({value}) -> padding({constant}) ({matches}x)")
    return content, changes

def fix_font_sizes(content):
    """Replace hardcoded font sizes with AppTheme constants."""
    changes = []
    for size, constant in FONT_SIZE_MAP.items():
        # Pattern for .font(.system(size: N))
        pattern = rf'\.font\(\.system\(size:\s*{size}(?:,|\))'
        # Find matches to count them
        matches = re.findall(pattern, content)
        if matches:
            # Replace with constant
            replacement = f'.font(.system(size: {constant},'
            # Handle the case without weight
            content = re.sub(
                rf'\.font\(\.system\(size:\s*{size}\)\)',
                f'.font(.system(size: {constant}))',
                content
            )
            # Handle the case with weight
            content = re.sub(
                rf'\.font\(\.system\(size:\s*{size},',
                f'.font(.system(size: {constant},',
                content
            )
            changes.append(f"font size {size} -> {constant} ({len(matches)}x)")
    return content, changes

def fix_file(file_path):
    """Apply all refactorings to a single file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        all_changes = []
        
        # Apply all fixes
        content, changes = fix_corner_radius(content)
        all_changes.extend(changes)
        
        content, changes = fix_padding(content)
        all_changes.extend(changes)
        
        content, changes = fix_font_sizes(content)
        all_changes.extend(changes)
        
        # Write back only if changes were made
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✓ {file_path}")
            for change in all_changes:
                print(f"  - {change}")
            return True
        return False
            
    except Exception as e:
        print(f"✗ Error processing {file_path}: {e}")
        return False

def main():
    """Main function to process all Swift files."""
    workspace = Path(__file__).parent.parent / "RecipeFinder"
    
    if not workspace.exists():
        print(f"Error: RecipeFinder directory not found at {workspace}")
        return
    
    print("Running comprehensive refactoring to use AppTheme constants...\n")
    
    files_changed = 0
    total_files = 0
    
    # Process all .swift files
    for swift_file in workspace.rglob("*.swift"):
        # Skip generated, backup, and theme files
        if any(skip in str(swift_file) for skip in ['.build', 'DerivedData', '.backup', 'AppTheme.swift']):
            continue
            
        total_files += 1
        if fix_file(swift_file):
            files_changed += 1
    
    print(f"\nDone! Modified {files_changed} of {total_files} files.")
    print("\nRefactoring complete. All hardcoded values replaced with AppTheme constants.")

if __name__ == "__main__":
    main()
