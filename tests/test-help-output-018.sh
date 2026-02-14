#!/bin/bash

# test-help-output-018.sh - UNINSTALL COMMAND HELP (Tutorial 2: guard uninstall, CLI-SPECS lines 230-234)
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
# UNINSTALL COMMAND HELP (Tutorial 2: guard uninstall, CLI-SPECS lines 230-234)
# ============================================================================
test_help_uninstall() {
    log_test "test_help_uninstall" \
             "guard help uninstall shows uninstall command help"

    output=$($GUARD_BIN help uninstall 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Should succeed"

    # From uninstall.go
    assert_output_contains "$output" "uninstall" "Contains 'uninstall'"

    # Should explain the steps (from uninstall.go Long description)
    assert_output_contains "$output" "reset" "Mentions reset step"
    assert_output_contains "$output" "cleanup" "Mentions cleanup step"
    assert_output_contains "$output" ".guardfile" "Mentions .guardfile deletion"
}

# Run test
run_test test_help_uninstall
print_test_summary 1
