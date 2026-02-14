#!/bin/bash

# test-help-output-007.sh - DISABLE COMMAND HELP (Tutorial 2: guard disable collection alice)
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
# DISABLE COMMAND HELP (Tutorial 2: guard disable collection alice)
# ============================================================================
test_help_disable() {
    log_test "test_help_disable" \
             "guard help disable shows disable command help"

    output=$($GUARD_BIN help disable 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Should succeed"

    # Usage pattern from disable.go: "disable [file|collection] <names...>"
    assert_output_contains "$output" "disable" "Contains 'disable'"
    assert_output_contains "$output" "Disable" "Contains 'Disable'"
    assert_output_contains "$output" "protection" "Contains 'protection'"
    assert_output_contains "$output" "file" "Contains 'file'"
    assert_output_contains "$output" "collection" "Contains 'collection'"

    # Should mention permission restoration
    assert_output_contains "$output" "permission" "Mentions permission restoration"

    # Should show available subcommands
    assert_output_contains "$output" "Available Commands" "Shows available subcommands"
}

# Run test
run_test test_help_disable
print_test_summary 1
