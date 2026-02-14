#!/bin/bash

# test-disable-auto-detect-002.sh - DISABLE AUTO-DETECTION TESTS - COLLECTION ONLY
# Tests auto-detection of files vs collections: guard disable <arg>...
# Without explicit 'file' or 'collection' keyword

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# DISABLE AUTO-DETECTION TESTS - COLLECTION ONLY
# ============================================================================
test_disable_auto_detect_single_collection() {
    log_test "test_disable_auto_detect_single_collection" \
             "Auto-detect: disable single collection when only collection exists"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt
    $GUARD_BIN create mycoll
    $GUARD_BIN update mycoll add file1.txt
    $GUARD_BIN enable collection mycoll

    # Verify initial state
    local initial_coll_flag=$(get_collection_guard_flag "mycoll")
    assert_equals "true" "$initial_coll_flag" "Collection should start guarded"

    # Run disable without 'collection' keyword
    $GUARD_BIN disable mycoll
    local exit_code=$?

    # Assert
    assert_exit_code $exit_code 0 "guard disable should succeed"

    local disabled_coll_flag=$(get_collection_guard_flag "mycoll")
    assert_equals "false" "$disabled_coll_flag" "Collection should be unguarded after disable"

    local disabled_file_flag=$(get_guard_flag "$(pwd)/file1.txt")
    assert_equals "false" "$disabled_file_flag" "File in collection should be unguarded"
}

# Run test
run_test test_disable_auto_detect_single_collection
print_test_summary 1
