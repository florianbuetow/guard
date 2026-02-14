#!/bin/bash

# test-config-013.sh - Test 13: Bulk config set with invalid mode (Negative)
# Tests configuration management (show and set operations)

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# Test 13: Bulk config set with invalid mode (Negative)
# ============================================================================
test_config_set_bulk_invalid_mode() {
    log_test "test_config_set_bulk_invalid_mode" \
             "Negative test: guard config set 999 root wheel fails"

    # Initialize guard
    $GUARD_BIN init 0644 flo staff > /dev/null 2>&1

    # Try bulk set with invalid mode
    set +e
    $GUARD_BIN config set 999 root wheel > /dev/null 2>&1
    local exit_code=$?
    set -e

    # Assert exit code 1
    assert_exit_code $exit_code 1 "guard config set 999 root wheel should fail"

    # Verify nothing was changed
    local mode=$(get_guard_mode_from_config)
    local owner=$(grep -A3 "^config:" .guardfile | grep "guard_owner:" | awk '{print $2}')
    local group=$(grep -A4 "^config:" .guardfile | grep "guard_group:" | awk '{print $2}')
    assert_equals "0644" "$mode" "guard_mode should remain 0644"
    assert_equals "flo" "$owner" "guard_owner should remain flo"
    assert_equals "staff" "$group" "guard_group should remain staff"
}

# Run test
run_test test_config_set_bulk_invalid_mode
print_test_summary 1
