#!/bin/bash

# RecipeFinder - SwiftLint Script
# Run from project root: ./scripts/lint.sh

set -e  # Exit on error

# Navigate to project root
cd "$(dirname "$0")/.." || exit 1

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
    echo "❌ SwiftLint not installed. Run: brew install swiftlint"
    exit 1
fi

echo "� Running SwiftLint on RecipeFinder..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

swiftlint lint RecipeFinder/ --config .swiftlint.yml

if [ $? -eq 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ SwiftLint passed with no violations!"
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  SwiftLint found violations. Please fix them."
    exit 1
fi

