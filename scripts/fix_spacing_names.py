#!/usr/bin/env python3
"""
Fix spacing property names from old abbreviations to numeric names.
Maps: XS->4, SM->8, MD->12, LG->16, XL->24, XXL->32
"""

import os
import re
from pathlib import Path

# Mapping from old spacing names to new numeric names
SPACING_MAP = {
    'spacingXXS': 'spacing2',
    'spacingXS': 'spacing4',
    'spacingSM': 'spacing8',
    'spacingMD': 'spacing12',
    'spacingLG': 'spacing16',
    'spacingXL': 'spacing24',
    'spacingXXL': 'spacing32',
    'spacing3XL': 'spacing40',
    'spacing4XL': 'spacing48',
}

def fix_file(file_path):
    """Fix spacing names in a single file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        changes_made = []
        
        # Replace each old spacing name with new numeric name
        for old_name, new_name in SPACING_MAP.items():
            pattern = rf'AppTheme\.{old_name}\b'
            replacement = f'AppTheme.{new_name}'
            
            matches = re.findall(pattern, content)
            if matches:
                content = re.sub(pattern, replacement, content)
                changes_made.append(f"{old_name} -> {new_name} ({len(matches)} occurrences)")
        
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
    
    print("Fixing spacing property names...\n")
    
    files_changed = 0
    total_files = 0
    
    # Process all .swift files
    for swift_file in workspace.rglob("*.swift"):
        # Skip generated and backup files
        if any(skip in str(swift_file) for skip in ['.build', 'DerivedData', '.backup']):
            continue
            
        total_files += 1
        if fix_file(swift_file):
            files_changed += 1
    
    print(f"\nDone! Modified {files_changed} of {total_files} files.")

if __name__ == "__main__":
    main()
