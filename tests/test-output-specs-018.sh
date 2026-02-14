#!/bin/bash

# test-output-specs-018.sh - UNINSTALL COMMAND OUTPUT TESTS
# Validates that command output matches the formats defined in CLI-INTERFACE-SPECS.md

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# UNINSTALL COMMAND OUTPUT TESTS
# ============================================================================
test_uninstall_success_output() {
    log_test "test_uninstall_success_output" \
             "Verify uninstall success output format"

    # Setup
    $GUARD_BIN init 0640 $USER staff > /dev/null 2>&1
    touch file1.txt
    $GUARD_BIN add file1.txt > /dev/null 2>&1
    $GUARD_BIN enable file file1.txt > /dev/null 2>&1

    # Run
    set +e
    output=$($GUARD_BIN uninstall 2>&1)
    local exit_code=$?
    set -e

    # Assert exit code
    assert_exit_code $exit_code 0 "Should succeed"

    # Check for "Reset complete:" section
    if echo "$output" | grep -q "^Reset complete:$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output contains 'Reset complete:'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should contain 'Reset complete:'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for "Cleanup complete:" section
    if echo "$output" | grep -q "^Cleanup complete:$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output contains 'Cleanup complete:'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should contain 'Cleanup complete:'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for "Removed .guardfile"
    if echo "$output" | grep -q "^Removed .guardfile$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output contains 'Removed .guardfile'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should contain 'Removed .guardfile'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for "Uninstall complete"
    if echo "$output" | grep -q "^Uninstall complete$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output contains 'Uninstall complete'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should contain 'Uninstall complete'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_uninstall_success_output
print_test_summary 1
