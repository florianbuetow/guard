#!/bin/bash

# test-help-output-017.sh - RESET COMMAND HELP (CLI-SPECS lines 225-228)
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
# RESET COMMAND HELP (CLI-SPECS lines 225-228)
# ============================================================================
test_help_reset() {
    log_test "test_help_reset" \
             "guard help reset shows reset command help"

    output=$($GUARD_BIN help reset 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Should succeed"

    # From reset.go
    assert_output_contains "$output" "reset" "Contains 'reset'"
    assert_output_contains "$output" "Disable" "Mentions disabling guard"
    assert_output_contains "$output" "file" "Mentions files"
    assert_output_contains "$output" "collection" "Mentions collections"
}

# Run test
run_test test_help_reset
print_test_summary 1
