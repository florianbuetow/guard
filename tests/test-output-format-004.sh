#!/bin/bash

# test-output-format-004.sh - PARTIAL/SKIP OUTPUT FORMAT TESTS
# Verifies that CLI output matches the formats specified in CLI-INTERFACE-SPECS.md
# These tests document gaps between spec and implementation - failing tests indicate
# where the implementation needs to be updated to match the spec.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# PARTIAL/SKIP OUTPUT FORMAT TESTS
# ============================================================================
test_enable_skipped_output_format() {
    log_test "test_enable_skipped_output_format" \
             "Enable already-enabled shows skip message"

    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch myfile.txt
    $GUARD_BIN enable file myfile.txt >/dev/null 2>&1

    # Enable again - should show skipped
    output=$($GUARD_BIN enable myfile.txt 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Enable should succeed (idempotent)"
    assert_contains "$output" "Skipped" "Output should contain 'Skipped' message"
    assert_contains "$output" "already enabled" "Output should indicate already enabled"
}

# Run test
run_test test_enable_skipped_output_format
print_test_summary 1
