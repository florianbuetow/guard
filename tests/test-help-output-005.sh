#!/bin/bash

# test-help-output-005.sh - TOGGLE COMMAND HELP (Tutorial 1: guard toggle file test.txt)
# Tests 'guard', 'guard help', and 'guard help <command>' for all commands
# Based on CLI-INTERFACE-SPECS.md, TUTORIAL-1.md, TUTORIAL-2.md, and source code
#
# Commands from tutorials that must be documented in help:
# Tutorial 1:
#   - guard init 0644 root wheel
#   - guard add file test.txt
#   - guard toggle file test.txt
# Tutorial 2:
#   - guard create alice
#   - guard show collection alice
#   - guard update alice add alice1.txt alice2.txt shared.txt
#   - guard update alice remove shared.txt
#   - guard enable collection alice
#   - guard disable collection alice
#   - guard toggle collection alice bob
#   - guard show file shared.txt
#   - guard show collection
#   - guard uninstall

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# TOGGLE COMMAND HELP (Tutorial 1: guard toggle file test.txt)
# ============================================================================
test_help_toggle() {
    log_test "test_help_toggle" \
             "guard help toggle shows toggle command help"

    output=$($GUARD_BIN help toggle 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Should succeed"

    # Usage pattern from toggle.go: "toggle [file|collection] <names...>"
    assert_output_contains "$output" "toggle" "Contains 'toggle'"
    assert_output_contains "$output" "file" "Contains 'file'"
    assert_output_contains "$output" "collection" "Contains 'collection'"
    assert_output_contains "$output" "Auto-detection" "Mentions auto-detection"

    # Should contain examples
    assert_output_contains "$output" "guard toggle" "Contains example"

    # Should show available subcommands
    assert_output_contains "$output" "Available Commands" "Shows available subcommands"
}

# Run test
run_test test_help_toggle
print_test_summary 1
