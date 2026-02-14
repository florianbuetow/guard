#!/bin/bash

# test-config-015.sh - Test 15: Verify config persists across commands
# Tests configuration management (show and set operations)

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# Test 15: Verify config persists across commands
# ============================================================================
test_config_persistence() {
    log_test "test_config_persistence" \
             "Positive test: config changes persist across commands"

    # Initialize guard
    $GUARD_BIN init 0644 flo staff > /dev/null 2>&1

    # Change config
    $GUARD_BIN config set 0600 root wheel > /dev/null 2>&1

    # Show config (should reflect changes)
    local output=$($GUARD_BIN config show 2>&1)

    # Verify all values persisted
    assert_contains "$output" "0600" "Config show should display updated mode"
    assert_contains "$output" "root" "Config show should display updated owner"
    assert_contains "$output" "wheel" "Config show should display updated group"
}

# Run test
run_test test_config_persistence
print_test_summary 1
