#!/bin/bash
set -e

# run-all-tests.sh - Test runner that automatically discovers and executes all guard test files
# Provides comprehensive test coverage with fail-fast behavior

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Guard CLI Comprehensive Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if guard binary exists
if [ ! -f "./guard" ] && ! command -v guard &> /dev/null; then
    echo -e "${RED}Error: guard binary not found${NC}"
    echo "Please build the guard binary first:"
    echo "  just build"
    echo "  or"
    echo "  go build -o guard ./cmd/guard"
    exit 1
fi

# Auto-discover all test-*.sh files and run them
# Sort to ensure consistent execution order
TEST_FILES=$(find "$SCRIPT_DIR" -maxdepth 1 -name "test-*.sh" -type f | sort)

# Filter out test-assertions-and-framework.sh and test-guardfile-parsers.sh
# as they are manual test files with different structure
TEST_FILES=$(echo "$TEST_FILES" | grep -v "test-assertions-and-framework.sh" | grep -v "test-guardfile-parsers.sh")

# Separate TUI-related tests from other tests (run all TUI-related tests last)
# Match "tui" only in the filename (after last /) to avoid false matches from directory names
TUI_TEST_FILES=$(echo "$TEST_FILES" | grep -i '/[^/]*tui[^/]*$' || true)
CLI_TEST_FILES=$(echo "$TEST_FILES" | grep -iv '/[^/]*tui[^/]*$' || true)

test_file_count=0

# Run CLI tests first
echo -e "${BLUE}--- CLI Tests ---${NC}"
echo ""

for test_file in $CLI_TEST_FILES; do
    test_name=$(basename "$test_file")

    echo -e "${BLUE}Running${NC} $test_name..."

    # Run test file - set -e will cause immediate exit on failure
    bash "$test_file"

    echo -e "${GREEN}✓ $test_name passed${NC}"
    echo ""

    ((test_file_count++))
done

# Run TUI tests if any exist
if [ -n "$TUI_TEST_FILES" ]; then
    echo ""
    echo -e "${BLUE}--- TUI Tests (require tmux) ---${NC}"
    echo ""

    # Check for tmux before running TUI tests
    if ! command -v tmux &> /dev/null; then
        echo -e "${RED}Error: tmux is required for TUI tests but is not installed${NC}"
        echo "Please install tmux to run TUI integration tests"
        exit 1
    fi

    for test_file in $TUI_TEST_FILES; do
        test_name=$(basename "$test_file")

        echo -e "${BLUE}Running${NC} $test_name..."

        # Run test file - set -e will cause immediate exit on failure
        bash "$test_file"

        echo -e "${GREEN}✓ $test_name passed${NC}"
        echo ""

        ((test_file_count++))
    done
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Test files run: $test_file_count"
echo -e "${GREEN}All tests passed!${NC}"
echo -e "${BLUE}========================================${NC}"

exit 0
