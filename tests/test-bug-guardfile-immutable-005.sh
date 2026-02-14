#!/bin/bash

# test-bug-guardfile-immutable-005.sh - Verify config set owner works normally
#
# This file tests that guard config set owner works under normal conditions
# (without immutable flag). This verifies the affected code path works
# when the immutable flag bug is not triggered.

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# FUNCTIONAL TEST: Verify config set owner works normally
# ============================================================================

test_config_owner_works_normally() {
    log_test "test_config_owner_works_normally" \
             "Verify: guard config set owner works under normal conditions"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"

    # Change config owner using correct syntax: guard config set owner <value>
    local new_owner="$(get_current_user)"
    local output
    output=$($GUARD_BIN config set owner "$new_owner" 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "Config set owner command should succeed"
    assert_contains "$output" "$new_owner" "Output should show new owner"
}

# Run test
run_test test_config_owner_works_normally
print_test_summary 1
