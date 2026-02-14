#!/bin/bash

# test-config-011.sh - Test 11: Bulk config set - update mode and owner (Positive)
# Tests configuration management (show and set operations)

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# Test 11: Bulk config set - update mode and owner (Positive)
# ============================================================================
test_config_set_bulk_mode_owner() {
    log_test "test_config_set_bulk_mode_owner" \
             "Positive test: guard config set 0600 root updates mode and owner"

    # Initialize guard
    $GUARD_BIN init 0644 flo staff > /dev/null 2>&1

    # Set mode and owner using bulk command
    $GUARD_BIN config set 0600 root > /dev/null 2>&1
    local exit_code=$?

    # Assert exit code
    assert_exit_code $exit_code 0 "guard config set 0600 root should succeed"

    # Verify mode and owner were updated
    local mode=$(get_guard_mode_from_config)
    local owner=$(grep -A3 "^config:" .guardfile | grep "guard_owner:" | awk '{print $2}')
    assert_equals "0600" "$mode" "guard_mode should be updated to 0600"
    assert_equals "root" "$owner" "guard_owner should be updated to root"

    # Verify group remains unchanged
    local group=$(grep -A4 "^config:" .guardfile | grep "guard_group:" | awk '{print $2}')
    assert_equals "staff" "$group" "guard_group should remain staff"
}

# Run test
run_test test_config_set_bulk_mode_owner
print_test_summary 1
