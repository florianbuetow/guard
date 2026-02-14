#!/bin/bash

# test-config-004.sh - Test 4: Config set owner (Positive)
# Tests configuration management (show and set operations)

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# Test 4: Config set owner (Positive)
# ============================================================================
test_config_set_owner_positive() {
    log_test "test_config_set_owner_positive" \
             "Positive test: guard config set owner updates owner"

    # Initialize guard
    $GUARD_BIN init 0644 flo staff > /dev/null 2>&1

    # Set new owner
    $GUARD_BIN config set owner root > /dev/null 2>&1
    local exit_code=$?

    # Assert exit code
    assert_exit_code $exit_code 0 "guard config set owner should succeed"

    # Verify owner was updated in .guardfile
    local owner=$(grep -A3 "^config:" .guardfile | grep "guard_owner:" | awk '{print $2}')
    assert_equals "root" "$owner" "guard_owner should be updated to root"
}

# Run test
run_test test_config_set_owner_positive
print_test_summary 1
