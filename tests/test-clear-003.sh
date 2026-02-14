#!/bin/bash

# test-clear-003.sh - SHARED FILES TESTS
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
# SHARED FILES TESTS
# ============================================================================
test_clear_shared_files() {
    log_test "test_clear_shared_files" \
             "Clear collection with files shared across multiple collections"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt file2.txt
    chmod 644 file1.txt file2.txt

    # file1 is in both group1 and group2
    # OLD: $GUARD_BIN add file file1.txt to group1 group2
    # OLD: $GUARD_BIN add file file2.txt to group1
    # NEW:
    $GUARD_BIN create group1 group2
    $GUARD_BIN update group1 add file1.txt file2.txt
    $GUARD_BIN update group2 add file1.txt
    $GUARD_BIN enable collection group1

    # Run clear on group1
    output=$($GUARD_BIN clear group1 2>&1)
    local exit_code=$?

    # Assert exit code
    assert_exit_code $exit_code 0 "guard clear should succeed"

    # Assert file1 is removed from group1 but still in group2
    if ! file_in_collection "$(pwd)/file1.txt" "group1"; then
        echo -e "${GREEN}✓ PASS${NC}: file1 removed from group1"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: file1 still in group1"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    if file_in_collection "$(pwd)/file1.txt" "group2"; then
        echo -e "${GREEN}✓ PASS${NC}: file1 still in group2"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: file1 removed from group2 (should remain)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Assert file2 is removed from group1
    if ! file_in_collection "$(pwd)/file2.txt" "group1"; then
        echo -e "${GREEN}✓ PASS${NC}: file2 removed from group1"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: file2 still in group1"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Assert both files still in registry
    if file_in_registry "$(pwd)/file1.txt"; then
        echo -e "${GREEN}✓ PASS${NC}: file1 still in registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: file1 removed from registry"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    if file_in_registry "$(pwd)/file2.txt"; then
        echo -e "${GREEN}✓ PASS${NC}: file2 still in registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: file2 removed from registry"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Assert file guard flags are false after clear
    local post_flag1=$(get_guard_flag "$(pwd)/file1.txt")
    local post_flag2=$(get_guard_flag "$(pwd)/file2.txt")
    assert_equals "false" "$post_flag1" "file1 guard flag should be false after clear"
    assert_equals "false" "$post_flag2" "file2 guard flag should be false after clear"
}

# Run test
run_test test_clear_shared_files
print_test_summary 1
