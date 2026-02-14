#!/bin/bash

# test-help-output-002.sh - INIT COMMAND HELP (Tutorial 1: guard init 0644 root wheel)
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
# INIT COMMAND HELP (Tutorial 1: guard init 0644 root wheel)
# ============================================================================
test_help_init() {
    log_test "test_help_init" \
             "guard help init shows init command help"

    output=$($GUARD_BIN help init 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Should succeed"

    # Usage pattern from init.go: "init [mode] [owner] [group]"
    assert_output_contains "$output" "init" "Contains 'init'"
    assert_output_contains "$output" "mode" "Contains 'mode'"
    assert_output_contains "$output" "owner" "Contains 'owner'"
    assert_output_contains "$output" "group" "Contains 'group'"
    assert_output_contains "$output" "Initialize" "Contains 'Initialize'"

    # Should contain examples (Tutorial 1 uses: guard init 0644 root wheel)
    assert_output_contains "$output" "guard init" "Contains example 'guard init'"

    # Should mention octal format
    assert_output_contains "$output" "000-777" "Mentions octal range 000-777"
}

# Run test
run_test test_help_init
print_test_summary 1
