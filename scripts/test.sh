#!/bin/bash

# RecipeFinder - Fast Unit Test Runner
# Runs all unit tests regardless of folder structure
# Optimized for speed

set -e

# Cleanup function
cleanup() {
    cd "$PROJECT_ROOT" 2>/dev/null || true
    rm -f ref.0* data.0* 2>/dev/null || true
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

echo "🧪 Running RecipeFinder Unit Tests "

# Get project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Clean up old results and temp files
rm -rf TestResults.xcresult 2>/dev/null || true
rm -f ref.0* data.0* 2>/dev/null || true

# Find all test files recursively
TEST_FILES=$(find RecipeFinderTests -name "*Tests.swift" -type f 2>/dev/null | wc -l | tr -d ' ')
echo "📋 Found $TEST_FILES test files"

# Run tests with optimizations:
# - Build test bundle first to ensure it's available
# - Use -parallel-testing-enabled YES for faster execution
# - Use -quiet to reduce output overhead
# - Use existing DerivedData to avoid rebuilding
# - Run all tests in RecipeFinderTests target (regardless of folder structure)
echo "🔨 Building test bundle..."
xcodebuild build-for-testing \
    -scheme RecipeFinder \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -derivedDataPath DerivedData \
    -quiet

BUILD_EXIT_CODE=$?
if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo ""
    echo "❌ Build failed with exit code $BUILD_EXIT_CODE"
    exit $BUILD_EXIT_CODE
fi

echo "🧪 Running unit tests..."
xcodebuild test-without-building \
    -scheme RecipeFinder \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -only-testing:RecipeFinderTests \
    -derivedDataPath DerivedData

TEST_EXIT_CODE=$?
if [ $TEST_EXIT_CODE -ne 0 ]; then
    echo ""
    echo "❌ Tests failed with exit code $TEST_EXIT_CODE"
    exit $TEST_EXIT_CODE
fi

echo ""
echo "✅ All unit tests completed successfully!"
