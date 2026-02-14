#!/bin/bash

# test-output-specs-016.sh - CLEANUP COMMAND OUTPUT TESTS
# Validates that command output matches the formats defined in CLI-INTERFACE-SPECS.md

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# CLEANUP COMMAND OUTPUT TESTS
# ============================================================================
test_cleanup_success_output() {
    log_test "test_cleanup_success_output" \
             "Verify cleanup success output format"

    # Setup
    $GUARD_BIN init 0640 $USER staff > /dev/null 2>&1
    touch file1.txt
    $GUARD_BIN add file1.txt > /dev/null 2>&1
    rm -f file1.txt  # Delete file to create stale entry
    $GUARD_BIN create empty_col > /dev/null 2>&1  # Create empty collection

    # Run
    set +e
    output=$($GUARD_BIN cleanup 2>&1)
    local exit_code=$?
    set -e

    # Assert exit code
    assert_exit_code $exit_code 0 "Should succeed"

    # Check for "Cleanup complete:" header
    if echo "$output" | grep -q "^Cleanup complete:$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output starts with 'Cleanup complete:'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should start with 'Cleanup complete:'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for removed files line
    if echo "$output" | grep -qE "^  Removed [0-9]+ file\(s\) \(file not found\)$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output shows 'Removed N file(s) (file not found)'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should show 'Removed N file(s) (file not found)'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for removed collections line
    if echo "$output" | grep -qE "^  Removed [0-9]+ collection\(s\) \(empty\)$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output shows 'Removed N collection(s) (empty)'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should show 'Removed N collection(s) (empty)'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_cleanup_success_output
print_test_summary 1
