#!/bin/bash
set -e

# run-cli-tests-sequential.sh - Run only CLI (non-TUI) tests sequentially with fail-fast behavior

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Guard CLI Test Runner${NC}"
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

# Filter out manual test files
TEST_FILES=$(echo "$TEST_FILES" | grep -v "test-assertions-and-framework.sh" | grep -v "test-guardfile-parsers.sh")

# Keep only non-TUI tests
CLI_TEST_FILES=$(echo "$TEST_FILES" | grep -iv '/[^/]*tui[^/]*$' || true)

if [ -z "$CLI_TEST_FILES" ]; then
    echo -e "${RED}No CLI test files found${NC}"
    exit 1
fi

test_count=$(echo "$CLI_TEST_FILES" | wc -l | tr -d ' ')
echo -e "Found ${BLUE}${test_count}${NC} CLI test files"
echo ""

# Record start time
start_time=$(date +%s)

passed=0
for test_file in $CLI_TEST_FILES; do
    test_name=$(basename "$test_file")

    echo -e "${BLUE}Running${NC} $test_name..."

    # set -e will cause immediate exit on failure
    bash "$test_file"

    echo -e "${GREEN}✓ $test_name passed${NC}"
    echo ""

    ((passed++))
done

# Record end time
end_time=$(date +%s)
elapsed=$((end_time - start_time))

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Total:  ${test_count}"
echo -e "Passed: ${GREEN}${passed}${NC}"
echo -e "Time:   ${elapsed}s"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}All CLI tests passed!${NC}"

exit 0
