#!/bin/bash

# test-toggle-auto-detect-002.sh - TOGGLE AUTO-DETECTION TESTS - COLLECTION ONLY
# Tests auto-detection of files vs collections: guard toggle <arg>...
# Without explicit 'file' or 'collection' keyword

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# TOGGLE AUTO-DETECTION TESTS - COLLECTION ONLY
# ============================================================================
test_toggle_auto_detect_single_collection() {
    log_test "test_toggle_auto_detect_single_collection" \
             "Auto-detect: toggle single collection when only collection exists"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt
    $GUARD_BIN create mycoll
    $GUARD_BIN update mycoll add file1.txt

    # Verify initial state
    local initial_coll_flag=$(get_collection_guard_flag "mycoll")
    assert_equals "false" "$initial_coll_flag" "Collection should start unguarded"

    # Run toggle without 'collection' keyword
    $GUARD_BIN toggle mycoll
    local exit_code=$?

    # Assert
    assert_exit_code $exit_code 0 "guard toggle should succeed"

    local toggled_coll_flag=$(get_collection_guard_flag "mycoll")
    assert_equals "true" "$toggled_coll_flag" "Collection should be guarded after toggle"

    local toggled_file_flag=$(get_guard_flag "$(pwd)/file1.txt")
    assert_equals "true" "$toggled_file_flag" "File in collection should be guarded"
}

# Run test
run_test test_toggle_auto_detect_single_collection
print_test_summary 1
