#!/bin/bash

# test-disable-auto-detect-006.sh - DISABLE AUTO-DETECTION TESTS - EXPLICIT KEYWORD OVERRIDE
# Tests auto-detection of files vs collections: guard disable <arg>...
# Without explicit 'file' or 'collection' keyword

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# DISABLE AUTO-DETECTION TESTS - EXPLICIT KEYWORD OVERRIDE
# ============================================================================
test_disable_explicit_file_keyword() {
    log_test "test_disable_explicit_file_keyword" \
             "Explicit 'file' keyword overrides auto-detection"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch foo
    $GUARD_BIN add file foo
    $GUARD_BIN create foo  # Same name - would be ambiguous
    $GUARD_BIN enable file foo

    # Run disable with explicit 'file' keyword - should work
    $GUARD_BIN disable file foo
    local exit_code=$?

    # Assert
    assert_exit_code $exit_code 0 "guard disable file should succeed with explicit keyword"

    local file_flag=$(get_guard_flag "$(pwd)/foo")
    assert_equals "false" "$file_flag" "File should be unguarded"
}

# Run test
run_test test_disable_explicit_file_keyword
print_test_summary 1
