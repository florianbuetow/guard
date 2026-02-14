#!/bin/bash

# test-file-management-005.sh - DISABLE FILE TESTS
# Tests file add, remove, toggle, enable, disable operations

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# DISABLE FILE TESTS
# ============================================================================
test_disable_file_positive() {
    log_test "test_disable_file_positive" \
             "Positive test: Disable guard on file"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch test.txt
    local initial_perms=$(get_file_permissions "test.txt")

    $GUARD_BIN add file test.txt
    $GUARD_BIN enable file test.txt

    # Run disable
    $GUARD_BIN disable file test.txt
    local exit_code=$?

    # Assert
    assert_exit_code $exit_code 0 "guard disable file should succeed"

    local guard_flag=$(get_guard_flag "$(pwd)/test.txt")
    assert_equals "false" "$guard_flag" "Guard flag should be false"

    local restored_perms=$(get_file_permissions "test.txt")
    assert_equals "$initial_perms" "$restored_perms" "Original permissions should be restored"
}

# Run test
run_test test_disable_file_positive
print_test_summary 1
