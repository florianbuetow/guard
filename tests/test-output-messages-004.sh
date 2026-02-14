#!/bin/bash

# test-output-messages-004.sh - UNINSTALL COMMAND OUTPUT TESTS (Issue 8)
# Tests enable/disable/uninstall operation messages

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e


# Find guard binary
find_guard_binary

# ============================================================================
# UNINSTALL COMMAND OUTPUT TESTS (Issue 8)
# ============================================================================
test_output_uninstall_command() {
    log_test "test_output_uninstall_command" \
             "Verify output shows 'All guards disabled', 'Cleanup completed', '.guardfile deleted'"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt file2.txt
    # OLD: $GUARD_BIN add file file1.txt file2.txt to mycoll > /dev/null 2>&1
    # NEW:
    $GUARD_BIN create mycoll
    $GUARD_BIN update mycoll add file1.txt file2.txt
    $GUARD_BIN enable collection mycoll > /dev/null 2>&1

    # Run
    set +e
    output=$($GUARD_BIN uninstall 2>&1)
    local exit_code=$?
    set -e

    # Assert exit code
    assert_exit_code $exit_code 0 "Should succeed"

    # Check for reset complete message
    if echo "$output" | grep -q "Reset complete:"; then
        echo -e "${GREEN}✓ PASS${NC}: Output contains 'Reset complete:'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output missing 'Reset complete:'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for cleanup complete message
    if echo "$output" | grep -q "Cleanup complete:"; then
        echo -e "${GREEN}✓ PASS${NC}: Output contains 'Cleanup complete:'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output missing 'Cleanup complete:'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for ".guardfile removed" message
    if echo "$output" | grep -q "Removed .guardfile"; then
        echo -e "${GREEN}✓ PASS${NC}: Output contains 'Removed .guardfile'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output missing 'Removed .guardfile'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Verify .guardfile was actually deleted
    if [ -f ".guardfile" ]; then
        echo -e "${RED}✗ FAIL${NC}: .guardfile still exists after uninstall"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        echo -e "${GREEN}✓ PASS${NC}: .guardfile successfully deleted"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
}

# Run test
run_test test_output_uninstall_command
print_test_summary 1
