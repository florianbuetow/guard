#!/bin/bash

# test-config-010.sh - Test 10: Bulk config set - update only mode (Positive)
# Tests configuration management (show and set operations)

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# Test 10: Bulk config set - update only mode (Positive)
# ============================================================================
test_config_set_bulk_mode_only() {
    log_test "test_config_set_bulk_mode_only" \
             "Positive test: guard config set 0600 updates only mode"

    # Initialize guard
    $GUARD_BIN init 0644 flo staff > /dev/null 2>&1

    # Set only mode using bulk command
    $GUARD_BIN config set 0600 > /dev/null 2>&1
    local exit_code=$?

    # Assert exit code
    assert_exit_code $exit_code 0 "guard config set 0600 should succeed"

    # Verify mode was updated
    local mode=$(get_guard_mode_from_config)
    assert_equals "0600" "$mode" "guard_mode should be updated to 0600"

    # Verify owner and group remain unchanged
    local owner=$(grep -A3 "^config:" .guardfile | grep "guard_owner:" | awk '{print $2}')
    local group=$(grep -A4 "^config:" .guardfile | grep "guard_group:" | awk '{print $2}')
    assert_equals "flo" "$owner" "guard_owner should remain flo"
    assert_equals "staff" "$group" "guard_group should remain staff"
}

# Run test
run_test test_config_set_bulk_mode_only
print_test_summary 1
