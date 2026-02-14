#!/bin/bash

# test-output-format-005.sh - AUTO-REGISTRATION OUTPUT FORMAT TESTS
# Verifies that CLI output matches the formats specified in CLI-INTERFACE-SPECS.md
# These tests document gaps between spec and implementation - failing tests indicate
# where the implementation needs to be updated to match the spec.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# AUTO-REGISTRATION OUTPUT FORMAT TESTS
# ============================================================================
test_toggle_auto_registration_output() {
    log_test "test_toggle_auto_registration_output" \
             "Toggle with auto-registration shows 'Registered' message"

    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch newfile.txt
    # File not in registry, toggle should auto-register

    output=$($GUARD_BIN toggle newfile.txt 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Toggle should succeed"
    assert_contains "$output" "Registered" "Output should contain 'Registered' message"
}

# Run test
run_test test_toggle_auto_registration_output
print_test_summary 1
