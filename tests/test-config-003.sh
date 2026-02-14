#!/bin/bash

# test-config-003.sh - Test 3: Config set mode (Positive)
# Tests configuration management (show and set operations)

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# Test 3: Config set mode (Positive)
# ============================================================================
test_config_set_mode_positive() {
    log_test "test_config_set_mode_positive" \
             "Positive test: guard config set mode updates mode"

    # Initialize guard
    $GUARD_BIN init 0644 flo staff > /dev/null 2>&1

    # Set new mode
    $GUARD_BIN config set mode 0600 > /dev/null 2>&1
    local exit_code=$?

    # Assert exit code
    assert_exit_code $exit_code 0 "guard config set mode should succeed"

    # Verify mode was updated
    local mode=$(get_guard_mode_from_config)
    assert_equals "0600" "$mode" "guard_mode should be updated to 0600"
}

# Run test
run_test test_config_set_mode_positive
print_test_summary 1
