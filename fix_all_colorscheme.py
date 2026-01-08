#!/usr/bin/env python3
import re
import sys
from pathlib import Path

def fix_colorscheme_patterns(file_path):
    """Replace all old colorScheme patterns with the new centralized modifier."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Pattern 1: .foregroundColor(colorScheme == .dark ? .white : .black)
    # Replace with: .adaptiveForegroundColor()
    content = re.sub(
        r'\.foregroundColor\(colorScheme\s*==\s*\.dark\s*\?\s*\.white\s*:\s*\.black\)',
        r'.adaptiveForegroundColor()',
        content
    )
    
    # Pattern 2: .foregroundColor(Color(colorScheme == .dark ? .white : .black).opacity(0.X))
    # Replace with: .adaptiveForegroundColor(opacity: 0.X)
    content = re.sub(
        r'\.foregroundColor\(Color\(colorScheme\s*==\s*\.dark\s*\?\s*\.white\s*:\s*\.black\)\.opacity\(([\d.]+)\)\)',
        r'.adaptiveForegroundColor(opacity: \1)',
        content
    )
    
    # Pattern 3: .tint(colorScheme == .dark ? .white : .black)
    # Replace with: .tint(AppTheme.textColor(for: colorScheme))
    content = re.sub(
        r'\.tint\(colorScheme\s*==\s*\.dark\s*\?\s*\.white\s*:\s*\.black\)',
        r'.tint(AppTheme.textColor(for: colorScheme))',
        content
    )
    
    # Pattern 4: .foregroundStyle(colorScheme == .dark ? .white : .black)
    # Replace with: .foregroundStyle(AppTheme.textColor(for: colorScheme))
    content = re.sub(
        r'\.foregroundStyle\(colorScheme\s*==\s*\.dark\s*\?\s*\.white\s*:\s*\.black\)',
        r'.foregroundStyle(AppTheme.textColor(for: colorScheme))',
        content
    )
    
    # Pattern 5: Complex ternary with disabled states (keep as-is for now, needs manual review)
    # isDisabled ? (colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.3)) : (colorScheme == .dark ? .white : .black)
    
    # Pattern 6: In parameter positions like `color: colorScheme == .dark ? .white : .black`
    # Replace with: `color: AppTheme.textColor(for: colorScheme)`
    content = re.sub(
        r'(\w+):\s*colorScheme\s*==\s*\.dark\s*\?\s*\.white\s*:\s*\.black(?!\))',
        r'\1: AppTheme.textColor(for: colorScheme)',
        content
    )
    
    # Pattern 7: iconColor: colorScheme == .dark ? .white : .black,
    content = re.sub(
        r'iconColor:\s*colorScheme\s*==\s*\.dark\s*\?\s*\.white\s*:\s*\.black,',
        r'iconColor: AppTheme.textColor(for: colorScheme),',
        content
    )
    
    # Pattern 8: Nested ternary in .foregroundColor like badge.isUnlocked ? (colorScheme == .dark ? .white : .black) : .gray
    # Replace with: badge.isUnlocked ? AppTheme.textColor(for: colorScheme) : .gray
    content = re.sub(
        r'\.foregroundColor\((\w+)\s*\?\s*\(colorScheme\s*==\s*\.dark\s*\?\s*\.white\s*:\s*\.black\)\s*:\s*',
        r'.foregroundColor(\1 ? AppTheme.textColor(for: colorScheme) : ',
        content
    )
    
    # Pattern 9: selectedTag == tag ? .white : (colorScheme == .dark ? .white : .black)
    # Replace with: selectedTag == tag ? .white : AppTheme.textColor(for: colorScheme)
    content = re.sub(
        r'(\w+)\s*==\s*(\w+)\s*\?\s*\.white\s*:\s*\(colorScheme\s*==\s*\.dark\s*\?\s*\.white\s*:\s*\.black\)',
        r'\1 == \2 ? .white : AppTheme.textColor(for: colorScheme)',
        content
    )
    
    # Pattern 10: isSelected ? .white : (colorScheme == .dark ? .white : .black)
    content = re.sub(
        r'isSelected\s*\?\s*\.white\s*:\s*\(colorScheme\s*==\s*\.dark\s*\?\s*\.white\s*:\s*\.black\)',
        r'isSelected ? .white : AppTheme.textColor(for: colorScheme)',
        content
    )
    
    # Pattern 11: viewMode == mode ? (colorScheme == .dark ? .white : .black) : (colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
    # Replace with: viewMode == mode ? AppTheme.textColor(for: colorScheme) : AppTheme.textColor(for: colorScheme, opacity: 0.6)
    content = re.sub(
        r'(\w+)\s*==\s*(\w+)\s*\?\s*\(colorScheme\s*==\s*\.dark\s*\?\s*\.white\s*:\s*\.black\)\s*:\s*\(colorScheme\s*==\s*\.dark\s*\?\s*\.white\.opacity\(([\d.]+)\)\s*:\s*\.black\.opacity\(([\d.]+)\)\)',
        r'\1 == \2 ? AppTheme.textColor(for: colorScheme) : AppTheme.textColor(for: colorScheme, opacity: \3)',
        content
    )
    
    # Pattern 12: valueColor == .primary ? (colorScheme == .dark ? .white : .black) : valueColor
    content = re.sub(
        r'(\w+)\s*==\s*\.primary\s*\?\s*\(colorScheme\s*==\s*\.dark\s*\?\s*\.white\s*:\s*\.black\)\s*:\s*\1',
        r'\1 == .primary ? AppTheme.textColor(for: colorScheme) : \1',
        content
    )
    
    # Pattern 13: return colorScheme == .dark ? .white : .black (in computed properties)
    # DO NOT change this automatically - needs manual review to ensure it's not a Color return type
    
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    views_dir = Path('/Users/asad.e.khan/Documents/Personal/app_ideas/RecipeFinder/RecipeFinder/Views')
    
    if not views_dir.exists():
        print(f"Error: {views_dir} does not exist")
        sys.exit(1)
    
    modified_files = []
    
    for swift_file in views_dir.rglob('*.swift'):
        if fix_colorscheme_patterns(swift_file):
            modified_files.append(swift_file)
            print(f"Modified: {swift_file.relative_to(views_dir.parent)}")
    
    print(f"\nTotal files modified: {len(modified_files)}")

if __name__ == '__main__':
    main()
