#!/bin/bash

# test-output-format-007.sh - DISABLE FOLDER/COLLECTION OUTPUT TESTS
# Verifies that CLI output matches the formats specified in CLI-INTERFACE-SPECS.md
# These tests document gaps between spec and implementation - failing tests indicate
# where the implementation needs to be updated to match the spec.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# DISABLE FOLDER/COLLECTION OUTPUT TESTS
# ============================================================================
test_disable_output_format_folder() {
    log_test "test_disable_output_format_folder" \
             "Disable folder shows 'Guard disabled for N folder(s)'"

    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    mkdir -p mydir
    touch mydir/file.txt
    $GUARD_BIN enable folder mydir >/dev/null 2>&1

    output=$($GUARD_BIN disable folder mydir 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Disable folder should succeed"
    assert_contains "$output" "Guard disabled for" "Output should contain 'Guard disabled for'"
    assert_contains "$output" "folder" "Output should mention folder"
}

# Run test
run_test test_disable_output_format_folder
print_test_summary 1
