#!/bin/bash

# test-output-specs-005.sh - DISABLE COMMAND OUTPUT TESTS
# Validates that command output matches the formats defined in CLI-INTERFACE-SPECS.md

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# DISABLE COMMAND OUTPUT TESTS
# ============================================================================
test_disable_success_output() {
    log_test "test_disable_success_output" \
             "Verify disable success output format"

    # Setup
    $GUARD_BIN init 0640 $USER staff > /dev/null 2>&1
    touch file1.txt file2.txt
    $GUARD_BIN add file1.txt file2.txt > /dev/null 2>&1
    $GUARD_BIN enable file file1.txt file2.txt > /dev/null 2>&1

    # Run
    set +e
    output=$($GUARD_BIN disable file file1.txt file2.txt 2>&1)
    local exit_code=$?
    set -e

    # Assert exit code
    assert_exit_code $exit_code 0 "Should succeed"

    # Check for spec format: "Guard disabled for N file(s)"
    if echo "$output" | grep -qE "^Guard disabled for [0-9]+ file\(s\)$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output matches 'Guard disabled for N file(s)' format"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should match 'Guard disabled for N file(s)' format"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_disable_success_output
print_test_summary 1
