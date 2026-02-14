#!/bin/bash

# test-collection-management-002.sh - ENABLE/DISABLE COLLECTION TESTS
# Tests collection toggle, enable, disable operations
# NOTE: Create/destroy collection tests moved to test-create.sh and test-destroy.sh

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# ENABLE/DISABLE COLLECTION TESTS
# ============================================================================
test_enable_collection_positive() {
    log_test "test_enable_collection_positive" \
             "Positive test: Enable collection and all member files"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt file2.txt
    # OLD: $GUARD_BIN add file file1.txt file2.txt to mygroup
    # NEW:
    $GUARD_BIN create mygroup
    $GUARD_BIN update mygroup add file1.txt file2.txt

    # Run enable
    $GUARD_BIN enable collection mygroup
    local exit_code=$?

    # Assert
    assert_exit_code $exit_code 0 "guard enable collection should succeed"

    local coll_flag=$(get_collection_guard_flag "mygroup")
    assert_equals "true" "$coll_flag" "Collection guard flag should be true"

    local file1_flag=$(get_guard_flag "$(pwd)/file1.txt")
    local file2_flag=$(get_guard_flag "$(pwd)/file2.txt")
    assert_equals "true" "$file1_flag" "File1 guard flag should be true"
    assert_equals "true" "$file2_flag" "File2 guard flag should be true"

    # Check file permissions
    local file1_perms=$(get_file_permissions "file1.txt")
    local file2_perms=$(get_file_permissions "file2.txt")
    assert_equals "000" "$file1_perms" "File1 permissions should be 000"
    assert_equals "000" "$file2_perms" "File2 permissions should be 000"
}

# Run test
run_test test_enable_collection_positive
print_test_summary 1
