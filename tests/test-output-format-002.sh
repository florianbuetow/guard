#!/bin/bash

# test-output-format-002.sh - ENABLE OUTPUT FORMAT TESTS
# Verifies that CLI output matches the formats specified in CLI-INTERFACE-SPECS.md
# These tests document gaps between spec and implementation - failing tests indicate
# where the implementation needs to be updated to match the spec.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# ENABLE OUTPUT FORMAT TESTS
# ============================================================================
test_enable_output_format_single_file() {
    log_test "test_enable_output_format_single_file" \
             "Enable shows count format 'Guard enabled for N file(s)'"

    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch myfile.txt

    output=$($GUARD_BIN enable myfile.txt 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Enable should succeed"
    assert_contains "$output" "Guard enabled for" "Output should contain 'Guard enabled for'"
    assert_contains "$output" "file(s)" "Output should contain 'file(s)' count format"
}

# Run test
run_test test_enable_output_format_single_file
print_test_summary 1
