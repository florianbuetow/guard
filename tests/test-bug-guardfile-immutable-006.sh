#!/bin/bash

# test-bug-guardfile-immutable-006.sh - Verify config set group works normally
#
# This file tests that guard config set group works under normal conditions
# (without immutable flag). This verifies the affected code path works
# when the immutable flag bug is not triggered.

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# FUNCTIONAL TEST: Verify config set group works normally
# ============================================================================

test_config_group_works_normally() {
    log_test "test_config_group_works_normally" \
             "Verify: guard config set group works under normal conditions"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"

    # Change config group using correct syntax: guard config set group <value>
    local new_group="$(get_current_group)"
    local output
    output=$($GUARD_BIN config set group "$new_group" 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "Config set group command should succeed"
    assert_contains "$output" "$new_group" "Output should show new group"
}

# Run test
run_test test_config_group_works_normally
print_test_summary 1
