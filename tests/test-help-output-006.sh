#!/bin/bash

# test-help-output-006.sh - ENABLE COMMAND HELP (Tutorial 2: guard enable collection alice)
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
# ENABLE COMMAND HELP (Tutorial 2: guard enable collection alice)
# ============================================================================
test_help_enable() {
    log_test "test_help_enable" \
             "guard help enable shows enable command help"

    output=$($GUARD_BIN help enable 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Should succeed"

    # Usage pattern from enable.go: "enable [file|collection] <names...>"
    assert_output_contains "$output" "enable" "Contains 'enable'"
    assert_output_contains "$output" "Enable" "Contains 'Enable'"
    assert_output_contains "$output" "protection" "Contains 'protection'"
    assert_output_contains "$output" "file" "Contains 'file'"
    assert_output_contains "$output" "collection" "Contains 'collection'"

    # Should contain examples
    assert_output_contains "$output" "guard enable" "Contains example"

    # Should show available subcommands
    assert_output_contains "$output" "Available Commands" "Shows available subcommands"
}

# Run test
run_test test_help_enable
print_test_summary 1
