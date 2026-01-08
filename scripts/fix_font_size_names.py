#!/usr/bin/env python3
"""
Replace semantic font size names with numeric ones for consistency with spacing.
fontSize80 is clear. fontSizeHero requires interpretation.
"""

import os
import re
from pathlib import Path

# Map old semantic names to new numeric names
FONT_SIZE_MAP = {
    'fontSizeTinyIcon': 'fontSize6',
    'fontSizeTinyText': 'fontSize7',
    'fontSizeCaption2': 'fontSize11',
    'fontSizeCaption1': 'fontSize12',
    'fontSizeFootnote': 'fontSize13',
    'fontSizeSubheadline': 'fontSize14',
    'fontSizeCallout': 'fontSize15',
    'fontSizeBody': 'fontSize16',
    'fontSizeHeadline': 'fontSize17',
    'fontSizeTiny': 'fontSize10',
    'fontSizeTitle3': 'fontSize20',
    'fontSizeTitle2': 'fontSize22',
    'fontSizeIcon': 'fontSize24',
    'fontSizeTitle1': 'fontSize28',
    'fontSizeMedium': 'fontSize32',
    'fontSizeLargeTitle': 'fontSize34',
    'fontSizeMediumLarge': 'fontSize38',
    'fontSizeLarge': 'fontSize42',
    'fontSizeEmoji': 'fontSize50',
    'fontSizeDisplay': 'fontSize60',
    'fontSizeHero': 'fontSize80',
}

def fix_file(file_path):
    """Replace semantic font size names with numeric equivalents."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        changes_made = []
        
        # Replace each old name with new numeric name
        for old_name, new_name in FONT_SIZE_MAP.items():
            pattern = rf'AppTheme\.{old_name}\b'
            replacement = f'AppTheme.{new_name}'
            
            matches = re.findall(pattern, content)
            if matches:
                content = re.sub(pattern, replacement, content)
                changes_made.append(f"{old_name} -> {new_name} ({len(matches)}x)")
        
        # Write back only if changes were made
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✓ {file_path}")
            for change in changes_made:
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
    
    print("Replacing semantic font size names with numeric names...\n")
    
    files_changed = 0
    total_files = 0
    
    # Process all .swift files except AppTheme.swift (it has both)
    for swift_file in workspace.rglob("*.swift"):
        if any(skip in str(swift_file) for skip in ['.build', 'DerivedData', '.backup', 'AppTheme.swift']):
            continue
            
        total_files += 1
        if fix_file(swift_file):
            files_changed += 1
    
    print(f"\nDone! Modified {files_changed} of {total_files} files.")

if __name__ == "__main__":
    main()
