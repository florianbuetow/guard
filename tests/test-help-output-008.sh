#!/bin/bash

# test-help-output-008.sh - CREATE COMMAND HELP (Tutorial 2: guard create alice)
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
# CREATE COMMAND HELP (Tutorial 2: guard create alice)
# ============================================================================
test_help_create() {
    log_test "test_help_create" \
             "guard help create shows create command help"

    output=$($GUARD_BIN help create 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Should succeed"

    # Usage pattern from create.go: "create <collection>..."
    assert_output_contains "$output" "create" "Contains 'create'"
    assert_output_contains "$output" "Create" "Contains 'Create'"
    assert_output_contains "$output" "collection" "Contains 'collection'"

    # Should mention reserved keywords (CLI-SPECS line 21)
    assert_output_contains "$output" "reserved" "Mentions reserved keywords"

    # Should contain examples (Tutorial 2 uses: guard create alice)
    assert_output_contains "$output" "guard create" "Contains example"
}

# Run test
run_test test_help_create
print_test_summary 1
