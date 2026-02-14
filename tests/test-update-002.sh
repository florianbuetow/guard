#!/bin/bash

# test-update-002.sh - UPDATE REMOVE TESTS
# Tests modifying collection membership with: guard update <collection> add|remove <files>...
# Replaces: guard add file ... to ... and guard remove file ... from ...

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# UPDATE REMOVE TESTS
# ============================================================================
test_update_remove_positive() {
    log_test "test_update_remove_positive" \
             "Positive test: Remove file from collection but keep in registry"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt
    $GUARD_BIN create mycoll
    $GUARD_BIN update mycoll add file1.txt

    # Run
    $GUARD_BIN update mycoll remove file1.txt
    local exit_code=$?

    # Assert
    assert_exit_code $exit_code 0 "Should succeed"

    # File should NOT be in collection
    if ! file_in_collection "$(pwd)/file1.txt" "mycoll"; then
        echo -e "${GREEN}✓ PASS${NC}: file1.txt removed from collection"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: file1.txt still in collection"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # File should still be in registry
    if file_in_registry "$(pwd)/file1.txt"; then
        echo -e "${GREEN}✓ PASS${NC}: file1.txt still in registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: file1.txt removed from registry (should stay)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_update_remove_positive
print_test_summary 1
