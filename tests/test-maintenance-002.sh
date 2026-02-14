#!/bin/bash

# test-maintenance-002.sh - RESET TESTS
# Tests guard cleanup, reset, uninstall commands

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e


# Find guard binary
find_guard_binary

# ============================================================================
# RESET TESTS
# ============================================================================
test_reset_disables_all_guards() {
    log_test "test_reset_disables_all_guards" \
             "Reset should disable guard for all files and collections"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt file2.txt
    local initial_perms1=$(get_file_permissions "file1.txt")
    local initial_perms2=$(get_file_permissions "file2.txt")

    # OLD: $GUARD_BIN add file file1.txt file2.txt to mycoll
    # NEW:
    $GUARD_BIN create mycoll
    $GUARD_BIN update mycoll add file1.txt file2.txt
    $GUARD_BIN enable collection mycoll

    # Verify files are guarded
    local flag1_before=$(get_guard_flag "$(pwd)/file1.txt")
    local coll_flag_before=$(get_collection_guard_flag "mycoll")

    # Run reset
    $GUARD_BIN reset
    local exit_code=$?

    # Assert
    assert_exit_code $exit_code 0 "Reset should succeed"

    # All file guard flags should be false
    local flag1=$(get_guard_flag "$(pwd)/file1.txt")
    local flag2=$(get_guard_flag "$(pwd)/file2.txt")
    assert_equals "false" "$flag1" "File1 guard flag should be false"
    assert_equals "false" "$flag2" "File2 guard flag should be false"

    # Collection guard flag should be false
    local coll_flag=$(get_collection_guard_flag "mycoll")
    assert_equals "false" "$coll_flag" "Collection guard flag should be false"

    # File permissions should be restored
    local restored_perms1=$(get_file_permissions "file1.txt")
    local restored_perms2=$(get_file_permissions "file2.txt")
    assert_equals "$initial_perms1" "$restored_perms1" "File1 permissions restored"
    assert_equals "$initial_perms2" "$restored_perms2" "File2 permissions restored"
}

# Run test
run_test test_reset_disables_all_guards
print_test_summary 1
