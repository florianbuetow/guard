#!/bin/bash

# test-help-output-001.sh - ROOT HELP TESTS
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
# ROOT HELP TESTS
# ============================================================================
test_guard_no_args() {
    log_test "test_guard_no_args" \
             "guard with no arguments shows help (CLI-SPECS line 155-156)"

    output=$($GUARD_BIN 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Should succeed"

    # Should contain main description (from main.go)
    assert_output_contains "$output" "Guard" "Contains 'Guard'"
    assert_output_contains "$output" "permission" "Contains 'permission'"

    # Should list available commands section
    assert_output_contains "$output" "Available Commands" "Contains 'Available Commands'"

    # All commands should be present
    assert_output_contains "$output" "init" "Lists init command"
    assert_output_contains "$output" "add" "Lists add command"
    assert_output_contains "$output" "remove" "Lists remove command"
    assert_output_contains "$output" "toggle" "Lists toggle command"
    assert_output_contains "$output" "enable" "Lists enable command"
    assert_output_contains "$output" "disable" "Lists disable command"
    assert_output_contains "$output" "create" "Lists create command"
    assert_output_contains "$output" "destroy" "Lists destroy command"
    assert_output_contains "$output" "update" "Lists update command"
    assert_output_contains "$output" "clear" "Lists clear command"
    assert_output_contains "$output" "show" "Lists show command"
    assert_output_contains "$output" "info" "Lists info command"
    assert_output_contains "$output" "version" "Lists version command"
    assert_output_contains "$output" "help" "Lists help command"
    assert_output_contains "$output" "config" "Lists config command"
    assert_output_contains "$output" "cleanup" "Lists cleanup command"
    assert_output_contains "$output" "reset" "Lists reset command"
    assert_output_contains "$output" "uninstall" "Lists uninstall command"
    assert_output_contains "$output" "completion" "Lists completion command"
}

# Run test
run_test test_guard_no_args
print_test_summary 1
