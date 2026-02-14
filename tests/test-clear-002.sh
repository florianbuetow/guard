#!/bin/bash

# test-clear-002.sh - ERROR CONDITION TESTS
# The clear command:
# 1. Disables guard on the collection(s) and all files in them
# 2. Removes all files from the collection(s) (collections become empty)
# 3. Collections remain in the registry (now empty)
# 4. Files remain registered in guard (not unregistered)

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# ERROR CONDITION TESTS
# ============================================================================
test_clear_no_args() {
    log_test "test_clear_no_args" \
             "Negative test: guard clear without arguments should fail"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"

    # Run
    set +e
    output=$($GUARD_BIN clear 2>&1)
    local exit_code=$?
    set -e

    # Assert
    assert_exit_code $exit_code 1 "guard clear without args should fail"

    # Assert error message
    if [[ "$output" == *"rror"* ]] || [[ "$output" == *"No collections"* ]] || [[ "$output" == *"Usage"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Error message displayed"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Error message not displayed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_clear_no_args
print_test_summary 1
