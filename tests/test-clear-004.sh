#!/bin/bash

# test-clear-004.sh - GUARDFILE STATE VERIFICATION TESTS
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
# GUARDFILE STATE VERIFICATION TESTS
# ============================================================================
test_clear_guardfile_state() {
    log_test "test_clear_guardfile_state" \
             "Verify .guardfile state is correct after clear"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt file2.txt file3.txt
    chmod 644 file1.txt file2.txt file3.txt

    # OLD: $GUARD_BIN add file file1.txt file2.txt to mygroup
    # OLD: $GUARD_BIN add file file3.txt  # Not in any collection
    # NEW:
    $GUARD_BIN create mygroup
    $GUARD_BIN update mygroup add file1.txt file2.txt
    $GUARD_BIN add file file3.txt  # Not in any collection
    $GUARD_BIN enable collection mygroup

    # Count before
    local files_before=$(count_files_in_registry)
    local collections_before=$(count_collections_in_registry)
    assert_equals "3" "$files_before" "Should have 3 files in registry before clear"
    assert_equals "1" "$collections_before" "Should have 1 collection in registry before clear"

    # Run clear
    $GUARD_BIN clear mygroup

    # Count after
    local files_after=$(count_files_in_registry)
    local collections_after=$(count_collections_in_registry)
    assert_equals "3" "$files_after" "Should still have 3 files in registry after clear"
    assert_equals "1" "$collections_after" "Should still have 1 collection in registry after clear"

    # Verify file3 is unaffected (not in collection)
    local file3_flag=$(get_guard_flag "$(pwd)/file3.txt")
    assert_equals "false" "$file3_flag" "file3.txt guard flag should be unchanged (false)"
}

# Run test
run_test test_clear_guardfile_state
print_test_summary 1
