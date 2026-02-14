#!/bin/bash

# test-config-006.sh - Test 6: Config set with invalid mode (Negative)
# Tests configuration management (show and set operations)

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# Test 6: Config set with invalid mode (Negative)
# ============================================================================
test_config_set_invalid_mode() {
    log_test "test_config_set_invalid_mode" \
             "Negative test: guard config set mode with invalid octal (999)"

    # Initialize guard
    $GUARD_BIN init 0644 flo staff > /dev/null 2>&1

    # Try to set invalid mode
    set +e
    $GUARD_BIN config set mode 999 > /dev/null 2>&1
    local exit_code=$?
    set -e

    # Assert exit code 1
    assert_exit_code $exit_code 1 "guard config set mode 999 should fail"

    # Verify mode was NOT changed
    local mode=$(get_guard_mode_from_config)
    assert_equals "0644" "$mode" "guard_mode should remain 0644"
}

# Run test
run_test test_config_set_invalid_mode
print_test_summary 1
