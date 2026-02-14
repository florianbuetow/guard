#!/bin/bash

# test-destroy-001.sh - DESTROY COLLECTION TESTS
# Tests destroying collections with: guard destroy <collection>...
# Replaces: guard remove collection <collection>...

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# DESTROY COLLECTION TESTS
# ============================================================================
test_destroy_positive() {
    log_test "test_destroy_positive" \
             "Positive test: Destroy collection disables files and removes collection"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt file2.txt

    $GUARD_BIN create mygroup
    $GUARD_BIN update mygroup add file1.txt file2.txt
    $GUARD_BIN enable collection mygroup

    # Verify files are guarded
    local flag1=$(get_guard_flag "$(pwd)/file1.txt")
    local flag2=$(get_guard_flag "$(pwd)/file2.txt")

    # Run destroy
    $GUARD_BIN destroy mygroup
    local exit_code=$?

    # Assert
    assert_exit_code $exit_code 0 "guard destroy should succeed"

    # Collection should not exist
    if ! collection_exists_in_registry "mygroup"; then
        echo -e "${GREEN}✓ PASS${NC}: Collection removed from registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Collection still in registry"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Files' guard flags should be false (disabled)
    local flag1_after=$(get_guard_flag "$(pwd)/file1.txt")
    local flag2_after=$(get_guard_flag "$(pwd)/file2.txt")
    assert_equals "false" "$flag1_after" "File1 guard flag should be false after collection destroy"
    assert_equals "false" "$flag2_after" "File2 guard flag should be false after collection destroy"

    # Files should still be in registry (only collection removed)
    if file_in_registry "$(pwd)/file1.txt"; then
        echo -e "${GREEN}✓ PASS${NC}: Files still in registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Files removed from registry (should stay)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_destroy_positive
print_test_summary 1
