#!/bin/bash

# test-help-output-009.sh - DESTROY COMMAND HELP (Tutorial 2 Summary mentions: guard destroy <name>)
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
# DESTROY COMMAND HELP (Tutorial 2 Summary mentions: guard destroy <name>)
# ============================================================================
test_help_destroy() {
    log_test "test_help_destroy" \
             "guard help destroy shows destroy command help"

    output=$($GUARD_BIN help destroy 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Should succeed"

    # Usage pattern from destroy.go: "destroy <collection>..."
    assert_output_contains "$output" "destroy" "Contains 'destroy'"
    assert_output_contains "$output" "Remove" "Contains 'Remove'"
    assert_output_contains "$output" "collection" "Contains 'collection'"

    # Should explain what happens (from destroy.go Long description)
    assert_output_contains "$output" "Disable" "Mentions disabling guard"
    assert_output_contains "$output" "registry" "Mentions registry"

    # Should contain examples
    assert_output_contains "$output" "guard destroy" "Contains example"
}

# Run test
run_test test_help_destroy
print_test_summary 1
