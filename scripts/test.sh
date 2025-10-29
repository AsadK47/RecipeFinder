#!/bin/bash

# RecipeFinder - Test Runner Script
# Can be run from anywhere: ./scripts/test.sh or just ./test.sh from scripts dir

echo "🧪 Running RecipeFinder Tests..."
echo ""

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Navigate to project root (one level up from scripts/)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Change to project root
cd "$PROJECT_ROOT" || exit 1

echo "📁 Project root: $PROJECT_ROOT"
echo ""

# Check if simulator is available
echo "🔍 Checking available simulators..."
AVAILABLE_SIMULATOR=$(xcrun simctl list devices available | grep "iPhone" | head -1 | sed 's/.*(\([^)]*\)).*/\1/')

if [ -z "$AVAILABLE_SIMULATOR" ]; then
    echo "⚠️  No iPhone simulator found, using default destination"
    DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro'
else
    echo "✅ Using available iPhone simulator"
    DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro'
fi

echo ""
echo "🏗️  Building tests..."

# Check if xcpretty is available
if command -v xcpretty &> /dev/null; then
    FORMATTER="xcpretty"
else
    FORMATTER="cat"
    echo "💡 Tip: Install xcpretty for better output: gem install xcpretty"
fi

# Build tests first (faster than build + test in one command)
xcodebuild build-for-testing \
    -scheme RecipeFinder \
    -destination "$DESTINATION" \
    -derivedDataPath DerivedData \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    | $FORMATTER

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo ""
    echo "❌ Build failed. Cannot run tests."
    exit 1
fi

echo ""
echo "🧪 Running tests..."

# Run tests without building (much faster)
xcodebuild test-without-building \
    -scheme RecipeFinder \
    -destination "$DESTINATION" \
    -derivedDataPath DerivedData \
    -resultBundlePath TestResults.xcresult \
    | $FORMATTER

TEST_EXIT_CODE=${PIPESTATUS[0]}

TEST_EXIT_CODE=${PIPESTATUS[0]}

# Check exit code
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ All tests passed!"
    echo ""
    echo "📊 View detailed results:"
    echo "   open TestResults.xcresult"
else
    echo ""
    echo "❌ Some tests failed."
    echo ""
    echo "📊 View detailed results:"
    echo "   open TestResults.xcresult"
    exit 1
fi
