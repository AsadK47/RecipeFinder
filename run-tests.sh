#!/bin/bash

# RecipeFinder Test Runner
# Runs all unit and UI tests for the project

set -e  # Exit on error

echo "🧪 RecipeFinder Test Suite"
echo "=========================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCHEME="RecipeFinder"
PROJECT="RecipeFinder.xcodeproj"
DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro"
DERIVED_DATA="DerivedData"

# Parse arguments
VERBOSE=false
UNIT_ONLY=false
UI_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -u|--unit)
            UNIT_ONLY=true
            shift
            ;;
        --ui)
            UI_ONLY=true
            shift
            ;;
        -h|--help)
            echo "Usage: ./run-tests.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -v, --verbose    Show detailed test output"
            echo "  -u, --unit       Run only unit tests"
            echo "  --ui             Run only UI tests"
            echo "  -h, --help       Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./run-tests.sh              # Run all tests"
            echo "  ./run-tests.sh -u           # Run unit tests only"
            echo "  ./run-tests.sh -v           # Verbose output"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Function to run tests
run_tests() {
    local test_target=$1
    local test_name=$2
    
    echo -e "${YELLOW}Running $test_name...${NC}"
    
    if [ "$VERBOSE" = true ]; then
        xcodebuild test-without-building \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -destination "$DESTINATION" \
            -derivedDataPath "$DERIVED_DATA" \
            -only-testing:"$test_target" \
            -resultBundlePath "TestResults-${test_target}.xcresult" \
            | $FORMATTER
    else
        xcodebuild test-without-building \
            -project "$PROJECT" \
            -scheme "$SCHEME" \
            -destination "$DESTINATION" \
            -derivedDataPath "$DERIVED_DATA" \
            -only-testing:"$test_target" \
            -resultBundlePath "TestResults-${test_target}.xcresult" \
            2>&1 | grep -E '(Test Suite|Test Case|✓|✗|passed|failed)' || true
    fi
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo -e "${GREEN}✓ $test_name passed${NC}"
        return 0
    else
        echo -e "${RED}✗ $test_name failed${NC}"
        echo "   View results: open TestResults-${test_target}.xcresult"
        return 1
    fi
}

# Check if simulator is available
echo "📱 Checking simulator availability..."
xcrun simctl list devices available | grep "iPhone" > /dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: No iOS simulators available${NC}"
    exit 1
fi

# Check if xcpretty is available
if command -v xcpretty &> /dev/null; then
    FORMATTER="xcpretty --color"
else
    FORMATTER="cat"
    echo "💡 Tip: Install xcpretty for better output: gem install xcpretty"
fi

# Build tests once (much faster)
echo "🏗️  Building tests..."
xcodebuild build-for-testing \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    | $FORMATTER

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

echo ""

# Run tests based on flags
FAILED=false

if [ "$UI_ONLY" = false ]; then
    if ! run_tests "RecipeFinderTests" "Unit Tests"; then
        FAILED=true
    fi
    echo ""
fi

if [ "$UNIT_ONLY" = false ]; then
    if ! run_tests "RecipeFinderUITests" "UI Tests"; then
        FAILED=true
    fi
    echo ""
fi

# Summary
echo "=========================="
if [ "$FAILED" = true ]; then
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
else
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
fi
