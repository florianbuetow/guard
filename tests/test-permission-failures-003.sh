#!/bin/bash

# test-permission-failures-003.sh - GUARD UNINSTALL - PERMISSION FAILURE TESTS
# Tests error handling when permission operations fail
#
# Approach: Remove execute permission from parent directory to make files
# inaccessible. This causes chmod to fail with "permission denied" because
# the kernel can't traverse to the file.

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# GUARD UNINSTALL - PERMISSION FAILURE TESTS
# ============================================================================
test_uninstall_aborts_on_permission_failure() {
    log_test "test_uninstall_aborts_on_permission_failure" \
             "Uninstall should abort and preserve .guardfile on permission failure"

    local current_user=$(get_current_user)
    local current_group=$(get_current_group)

    # Setup
    mkdir -p restricted_dir
    touch restricted_dir/protected.txt

    $GUARD_BIN init 000 "$current_user" "$current_group"
    $GUARD_BIN add restricted_dir/protected.txt
    $GUARD_BIN enable file restricted_dir/protected.txt

    # Remove execute permission from directory
    chmod 600 restricted_dir

    # Run uninstall
    set +e
    output=$($GUARD_BIN uninstall 2>&1)
    local exit_code=$?
    set -e

    # Restore permissions
    chmod 755 restricted_dir

    # Assert: Should fail
    assert_exit_code $exit_code 1 "Uninstall should fail when permission restore fails"

    # Assert: .guardfile should be preserved
    if [ -f ".guardfile" ]; then
        echo -e "${GREEN}✓ PASS${NC}: .guardfile preserved on error"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: .guardfile should be preserved on error"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Assert: Error message mentions abort
    if echo "$output" | grep -qi "abort"; then
        echo -e "${GREEN}✓ PASS${NC}: Output mentions abort"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should mention abort"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_uninstall_aborts_on_permission_failure
print_test_summary 1
