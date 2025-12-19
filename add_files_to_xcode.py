#!/usr/bin/env python3
import os
import uuid
import re

# Read the project file
pbxproj_path = "RecipeFinder.xcodeproj/project.pbxproj"
with open(pbxproj_path, 'r') as f:
    content = f.read()

# Generate unique UUIDs for each file (2 per file: FileReference and BuildFile)
files_to_add = [
    ("QuickSnackSheet.swift", "RecipeFinder/Components"),
    ("DietaryInfo.swift", "RecipeFinder/Models"),
    ("NutritionalTips.swift", "RecipeFinder/Models"),
    ("NutritionalTipsView.swift", "RecipeFinder/Views/Settings")
]

# Generate UUIDs
file_refs = {}
build_files = {}
for filename, path in files_to_add:
    file_refs[filename] = uuid.uuid4().hex[:24].upper()
    build_files[filename] = uuid.uuid4().hex[:24].upper()
    print(f"{filename}: FileRef={file_refs[filename]}, BuildFile={build_files[filename]}")

# Create backup
os.system(f"cp {pbxproj_path} {pbxproj_path}.backup")
print("\nBackup created: project.pbxproj.backup")

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

# 3. Add to Components group for QuickSnackSheet.swift
components_pattern = r'(/\* Components \*/ = \{[\s\S]*?children = \(\n)'
match = re.search(components_pattern, content)
if match:
    insert_pos = match.end()
    entry = f"\t\t\t\t{file_refs['QuickSnackSheet.swift']} /* QuickSnackSheet.swift */,\n"
    new_content = content[:insert_pos] + entry + content[insert_pos:]
    content = new_content
    print("✓ Added QuickSnackSheet.swift to Components group")

# 4. Add to Models groups
# Find Models section and add DietaryInfo.swift and NutritionalTips.swift
# Look for the Models group that contains Recipe folder
models_pattern = r'(9E4DC75C2E9C1B4500E17DDF /\* Models \*/[\s\S]*?children = \(\n)'
match = re.search(models_pattern, content)
if match:
    insert_pos = match.end()
    entries = f"\t\t\t\t{file_refs['DietaryInfo.swift']} /* DietaryInfo.swift */,\n\t\t\t\t{file_refs['NutritionalTips.swift']} /* NutritionalTips.swift */,\n"
    new_content = content[:insert_pos] + entries + content[insert_pos:]
    content = new_content
    print("✓ Added DietaryInfo.swift and NutritionalTips.swift to Models group")

# 5. Add to Settings View group for NutritionalTipsView.swift
settings_pattern = r'(9E77ABF62EB452EF00666BB0 /\* Settings \*/[\s\S]*?children = \(\n)'
match = re.search(settings_pattern, content)
if match:
    insert_pos = match.end()
    entry = f"\t\t\t\t{file_refs['NutritionalTipsView.swift']} /* NutritionalTipsView.swift */,\n"
    new_content = content[:insert_pos] + entry + content[insert_pos:]
    content = new_content
    print("✓ Added NutritionalTipsView.swift to Settings group")

# 6. Add to Sources Build Phase
sources_pattern = r'(9EB04E5B2EB4704F0033C093 /\* MoreView\.swift in Sources \*/,\n)'
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
print("\nIf build still fails, restore backup with:")
print(f"  cp {pbxproj_path}.backup {pbxproj_path}")
