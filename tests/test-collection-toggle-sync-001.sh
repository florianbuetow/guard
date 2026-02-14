#!/bin/bash

# test-collection-toggle-sync-001.sh - COLLECTION TOGGLE SYNC TESTS
# Verifies that when toggling a collection, ALL files sync to the collection's
# new guard state, regardless of their individual prior states.
#
# Per TUI-INTERFACE-SPECS-MILESTONE-1.md lines 400-418:
# "When you press Spacebar on a collection showing [g], [-], or [~], it will
# toggle the guard flag to true, and the indicator will change to [G] (all
# files in the collection become guarded as a result)."

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# COLLECTION TOGGLE SYNC TESTS
# ============================================================================
test_toggle_collection_mixed_states_syncs_files() {
    log_test "test_toggle_collection_mixed_states_syncs_files" \
             "When toggling a collection with mixed file states, all files sync to collection's new guard state"

    # Setup: Initialize guard
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"

    # Create 3 test files
    touch file1.txt file2.txt file3.txt

    # Create collection and add all 3 files
    $GUARD_BIN create mycoll
    $GUARD_BIN update mycoll add file1.txt file2.txt file3.txt

    # Set mixed states:
    # - file1: guarded (via enable file)
    # - file2: not guarded (default)
    # - file3: guarded (via enable file)
    $GUARD_BIN enable file file1.txt
    # file2 remains unguarded (default after add)
    $GUARD_BIN enable file file3.txt

    # Verify mixed state setup
    local file1_before=$(get_guard_flag "file1.txt")
    local file2_before=$(get_guard_flag "file2.txt")
    local file3_before=$(get_guard_flag "file3.txt")
    assert_equals "true" "$file1_before" "Setup: file1 should be guarded"
    assert_equals "false" "$file2_before" "Setup: file2 should NOT be guarded"
    assert_equals "true" "$file3_before" "Setup: file3 should be guarded"

    # Verify collection guard is false initially
    local coll_before=$(get_collection_guard_flag "mycoll")
    assert_equals "false" "$coll_before" "Setup: collection guard should be false initially"

    # === ACTION 1: Toggle collection (false -> true) ===
    $GUARD_BIN toggle collection mycoll
    local exit_code1=$?
    assert_exit_code $exit_code1 0 "First toggle should succeed"

    # Assert: Collection guard is now true
    local coll_after1=$(get_collection_guard_flag "mycoll")
    assert_equals "true" "$coll_after1" "Collection guard should be true after first toggle"

    # Assert: ALL files should now have guard=true (synced to collection state)
    local file1_after1=$(get_guard_flag "file1.txt")
    local file2_after1=$(get_guard_flag "file2.txt")
    local file3_after1=$(get_guard_flag "file3.txt")
    assert_equals "true" "$file1_after1" "file1 should be guarded after collection toggle to true"
    assert_equals "true" "$file2_after1" "file2 should be guarded after collection toggle to true (was false, now synced)"
    assert_equals "true" "$file3_after1" "file3 should be guarded after collection toggle to true"

    # === ACTION 2: Toggle collection again (true -> false) ===
    $GUARD_BIN toggle collection mycoll
    local exit_code2=$?
    assert_exit_code $exit_code2 0 "Second toggle should succeed"

    # Assert: Collection guard is now false
    local coll_after2=$(get_collection_guard_flag "mycoll")
    assert_equals "false" "$coll_after2" "Collection guard should be false after second toggle"

    # Assert: ALL files should now have guard=false (synced to collection state)
    local file1_after2=$(get_guard_flag "file1.txt")
    local file2_after2=$(get_guard_flag "file2.txt")
    local file3_after2=$(get_guard_flag "file3.txt")
    assert_equals "false" "$file1_after2" "file1 should be unguarded after collection toggle to false"
    assert_equals "false" "$file2_after2" "file2 should be unguarded after collection toggle to false"
    assert_equals "false" "$file3_after2" "file3 should be unguarded after collection toggle to false"
}

# Run test
run_test test_toggle_collection_mixed_states_syncs_files
print_test_summary 1
