#!/bin/bash

# Script to remove Firebase package dependencies from Xcode project
# This must be run to clean up Firebase remnants

set -e

echo "🧹 Removing Firebase from RecipeFinder..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

PROJECT_FILE="RecipeFinder.xcodeproj/project.pbxproj"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Error: Could not find project.pbxproj"
    exit 1
fi

echo "📝 Backing up project file..."
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"

echo "🔍 Removing Firebase package references..."

# Remove Firebase from PBXBuildFile section
sed -i '' '/FirebaseAnalytics in Frameworks/d' "$PROJECT_FILE"
sed -i '' '/FirebaseAuth in Frameworks/d' "$PROJECT_FILE"
sed -i '' '/FirebaseFirestore in Frameworks/d' "$PROJECT_FILE"
sed -i '' '/9EA9CC39.*FirebaseAnalytics/d' "$PROJECT_FILE"
sed -i '' '/9EA9CC3B.*FirebaseAuth/d' "$PROJECT_FILE"
sed -i '' '/9EA9CC3D.*FirebaseFirestore/d' "$PROJECT_FILE"

# Remove from Frameworks section
sed -i '' '/9EA9CC39.*\/\* FirebaseAnalytics/d' "$PROJECT_FILE"
sed -i '' '/9EA9CC3B.*\/\* FirebaseAuth/d' "$PROJECT_FILE"
sed -i '' '/9EA9CC3D.*\/\* FirebaseFirestore/d' "$PROJECT_FILE"

# Remove package references
sed -i '' '/9EA9CC37.*firebase-ios-sdk/d' "$PROJECT_FILE"
sed -i '' '/XCRemoteSwiftPackageReference.*firebase-ios-sdk/d' "$PROJECT_FILE"
sed -i '' '/repositoryURL.*firebase-ios-sdk/d' "$PROJECT_FILE"
sed -i '' '/9EA9CC38.*FirebaseAnalytics.*{/,/};/d' "$PROJECT_FILE"
sed -i '' '/9EA9CC3A.*FirebaseAuth.*{/,/};/d' "$PROJECT_FILE"
sed -i '' '/9EA9CC3C.*FirebaseFirestore.*{/,/};/d' "$PROJECT_FILE"

echo "🧽 Cleaning derived data and caches..."
rm -rf "$PROJECT_ROOT/DerivedData"
rm -rf ~/Library/Developer/Xcode/DerivedData/RecipeFinder-*
rm -rf "$PROJECT_ROOT/.build"

echo "📦 Resolving package dependencies..."
xcodebuild -resolvePackageDependencies -project RecipeFinder.xcodeproj -scheme RecipeFinder 2>/dev/null || true

echo ""
echo "✅ Firebase removed successfully!"
echo ""
echo "📋 Next steps:"
echo "   1. Open the project in Xcode"
echo "   2. File > Packages > Resolve Package Versions"
echo "   3. Clean Build Folder (Cmd+Shift+K)"
echo "   4. Build project (Cmd+B)"
echo ""
echo "💾 Backup saved to: ${PROJECT_FILE}.backup"
echo ""
