#!/bin/bash

# test-output-specs-017.sh - RESET COMMAND OUTPUT TESTS
# Validates that command output matches the formats defined in CLI-INTERFACE-SPECS.md

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# RESET COMMAND OUTPUT TESTS
# ============================================================================
test_reset_success_output() {
    log_test "test_reset_success_output" \
             "Verify reset success output format"

    # Setup
    $GUARD_BIN init 0640 $USER staff > /dev/null 2>&1
    touch file1.txt file2.txt
    $GUARD_BIN add file1.txt file2.txt > /dev/null 2>&1
    $GUARD_BIN create docs > /dev/null 2>&1
    $GUARD_BIN update docs add file1.txt > /dev/null 2>&1
    $GUARD_BIN enable file file1.txt file2.txt > /dev/null 2>&1
    $GUARD_BIN enable collection docs > /dev/null 2>&1

    # Run
    set +e
    output=$($GUARD_BIN reset 2>&1)
    local exit_code=$?
    set -e

    # Assert exit code
    assert_exit_code $exit_code 0 "Should succeed"

    # Check for "Reset complete:" header
    if echo "$output" | grep -q "^Reset complete:$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output starts with 'Reset complete:'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should start with 'Reset complete:'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for disabled files line
    if echo "$output" | grep -qE "^  Guard disabled for [0-9]+ file\(s\)$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output shows 'Guard disabled for N file(s)'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should show 'Guard disabled for N file(s)'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for disabled collections line
    if echo "$output" | grep -qE "^  Guard disabled for [0-9]+ collection\(s\)$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output shows 'Guard disabled for N collection(s)'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should show 'Guard disabled for N collection(s)'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_reset_success_output
print_test_summary 1
