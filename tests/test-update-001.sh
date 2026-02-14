#!/bin/bash

# test-update-001.sh - UPDATE ADD TESTS
# Tests modifying collection membership with: guard update <collection> add|remove <files>...
# Replaces: guard add file ... to ... and guard remove file ... from ...

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# UPDATE ADD TESTS
# ============================================================================
test_update_add_positive() {
    log_test "test_update_add_positive" \
             "Positive test: Add multiple files to collection with guard update"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt file2.txt
    $GUARD_BIN create mycollection

    # Run
    $GUARD_BIN update mycollection add file1.txt file2.txt
    local exit_code=$?

    # Assert
    assert_exit_code $exit_code 0 "guard update add should succeed"

    # Check files are in collection
    if file_in_collection "$(pwd)/file1.txt" "mycollection"; then
        echo -e "${GREEN}✓ PASS${NC}: file1.txt is in collection"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: file1.txt not in collection"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    if file_in_collection "$(pwd)/file2.txt" "mycollection"; then
        echo -e "${GREEN}✓ PASS${NC}: file2.txt is in collection"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: file2.txt not in collection"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check files are in registry
    if file_in_registry "$(pwd)/file1.txt" && file_in_registry "$(pwd)/file2.txt"; then
        echo -e "${GREEN}✓ PASS${NC}: Both files in registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Files not in registry"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_update_add_positive
print_test_summary 1
