#!/bin/bash

# test-bug-collection-sync-001.sh - BUG #3: Collection/folder toggling syncs to collection state, not individual
#
# This file tests the following bug from docs/BUGS.md:
#
# Bug #3: Collection/folder toggling uses individual file states instead of syncing
#
# From BUGS.md:
# "When toggling a collection or folder, all guard states of all files are toggled
# individually, depending on their prior guard state. This is not what the
# specifications say."
#
# "The guard state must be derived from the collection guard flag and not from
# the flag of the files in the collection. This ensures that all files in a
# collection are in sync again after we toggle the guard of a collection."
#
# Tests are designed to FAIL when the bug exists, PASS when fixed.

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# BUG #3: Collection/folder toggling syncs to collection state, not individual
# ============================================================================
test_toggle_collection_syncs_all_files_to_same_state() {
    log_test "test_toggle_collection_syncs_all_files_to_same_state" \
             "BUG #3: After toggling collection, ALL files should have the SAME guard state"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt file2.txt file3.txt
    $GUARD_BIN create mycoll
    $GUARD_BIN update mycoll add file1.txt file2.txt file3.txt

    # First toggle: enable collection (all files should be guarded)
    $GUARD_BIN toggle collection mycoll

    local file1_guard=$(get_guard_flag "file1.txt")
    local file2_guard=$(get_guard_flag "file2.txt")
    local file3_guard=$(get_guard_flag "file3.txt")

    # All should be true
    if [ "$file1_guard" = "true" ] && [ "$file2_guard" = "true" ] && [ "$file3_guard" = "true" ]; then
        echo -e "${GREEN}✓ PASS${NC}: All files guarded after first toggle"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Not all files guarded after first toggle"
        echo -e "  file1: $file1_guard, file2: $file2_guard, file3: $file3_guard"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Second toggle: disable collection (all files should be unguarded)
    $GUARD_BIN toggle collection mycoll

    file1_guard=$(get_guard_flag "file1.txt")
    file2_guard=$(get_guard_flag "file2.txt")
    file3_guard=$(get_guard_flag "file3.txt")

    # All should be false
    if [ "$file1_guard" = "false" ] && [ "$file2_guard" = "false" ] && [ "$file3_guard" = "false" ]; then
        echo -e "${GREEN}✓ PASS${NC}: All files unguarded after second toggle"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Not all files unguarded after second toggle"
        echo -e "  file1: $file1_guard, file2: $file2_guard, file3: $file3_guard"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_toggle_collection_syncs_all_files_to_same_state
print_test_summary 1
