#!/bin/bash

# test-collection-management-001.sh - TOGGLE COLLECTION TESTS
# Tests collection toggle, enable, disable operations
# NOTE: Create/destroy collection tests moved to test-create.sh and test-destroy.sh

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# TOGGLE COLLECTION TESTS
# ============================================================================
test_toggle_collection_positive() {
    log_test "test_toggle_collection_positive" \
             "Positive test: Toggle collection and member files"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt
    # OLD: $GUARD_BIN add file file1.txt to mygroup
    # NEW:
    $GUARD_BIN create mygroup
    $GUARD_BIN update mygroup add file1.txt

    # First toggle (enable)
    $GUARD_BIN toggle collection mygroup
    local exit_code1=$?
    assert_exit_code $exit_code1 0 "First toggle should succeed"

    local coll_flag1=$(get_collection_guard_flag "mygroup")
    assert_equals "true" "$coll_flag1" "Collection guard flag should be true"

    local file_flag1=$(get_guard_flag "$(pwd)/file1.txt")
    assert_equals "true" "$file_flag1" "Member file guard flag should be true"

    # Second toggle (disable)
    $GUARD_BIN toggle collection mygroup
    local exit_code2=$?
    assert_exit_code $exit_code2 0 "Second toggle should succeed"

    local coll_flag2=$(get_collection_guard_flag "mygroup")
    assert_equals "false" "$coll_flag2" "Collection guard flag should be false"

    local file_flag2=$(get_guard_flag "$(pwd)/file1.txt")
    assert_equals "false" "$file_flag2" "Member file guard flag should be false"
}

# Run test
run_test test_toggle_collection_positive
print_test_summary 1
