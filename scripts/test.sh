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

# Run tests using xcodebuild
xcodebuild test \
    -scheme RecipeFinder \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
    -quiet

# Check exit code
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ All tests passed!"
else
    echo ""
    echo "❌ Some tests failed. See details above."
    exit 1
fi
