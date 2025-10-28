#!/bin/bash

# RecipeFinder Linting Script
# Runs SwiftLint on the entire project

set -e  # Exit on error

echo "🔍 RecipeFinder SwiftLint"
echo "========================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
FIX=false
STRICT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --fix)
            FIX=true
            shift
            ;;
        --strict)
            STRICT=true
            shift
            ;;
        -h|--help)
            echo "Usage: ./run-lint.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --fix        Automatically fix violations where possible"
            echo "  --strict     Treat warnings as errors"
            echo "  -h, --help   Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./run-lint.sh              # Run lint checks"
            echo "  ./run-lint.sh --fix        # Fix violations automatically"
            echo "  ./run-lint.sh --strict     # Fail on warnings"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
    echo -e "${RED}❌ SwiftLint is not installed${NC}"
    echo ""
    echo "To install SwiftLint, run:"
    echo -e "${BLUE}  brew install swiftlint${NC}"
    echo ""
    echo "Or install via Mint:"
    echo -e "${BLUE}  mint install realm/SwiftLint${NC}"
    echo ""
    exit 1
fi

# Display SwiftLint version
SWIFTLINT_VERSION=$(swiftlint version)
echo -e "${BLUE}SwiftLint version: $SWIFTLINT_VERSION${NC}"
echo ""

# Run SwiftLint
if [ "$FIX" = true ]; then
    echo -e "${YELLOW}🔧 Auto-fixing violations...${NC}"
    swiftlint --fix --format
    echo ""
fi

echo -e "${YELLOW}🔍 Analyzing code...${NC}"
echo ""

# Run lint with appropriate flags
if [ "$STRICT" = true ]; then
    swiftlint lint --strict
else
    swiftlint lint
fi

EXIT_CODE=$?

echo ""
echo "========================"

if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✅ Linting passed! Code looks great.${NC}"
else
    echo -e "${RED}❌ Linting found issues. Please fix the violations above.${NC}"
    echo ""
    echo "Tip: Run ${BLUE}./run-lint.sh --fix${NC} to auto-fix some issues"
fi

exit $EXIT_CODE
