#!/bin/bash

# test-remove-optional-keyword-001.sh - REMOVE FILE TESTS (optional 'file' keyword)
# Tests unregistering files with: guard remove <file>... (without explicit 'file' keyword)
# Replaces: guard remove file <file>...

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# REMOVE FILE TESTS (optional 'file' keyword)
# ============================================================================
test_remove_positive() {
    log_test "test_remove_positive" \
             "Positive test: Remove registered file and restore permissions without 'file' keyword"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch test.txt
    local initial_perms=$(get_file_permissions "test.txt")

    $GUARD_BIN add file test.txt
    $GUARD_BIN enable file test.txt

    # Verify file is guarded
    local guarded_perms=$(get_file_permissions "test.txt")

    # Run remove (without 'file' keyword)
    $GUARD_BIN remove test.txt
    local exit_code=$?

    # Assert
    assert_exit_code $exit_code 0 "guard remove should succeed"

    # File should not be in registry
    if ! file_in_registry "$(pwd)/test.txt"; then
        echo -e "${GREEN}✓ PASS${NC}: File is not in registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: File is still in registry"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Permissions should be restored
    local restored_perms=$(get_file_permissions "test.txt")
    assert_equals "$initial_perms" "$restored_perms" "Permissions should be restored to original"
}

# Run test
run_test test_remove_positive
print_test_summary 1
