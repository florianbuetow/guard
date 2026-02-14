#!/bin/bash

# test-help-output-016.sh - CLEANUP COMMAND HELP (CLI-SPECS lines 221-223)
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
# CLEANUP COMMAND HELP (CLI-SPECS lines 221-223)
# ============================================================================
test_help_cleanup() {
    log_test "test_help_cleanup" \
             "guard help cleanup shows cleanup command help"

    output=$($GUARD_BIN help cleanup 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Should succeed"

    # From cleanup.go
    assert_output_contains "$output" "cleanup" "Contains 'cleanup'"
    assert_output_contains "$output" "empty" "Mentions empty collections"
    assert_output_contains "$output" "don't exist" "Mentions files that don't exist"
}

# Run test
run_test test_help_cleanup
print_test_summary 1
