#!/bin/bash

# test-help-output-014.sh - VERSION COMMAND HELP (CLI-SPECS line 149-150)
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
# VERSION COMMAND HELP (CLI-SPECS line 149-150)
# ============================================================================
test_help_version() {
    log_test "test_help_version" \
             "guard help version shows version command help"

    output=$($GUARD_BIN help version 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Should succeed"

    assert_output_contains "$output" "version" "Contains 'version'"
}

# Run test
run_test test_help_version
print_test_summary 1
