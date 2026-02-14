#!/bin/bash

# test-output-format-003.sh - DISABLE OUTPUT FORMAT TESTS
# Verifies that CLI output matches the formats specified in CLI-INTERFACE-SPECS.md
# These tests document gaps between spec and implementation - failing tests indicate
# where the implementation needs to be updated to match the spec.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# DISABLE OUTPUT FORMAT TESTS
# ============================================================================
test_disable_output_format_single_file() {
    log_test "test_disable_output_format_single_file" \
             "Disable shows count format 'Guard disabled for N file(s)'"

    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch myfile.txt
    $GUARD_BIN enable file myfile.txt >/dev/null 2>&1

    output=$($GUARD_BIN disable myfile.txt 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Disable should succeed"
    assert_contains "$output" "Guard disabled for" "Output should contain 'Guard disabled for'"
    assert_contains "$output" "file(s)" "Output should contain 'file(s)' count format"
}

# Run test
run_test test_disable_output_format_single_file
print_test_summary 1
