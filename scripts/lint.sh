#!/bin/bash

# RecipeFinder - SwiftLint Script
# Can be run from anywhere: ./scripts/lint.sh or just ./lint.sh from scripts dir

echo "🔍 Running SwiftLint on entire project..."
echo ""

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Navigate to project root (one level up from scripts/)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Change to project root
cd "$PROJECT_ROOT" || exit 1

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
    echo "❌ SwiftLint is not installed!"
    echo ""
    echo "Install with Homebrew:"
    echo "  brew install swiftlint"
    echo ""
    echo "Or download from: https://github.com/realm/SwiftLint"
    exit 1
fi

echo "📁 Project root: $PROJECT_ROOT"
echo ""

# Run SwiftLint
swiftlint lint RecipeFinder/ --config .swiftlint.yml

# Check exit code
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SwiftLint passed! No issues found."
else
    echo ""
    echo "⚠️  SwiftLint found issues. Please fix them above."
    exit 1
fi
