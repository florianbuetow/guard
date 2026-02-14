#!/bin/bash

# test-config-012.sh - Test 12: Bulk config set - update all three (Positive)
# Tests configuration management (show and set operations)

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# Test 12: Bulk config set - update all three (Positive)
# ============================================================================
test_config_set_bulk_all() {
    log_test "test_config_set_bulk_all" \
             "Positive test: guard config set 0600 root wheel updates all"

    # Initialize guard
    $GUARD_BIN init 0644 flo staff > /dev/null 2>&1

    # Set all three using bulk command
    $GUARD_BIN config set 0600 root wheel > /dev/null 2>&1
    local exit_code=$?

    # Assert exit code
    assert_exit_code $exit_code 0 "guard config set 0600 root wheel should succeed"

    # Verify all three were updated
    local mode=$(get_guard_mode_from_config)
    local owner=$(grep -A3 "^config:" .guardfile | grep "guard_owner:" | awk '{print $2}')
    local group=$(grep -A4 "^config:" .guardfile | grep "guard_group:" | awk '{print $2}')
    assert_equals "0600" "$mode" "guard_mode should be updated to 0600"
    assert_equals "root" "$owner" "guard_owner should be updated to root"
    assert_equals "wheel" "$group" "guard_group should be updated to wheel"
}

# Run test
run_test test_config_set_bulk_all
print_test_summary 1
