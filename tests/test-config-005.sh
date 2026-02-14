#!/bin/bash

# test-config-005.sh - Test 5: Config set group (Positive)
# Tests configuration management (show and set operations)

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# Test 5: Config set group (Positive)
# ============================================================================
test_config_set_group_positive() {
    log_test "test_config_set_group_positive" \
             "Positive test: guard config set group updates group"

    # Initialize guard
    $GUARD_BIN init 0644 flo staff > /dev/null 2>&1

    # Set new group
    $GUARD_BIN config set group wheel > /dev/null 2>&1
    local exit_code=$?

    # Assert exit code
    assert_exit_code $exit_code 0 "guard config set group should succeed"

    # Verify group was updated in .guardfile
    local group=$(grep -A4 "^config:" .guardfile | grep "guard_group:" | awk '{print $2}')
    assert_equals "wheel" "$group" "guard_group should be updated to wheel"
}

# Run test
run_test test_config_set_group_positive
print_test_summary 1
