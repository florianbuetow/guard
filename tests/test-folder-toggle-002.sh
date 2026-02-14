#!/bin/bash

# test-folder-toggle-002.sh - FOLDER TOGGLE ERROR TESTS
# Verifies that folder operations create a folder entry in .guardfile,
# register all immediate files (non-recursive), and sync guard state.
#
# Based on CLI-INTERFACE-SPECS.md folder management section.

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# FOLDER TOGGLE ERROR TESTS
# ============================================================================
test_toggle_folder_error_no_args() {
    log_test "test_toggle_folder_error_no_args" \
             "Toggle folder errors when no arguments provided"

    # Setup: Initialize guard
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"

    # === ACTION: Toggle folder with no args ===
    set +e
    local output
    output=$($GUARD_BIN toggle folder 2>&1)
    local exit_code=$?
    set -e

    # Assert: Exit code 1 and error message
    assert_exit_code $exit_code 1 "Should fail with exit code 1"
    assert_contains "$output" "No folders specified" "Should show 'No folders specified' error"
}

# Run test
run_test test_toggle_folder_error_no_args
print_test_summary 1
