#!/bin/bash

# test-output-format-001.sh - TOGGLE OUTPUT FORMAT TESTS
# Verifies that CLI output matches the formats specified in CLI-INTERFACE-SPECS.md
# These tests document gaps between spec and implementation - failing tests indicate
# where the implementation needs to be updated to match the spec.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# TOGGLE OUTPUT FORMAT TESTS
# ============================================================================
test_toggle_output_format_single_file() {
    log_test "test_toggle_output_format_single_file" \
             "Toggle output contains 'Guard enabled for' message"

    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch myfile.txt

    output=$($GUARD_BIN toggle myfile.txt 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Toggle should succeed"
    assert_contains "$output" "Guard enabled for" "Output should contain 'Guard enabled for'"
    assert_contains "$output" "myfile.txt" "Output should contain filename"
}

# Run test
run_test test_toggle_output_format_single_file
print_test_summary 1
