#!/usr/bin/env python3
"""
Fix Print Statements Script
Replaces print() and debugLog() calls with proper AppLogger
"""

import os
import re
from pathlib import Path

def should_skip_file(filepath):
    """Skip certain files/directories"""
    skip_patterns = [
        '.git', '.build', 'DerivedData', '.xcodeproj', 
        'Preview Content', '.xcassets', '.xcdatamodeld',
        'fix_', 'add_files_to_xcode.py',  # Skip other scripts
        'AppLogger.swift'  # Don't modify the logger itself
    ]
    return any(pattern in str(filepath) for pattern in skip_patterns)

def extract_log_category(filepath):
    """Extract a meaningful category name from the file path"""
    name = filepath.stem
    if 'Manager' in name:
        return name.replace('Manager', '')
    elif 'View' in name:
        return name.replace('View', '')
    return name

def needs_logger_import(content):
    """Check if file already has logger setup"""
    return 'AppLogger.logger' not in content and 'private let logger' not in content

def add_logger_setup(content, category):
    """Add Logger setup after imports"""
    lines = content.split('\n')
    
    # Find last import line
    last_import_idx = -1
    for i, line in enumerate(lines):
        if line.strip().startswith('import '):
            last_import_idx = i
    
    if last_import_idx == -1:
        return content
    
    # Insert Logger setup (uses centralized AppLogger)
    logger_setup = f"""
private let logger = AppLogger.logger(category: "{category}")
"""
    
    # Insert after last import
    lines.insert(last_import_idx + 1, logger_setup)
    return '\n'.join(lines)

def fix_print_statements(content):
    """Replace print statements with logger calls"""
    
    # Pattern 1: print("literal string")
    content = re.sub(
        r'print\("([^"]+)"\)',
        r'logger.info("\1")',
        content
    )
    
    # Pattern 2: print("string with \(interpolation)")
    content = re.sub(
        r'print\("([^"]*\\[^)]+\)[^"]*)"\)',
        r'logger.info("\1")',
        content
    )
    
    # Pattern 3: debugLog("...")
    content = re.sub(
        r'debugLog\("([^"]+)"\)',
        r'logger.debug("\1")',
        content
    )
    
    # Pattern 4: debugLog("... \(interpolation)")
    content = re.sub(
        r'debugLog\("([^"]*\\[^)]+\)[^"]*)"\)',
        r'logger.debug("\1")',
        content
    )
    
    return content

def fix_error_print_statements(content):
    """Replace error prints with logger.error"""
    
    # Pattern: print with "Error", "ERROR", "❌"
    error_patterns = [
        (r'logger\.info\("(❌[^"]+)"\)', r'logger.error("\1")'),
        (r'logger\.info\("([Ee]rror:[^"]+)"\)', r'logger.error("\1")'),
        (r'logger\.info\("(ERROR[^"]+)"\)', r'logger.error("\1")'),
        (r'logger\.debug\("(❌[^"]+)"\)', r'logger.error("\1")'),
    ]
    
    for pattern, replacement in error_patterns:
        content = re.sub(pattern, replacement, content)
    
    return content

def process_file(filepath):
    """Process a single Swift file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            original_content = f.read()
        
        # Skip if no print or debugLog
        if 'print(' not in original_content and 'debugLog(' not in original_content:
            return False
        
        content = original_content
        
        # Fix print statements
        content = fix_print_statements(content)
        content = fix_error_print_statements(content)
        
        # Add logger if needed
        if content != original_content and needs_logger_import(original_content):
            category = extract_log_category(filepath)
            content = add_logger_setup(content, category)
        
        # Write back if changed
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        
        return False
        
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return False

def main():
    # Get RecipeFinder directory
    base_dir = Path(__file__).parent / "RecipeFinder"
    
    if not base_dir.exists():
        print(f"Error: {base_dir} does not exist")
        return
    
    print("🔍 Scanning for print statements...\n")
    
    modified_files = []
    
    # Process all Swift files
    for swift_file in base_dir.rglob("*.swift"):
        if should_skip_file(swift_file):
            continue
        
        if process_file(swift_file):
            modified_files.append(swift_file)
            print(f"✅ Modified: {swift_file.relative_to(base_dir.parent)}")
    
    print(f"\n{'='*60}")
    print(f"📊 Summary:")
    print(f"{'='*60}")
    print(f"Total files modified: {len(modified_files)}")
    
    if modified_files:
        print(f"\n⚠️  Note: Extensions.swift debugLog function should be removed manually")
        print(f"         after verifying all callers are updated.\n")
    else:
        print("\n✨ No print statements found!")

if __name__ == "__main__":
    main()
