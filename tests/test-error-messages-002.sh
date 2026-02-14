#!/bin/bash

# test-error-messages-002.sh - AMBIGUITY ERROR TESTS
# Verifies that error/warning messages match the formats specified in CLI-INTERFACE-SPECS.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# AMBIGUITY ERROR TESTS
# ============================================================================
test_error_ambiguous_file_collection() {
    log_test "test_error_ambiguous_file_collection" \
             "File takes priority when file and collection have same name"

    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"

    # Create file named 'foo'
    touch foo

    # Create collection also named 'foo'
    touch other.txt
    $GUARD_BIN add other.txt
    $GUARD_BIN create foo
    $GUARD_BIN update foo add other.txt

    # Toggle 'foo' without explicit keyword - file takes priority (per CLI spec)
    set +e
    output=$($GUARD_BIN toggle foo 2>&1)
    local exit_code=$?
    set -e

    # Per CLI spec: "A file path like `main.go` is always treated as a file
    # (even if a collection named `main.go` exists)"
    assert_exit_code $exit_code 0 "Toggle should succeed (file takes priority)"
    assert_contains "$output" "Guard enabled for foo" "File should be toggled"
}

# Run test
run_test test_error_ambiguous_file_collection
print_test_summary 1
