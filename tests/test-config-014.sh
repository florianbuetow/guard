#!/bin/bash

# test-config-014.sh - Test 14: Config set without .guardfile (Negative)
# Tests configuration management (show and set operations)

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# Test 14: Config set without .guardfile (Negative)
# ============================================================================
test_config_set_no_guardfile() {
    log_test "test_config_set_no_guardfile" \
             "Negative test: guard config set fails without .guardfile"

    # Ensure no .guardfile exists

    # Try to set config
    set +e
    $GUARD_BIN config set mode 0600 > /dev/null 2>&1
    local exit_code=$?
    set -e

    # Assert exit code 1
    assert_exit_code $exit_code 1 "guard config set without .guardfile should fail"
}

# Run test
run_test test_config_set_no_guardfile
print_test_summary 1
