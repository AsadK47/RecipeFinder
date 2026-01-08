#!/usr/bin/env python3
import os
import sys
import uuid
import re
from pathlib import Path

def find_swift_files_not_in_project(project_content, workspace_dir="RecipeFinder"):
    """Find all .swift files in workspace that aren't referenced in the project"""
    missing_files = []
    
    # Walk through the workspace directory
    workspace_path = Path(workspace_dir)
    for swift_file in workspace_path.rglob("*.swift"):
        relative_path = swift_file.relative_to(workspace_path)
        filename = swift_file.name
        
        # Skip if already in project
        if filename in project_content:
            continue
            
        # Determine the group path
        parent_path = str(relative_path.parent)
        if parent_path == '.':
            group_path = f"{workspace_dir}"
        else:
            group_path = f"{workspace_dir}/{parent_path}"
        
        missing_files.append((filename, group_path))
    
    return missing_files

# Read the project file
pbxproj_path = "RecipeFinder.xcodeproj/project.pbxproj"
with open(pbxproj_path, 'r') as f:
    content = f.read()

# Get files to add - either from command line args or scan workspace
if len(sys.argv) > 1:
    # Use files from command line arguments
    files_to_add = []
    for filepath in sys.argv[1:]:
        path_obj = Path(filepath)
        if path_obj.suffix == '.swift' and path_obj.exists():
            # Determine relative path from RecipeFinder/
            if 'RecipeFinder/' in str(path_obj):
                parts = str(path_obj).split('RecipeFinder/', 1)[1]
                parent = str(Path(parts).parent)
                group_path = f"RecipeFinder/{parent}" if parent != '.' else "RecipeFinder"
                files_to_add.append((path_obj.name, group_path))
        else:
            print(f"⚠️  Skipping {filepath} (not a Swift file or doesn't exist)")
    
    if not files_to_add:
        print("❌ No valid Swift files provided")
        sys.exit(1)
else:
    # Auto-scan workspace for missing files
    files_to_add = find_swift_files_not_in_project(content)
    
    if not files_to_add:
        print("✅ All Swift files are already in the project!")
        sys.exit(0)

print(f"\nFound {len(files_to_add)} file(s) to add:")
for filename, path in files_to_add:
    print(f"  • {filename} → {path}")

# Generate UUIDs
file_refs = {}
build_files = {}
for filename, path in files_to_add:
    file_refs[filename] = uuid.uuid4().hex[:24].upper()
    build_files[filename] = uuid.uuid4().hex[:24].upper()

print("\nGenerating references...")

# Create backup
os.system(f"cp {pbxproj_path} {pbxproj_path}.backup")
print("Backup created: project.pbxproj.backup")

# Now insert the entries
# 1. Add to PBXBuildFile section
build_file_section = "/* Begin PBXBuildFile section */"
build_file_entries = []
for filename, path in files_to_add:
    entry = f"\t\t{build_files[filename]} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[filename]} /* {filename} */; }};"
    build_file_entries.append(entry)

# Find the insertion point (after first build file entry)
match = re.search(r'(/\* Begin PBXBuildFile section \*/\n\t\t[^\n]+\n)', content)
if match:
    insert_pos = match.end()
    new_content = content[:insert_pos] + '\n'.join(build_file_entries) + '\n' + content[insert_pos:]
    content = new_content
    print("\n✓ Added PBXBuildFile entries")

# 2. Add to PBXFileReference section
file_ref_section = "/* Begin PBXFileReference section */"
file_ref_entries = []
for filename, path in files_to_add:
    entry = f"\t\t{file_refs[filename]} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};"
    file_ref_entries.append(entry)

match = re.search(r'(/\* Begin PBXFileReference section \*/\n\t\t[^\n]+\n)', content)
if match:
    insert_pos = match.end()
    new_content = content[:insert_pos] + '\n'.join(file_ref_entries) + '\n' + content[insert_pos:]
    content = new_content
    print("✓ Added PBXFileReference entries")

# 3. Add to Sources Build Phase (generic for all files)
sources_pattern = r'(/\* Sources \*/ = \{[\s\S]*?files = \(\n)'
match = re.search(sources_pattern, content)
if match:
    insert_pos = match.end()
    source_entries = []
    for filename, path in files_to_add:
        entry = f"\t\t\t\t{build_files[filename]} /* {filename} in Sources */,"
        source_entries.append(entry)
    new_content = content[:insert_pos] + '\n'.join(source_entries) + '\n' + content[insert_pos:]
    content = new_content
    print("✓ Added files to Sources Build Phase")

# Write the modified content
with open(pbxproj_path, 'w') as f:
    f.write(content)

print(f"\n✅ Successfully updated {pbxproj_path}")
print("⚠️  Note: Files added to project but not to folder groups.")
print("   Manually organize them in Xcode by dragging into appropriate groups.")
print("\nIf build fails, restore backup with:")
print(f"  cp {pbxproj_path}.backup {pbxproj_path}")
