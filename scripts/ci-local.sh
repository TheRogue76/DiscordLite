#!/bin/bash

# Local CI Check Script
# Runs the same checks as GitHub Actions CI pipeline locally

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🚀 Running local CI checks..."
echo ""

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
    echo -e "${RED}❌ SwiftLint not found${NC}"
    echo "Install with: brew install swiftlint"
    exit 1
fi

# Check if swift-format is installed
if ! command -v swift-format &> /dev/null; then
    echo -e "${RED}❌ swift-format not found${NC}"
    echo "Install with: brew install swift-format"
    exit 1
fi

# 1. SwiftLint
echo -e "${YELLOW}📝 Running SwiftLint (strict mode)...${NC}"
if swiftlint lint --strict --reporter emoji; then
    echo -e "${GREEN}✅ SwiftLint passed${NC}"
else
    echo -e "${RED}❌ SwiftLint failed${NC}"
    echo "Run 'swiftlint --fix' to auto-fix some issues"
    exit 1
fi
echo ""

# 2. swift-format
echo -e "${YELLOW}🎨 Checking code formatting...${NC}"
UNFORMATTED=$(swift-format lint --recursive DiscordLite DiscordLiteTests 2>&1 | grep -c "would" || true)
if [ "$UNFORMATTED" -gt 0 ]; then
    echo -e "${RED}❌ Found $UNFORMATTED file(s) with formatting issues${NC}"
    echo "Run 'swift-format format --in-place --recursive DiscordLite DiscordLiteTests' to fix"
    swift-format lint --recursive DiscordLite DiscordLiteTests
    exit 1
else
    echo -e "${GREEN}✅ All files properly formatted${NC}"
fi
echo ""

# 3. Unit Tests
echo -e "${YELLOW}🧪 Running unit tests...${NC}"
if xcodebuild test \
    -project DiscordLite.xcodeproj \
    -scheme DiscordLite \
    -destination 'platform=macOS' \
    -quiet; then
    echo -e "${GREEN}✅ All tests passed${NC}"
else
    echo -e "${RED}❌ Tests failed${NC}"
    exit 1
fi
echo ""

# 4. Build (Release)
echo -e "${YELLOW}🔨 Building release configuration...${NC}"
if xcodebuild build \
    -project DiscordLite.xcodeproj \
    -scheme DiscordLite \
    -configuration Release \
    -destination 'platform=macOS' \
    -quiet; then
    echo -e "${GREEN}✅ Release build succeeded${NC}"
else
    echo -e "${RED}❌ Release build failed${NC}"
    exit 1
fi
echo ""

echo -e "${GREEN}✅ All CI checks passed!${NC}"
echo "Your code is ready to push 🚀"
