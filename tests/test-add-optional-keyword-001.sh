#!/bin/bash

# test-add-optional-keyword-001.sh - ADD FILE TESTS (optional 'file' keyword)
# Tests registering files with: guard add <file>... (without explicit 'file' keyword)
# Replaces: guard add file <file>...

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# ADD FILE TESTS (optional 'file' keyword)
# ============================================================================
test_add_positive() {
    log_test "test_add_positive" \
             "Positive test: Add existing file to registry without 'file' keyword"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch test1.txt
    local initial_perms=$(get_file_permissions "test1.txt")

    # Run (without 'file' keyword)
    $GUARD_BIN add test1.txt
    local exit_code=$?

    # Assert
    assert_exit_code $exit_code 0 "guard add should succeed"

    if file_in_registry "$(pwd)/test1.txt"; then
        echo -e "${GREEN}✓ PASS${NC}: File is in registry"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: File is not in registry"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    local guard_flag=$(get_guard_flag "$(pwd)/test1.txt")
    assert_equals "false" "$guard_flag" "Guard flag should be false"

    local current_perms=$(get_file_permissions "test1.txt")
    assert_equals "$initial_perms" "$current_perms" "File permissions should be unchanged"
}

# Run test
run_test test_add_positive
print_test_summary 1
