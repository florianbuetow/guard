#!/bin/bash

# test-output-specs-006.sh - CREATE COMMAND OUTPUT TESTS
# Validates that command output matches the formats defined in CLI-INTERFACE-SPECS.md

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# CREATE COMMAND OUTPUT TESTS
# ============================================================================
test_create_success_output() {
    log_test "test_create_success_output" \
             "Verify create success output format"

    # Setup
    $GUARD_BIN init 0640 $USER staff > /dev/null 2>&1

    # Run
    set +e
    output=$($GUARD_BIN create docs configs 2>&1)
    local exit_code=$?
    set -e

    # Assert exit code
    assert_exit_code $exit_code 0 "Should succeed"

    # Check for spec format: "Created N collection(s):"
    if echo "$output" | grep -qE "^Created [0-9]+ collection\(s\):$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output matches 'Created N collection(s):' format"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should match 'Created N collection(s):' format"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for indented list of collections
    if echo "$output" | grep -q "^  - docs$"; then
        echo -e "${GREEN}✓ PASS${NC}: Shows '  - docs' in list"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Should show '  - docs' in indented list"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_create_success_output
print_test_summary 1
