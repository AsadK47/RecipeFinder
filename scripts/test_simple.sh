#!/bin/bash

# Simple test runner that works with limited terminal environment

echo "🧪 Running RecipeFinder Unit Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Configuration
SCHEME="RecipeFinder"
DESTINATION="platform=iOS Simulator,name=iPhone 15,OS=latest"
DERIVED_DATA="DerivedData"

# Clean up old results
echo "🧹 Cleaning previous test results..."
/bin/rm -rf TestResults.xcresult 2>/dev/null || true
/bin/rm -f ref.0* data.0* 2>/dev/null || true

# Build test bundle
echo "🔨 Building test bundle..."
/usr/bin/xcodebuild build-for-testing \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA" \
    -quiet

BUILD_EXIT_CODE=$?
if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo ""
    echo "❌ Build failed with exit code $BUILD_EXIT_CODE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit $BUILD_EXIT_CODE
fi

# Run tests
echo "🧪 Executing unit tests..."
/usr/bin/xcodebuild test-without-building \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -only-testing:RecipeFinderTests \
    -derivedDataPath "$DERIVED_DATA" \
    -enableCodeCoverage YES \
    -resultBundlePath TestResults.xcresult

TEST_EXIT_CODE=$?

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "✅ All unit tests passed successfully!"
    echo ""
    echo "📊 Test Results:"
    echo "   • Coverage report: TestResults.xcresult"
    echo "   • View in Xcode: xed TestResults.xcresult"
    echo ""
    exit 0
else
    echo "❌ Tests failed with exit code $TEST_EXIT_CODE"
    echo ""
    echo "💡 Tips:"
    echo "   • Check TestResults.xcresult for detailed failure information"
    echo "   • Run individual test files to isolate failures"
    echo "   • Ensure all dependencies are up to date"
    echo ""
    exit $TEST_EXIT_CODE
fi
