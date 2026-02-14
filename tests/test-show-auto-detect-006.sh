#!/bin/bash

# test-show-auto-detect-006.sh - SHOW AUTO-DETECTION TESTS - EXPLICIT KEYWORD OVERRIDE
# Tests auto-detection of files vs collections: guard show <arg>...
# Without explicit 'file' or 'collection' keyword

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# SHOW AUTO-DETECTION TESTS - EXPLICIT KEYWORD OVERRIDE
# ============================================================================
test_show_explicit_file_keyword() {
    log_test "test_show_explicit_file_keyword" \
             "Explicit 'file' keyword overrides auto-detection"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch foo
    $GUARD_BIN add file foo
    $GUARD_BIN create foo  # Same name - would be ambiguous

    # Run show with explicit 'file' keyword - should work
    set +e
    output=$($GUARD_BIN show file foo 2>&1)
    local exit_code=$?
    set -e

    # Assert
    assert_exit_code $exit_code 0 "guard show file should succeed with explicit keyword"

    # Check that file info is displayed
    if [[ "$output" == *"foo"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: File info displayed"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: File info not displayed"
        echo "Got: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_show_explicit_file_keyword
print_test_summary 1
