#!/bin/bash

# test-clear-005.sh - INTERACTION WITH OTHER COMMANDS TESTS
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
# INTERACTION WITH OTHER COMMANDS TESTS
# ============================================================================
test_clear_then_add_files() {
    log_test "test_clear_then_add_files" \
             "After clearing, should be able to add files back to collection"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt file2.txt
    chmod 644 file1.txt file2.txt

    # OLD: $GUARD_BIN add file file1.txt to mygroup
    # NEW:
    $GUARD_BIN create mygroup
    $GUARD_BIN update mygroup add file1.txt
    $GUARD_BIN enable collection mygroup

    # Clear the collection
    $GUARD_BIN clear mygroup

    # Add files back using new syntax
    # OLD: $GUARD_BIN add file file1.txt file2.txt to mygroup
    # NEW:
    $GUARD_BIN update mygroup add file1.txt file2.txt
    local exit_code=$?
    assert_exit_code $exit_code 0 "Adding files to cleared collection should succeed"

    # Verify files are in collection
    if file_in_collection "$(pwd)/file1.txt" "mygroup"; then
        echo -e "${GREEN}✓ PASS${NC}: file1.txt added back to collection"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: file1.txt not in collection"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    if file_in_collection "$(pwd)/file2.txt" "mygroup"; then
        echo -e "${GREEN}✓ PASS${NC}: file2.txt added to collection"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: file2.txt not in collection"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Verify guard flags are still false (files added but not enabled)
    local flag1=$(get_guard_flag "$(pwd)/file1.txt")
    local flag2=$(get_guard_flag "$(pwd)/file2.txt")
    assert_equals "false" "$flag1" "file1.txt guard flag should be false (not re-enabled)"
    assert_equals "false" "$flag2" "file2.txt guard flag should be false"
}

# Run test
run_test test_clear_then_add_files
print_test_summary 1
