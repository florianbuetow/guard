#!/bin/bash

# test-update-005.sh - UPDATE ERROR CASES
# Tests modifying collection membership with: guard update <collection> add|remove <files>...
# Replaces: guard add file ... to ... and guard remove file ... from ...

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# UPDATE ERROR CASES
# ============================================================================
test_update_no_args() {
    log_test "test_update_no_args" \
             "Negative test: guard update without arguments"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"

    # Run
    set +e
    $GUARD_BIN update > /dev/null 2>&1
    local exit_code=$?
    set -e

    # Assert
    assert_exit_code $exit_code 1 "guard update without args should fail"
}

# Run test
run_test test_update_no_args
print_test_summary 1
