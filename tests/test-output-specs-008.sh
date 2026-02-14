#!/bin/bash

# test-output-specs-008.sh - CLEAR COMMAND OUTPUT TESTS
# Validates that command output matches the formats defined in CLI-INTERFACE-SPECS.md

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# CLEAR COMMAND OUTPUT TESTS
# ============================================================================
test_clear_success_output() {
    log_test "test_clear_success_output" \
             "Verify clear success output format"

    # Setup
    $GUARD_BIN init 0640 $USER staff > /dev/null 2>&1
    touch file1.txt file2.txt
    $GUARD_BIN create docs > /dev/null 2>&1
    $GUARD_BIN update docs add file1.txt file2.txt > /dev/null 2>&1

    # Run
    set +e
    output=$($GUARD_BIN clear docs 2>&1)
    local exit_code=$?
    set -e

    # Assert exit code
    assert_exit_code $exit_code 0 "Should succeed"

    # Check for spec format: "Cleared N collection(s):"
    if echo "$output" | grep -qE "^Cleared [0-9]+ collection\(s\):$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output matches 'Cleared N collection(s):' format"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should match 'Cleared N collection(s):' format"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for collection with removed count
    if echo "$output" | grep -qE "^  - docs: removed [0-9]+ file\(s\)$"; then
        echo -e "${GREEN}✓ PASS${NC}: Shows collection with removed file count"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Should show '  - docs: removed N file(s)'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_clear_success_output
print_test_summary 1
