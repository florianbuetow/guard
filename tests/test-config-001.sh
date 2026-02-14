#!/bin/bash

# test-config-001.sh - Test 1: Config show with valid .guardfile (Positive)
# Tests configuration management (show and set operations)

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# Test 1: Config show with valid .guardfile (Positive)
# ============================================================================
test_config_show_positive() {
    log_test "test_config_show_positive" \
             "Positive test: guard config show displays current config"

    # Initialize guard first
    $GUARD_BIN init 0644 flo staff > /dev/null 2>&1

    # Run guard config show
    local output=$($GUARD_BIN config show 2>&1)
    local exit_code=$?

    # Assert exit code
    assert_exit_code $exit_code 0 "guard config show should succeed"

    # Assert output contains mode, owner, group
    assert_contains "$output" "Mode:" "Output should contain Mode"
    assert_contains "$output" "Owner:" "Output should contain Owner"
    assert_contains "$output" "Group:" "Output should contain Group"
    assert_contains "$output" "0644" "Output should contain mode value 0644"
}

# Run test
run_test test_config_show_positive
print_test_summary 1
