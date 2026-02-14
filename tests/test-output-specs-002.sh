#!/bin/bash

# test-output-specs-002.sh - ADD COMMAND OUTPUT TESTS
# Validates that command output matches the formats defined in CLI-INTERFACE-SPECS.md

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# ADD COMMAND OUTPUT TESTS
# ============================================================================
test_add_success_output() {
    log_test "test_add_success_output" \
             "Verify add success output format: 'Registered N file(s)'"

    # Setup
    $GUARD_BIN init 0640 $USER staff > /dev/null 2>&1
    touch file1.txt file2.txt file3.txt

    # Run
    set +e
    output=$($GUARD_BIN add file1.txt file2.txt file3.txt 2>&1)
    local exit_code=$?
    set -e

    # Assert exit code
    assert_exit_code $exit_code 0 "Should succeed"

    # Check for spec format: "Registered N file(s)"
    if echo "$output" | grep -qE "^Registered [0-9]+ file\(s\)$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output matches 'Registered N file(s)' format"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should match 'Registered N file(s)' format"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for correct count
    if echo "$output" | grep -q "Registered 3 file(s)"; then
        echo -e "${GREEN}✓ PASS${NC}: Correct count of 3 files"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Should show 'Registered 3 file(s)'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_add_success_output
print_test_summary 1
