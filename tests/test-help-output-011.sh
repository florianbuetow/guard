#!/bin/bash

# test-help-output-011.sh - UPDATE COMMAND HELP (Tutorial 2: guard update alice add ..., guard update alice remove ...)
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
# UPDATE COMMAND HELP (Tutorial 2: guard update alice add ..., guard update alice remove ...)
# ============================================================================
test_help_update() {
    log_test "test_help_update" \
             "guard help update shows update command help"

    output=$($GUARD_BIN help update 2>&1)
    local exit_code=$?

    assert_exit_code $exit_code 0 "Should succeed"

    # Usage pattern from update.go: "update <collection> add|remove <files>..."
    assert_output_contains "$output" "update" "Contains 'update'"
    assert_output_contains "$output" "add" "Contains 'add'"
    assert_output_contains "$output" "remove" "Contains 'remove'"
    assert_output_contains "$output" "collection" "Contains 'collection'"

    # Should contain examples (Tutorial 2 uses: guard update alice add ...)
    assert_output_contains "$output" "guard update" "Contains example 'guard update'"

    # Should explain what it does
    assert_output_contains "$output" "Add" "Mentions adding files"
}

# Run test
run_test test_help_update
print_test_summary 1
