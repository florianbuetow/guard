#!/bin/bash

# test-clear-001.sh - BASIC CLEAR TESTS
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
# BASIC CLEAR TESTS
# ============================================================================
test_clear_single_collection_with_files() {
    log_test "test_clear_single_collection_with_files" \
             "Positive test: Clear collection with files - disables guard, removes files from collection, keeps collection and files in registry"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt file2.txt
    chmod 644 file1.txt file2.txt
    local initial_perms1=$(get_file_permissions "file1.txt")
    local initial_perms2=$(get_file_permissions "file2.txt")

    # OLD: $GUARD_BIN add file file1.txt file2.txt to mygroup
    # NEW:
    $GUARD_BIN create mygroup
    $GUARD_BIN update mygroup add file1.txt file2.txt
    $GUARD_BIN enable collection mygroup

    # Verify files are guarded
    local pre_flag1=$(get_guard_flag "$(pwd)/file1.txt")
    local pre_flag2=$(get_guard_flag "$(pwd)/file2.txt")
    local pre_coll_flag=$(get_collection_guard_flag "mygroup")
    assert_equals "true" "$pre_flag1" "File1 should be guarded before clear"
    assert_equals "true" "$pre_flag2" "File2 should be guarded before clear"
    assert_equals "true" "$pre_coll_flag" "Collection should be guarded before clear"

    # Run clear
    output=$($GUARD_BIN clear mygroup 2>&1)
    local exit_code=$?

    # Assert exit code
    assert_exit_code $exit_code 0 "guard clear should succeed"

    # Assert output message - per CLI-INTERFACE-SPECS.md format
    assert_contains "$output" "Cleared 1 collection(s):" "Output should confirm collection cleared"

    # Assert collection still exists in registry
    if collection_exists_in_registry "mygroup"; then
        echo -e "${GREEN}✓ PASS${NC}: Collection still exists in registry after clear"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Collection removed from registry (should remain)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Assert collection guard flag is now false
    local post_coll_flag=$(get_collection_guard_flag "mygroup")
    assert_equals "false" "$post_coll_flag" "Collection guard flag should be false after clear"

    # Assert files are no longer in collection
    if ! file_in_collection "$(pwd)/file1.txt" "mygroup"; then
        echo -e "${GREEN}✓ PASS${NC}: File1 removed from collection"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: File1 still in collection (should be removed)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    if ! file_in_collection "$(pwd)/file2.txt" "mygroup"; then
        echo -e "${GREEN}✓ PASS${NC}: File2 removed from collection"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: File2 still in collection (should be removed)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Assert files still exist in registry
    if file_in_registry "$(pwd)/file1.txt"; then
        echo -e "${GREEN}✓ PASS${NC}: File1 still in registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: File1 removed from registry (should remain)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    if file_in_registry "$(pwd)/file2.txt"; then
        echo -e "${GREEN}✓ PASS${NC}: File2 still in registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: File2 removed from registry (should remain)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Assert files' guard flags are false
    local post_flag1=$(get_guard_flag "$(pwd)/file1.txt")
    local post_flag2=$(get_guard_flag "$(pwd)/file2.txt")
    assert_equals "false" "$post_flag1" "File1 guard flag should be false after clear"
    assert_equals "false" "$post_flag2" "File2 guard flag should be false after clear"

    # Assert file permissions are restored
    local restored_perms1=$(get_file_permissions "file1.txt")
    local restored_perms2=$(get_file_permissions "file2.txt")
    assert_equals "$initial_perms1" "$restored_perms1" "File1 permissions should be restored"
    assert_equals "$initial_perms2" "$restored_perms2" "File2 permissions should be restored"
}

# Run test
run_test test_clear_single_collection_with_files
print_test_summary 1
