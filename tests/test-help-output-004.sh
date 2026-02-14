#!/bin/bash

# test-help-output-004.sh - REMOVE COMMAND HELP
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
# REMOVE COMMAND HELP
# ============================================================================
test_help_remove() {
    log_test "test_help_remove" \
             "guard help remove shows remove command help"

    output=$($GUARD_BIN help remove 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Should succeed"

    # Usage pattern from remove.go: "remove [file] <paths>..."
    assert_output_contains "$output" "remove" "Contains 'remove'"
    assert_output_contains "$output" "file" "Contains 'file'"
    assert_output_contains "$output" "registry" "Contains 'registry'"

    # Should explain what happens when removing (from remove.go Long description)
    assert_output_contains "$output" "collection" "Mentions collection removal"
    assert_output_contains "$output" "permission" "Mentions permission restoration"

    # Should show available subcommands
    assert_output_contains "$output" "Available Commands" "Shows available subcommands"
}

# Run test
run_test test_help_remove
print_test_summary 1
