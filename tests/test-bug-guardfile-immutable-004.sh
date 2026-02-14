#!/bin/bash

# test-bug-guardfile-immutable-004.sh - Verify config set mode works normally
#
# This file tests that guard config set mode works under normal conditions
# (without immutable flag). This verifies the affected code path works
# when the immutable flag bug is not triggered.

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# FUNCTIONAL TEST: Verify config commands work normally
# ============================================================================

test_config_mode_works_normally() {
    log_test "test_config_mode_works_normally" \
             "Verify: guard config set mode works under normal conditions"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"

    # Change config mode using correct syntax: guard config set mode <value>
    local output
    output=$($GUARD_BIN config set mode 644 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "Config set mode command should succeed"
    assert_contains "$output" "644" "Output should show new mode"

    # Verify the change was saved
    local saved_mode=$(get_guard_mode_from_config)
    # Note: saved_mode might be "0644" or "644" depending on implementation
    if [[ "$saved_mode" == "644" ]] || [[ "$saved_mode" == "0644" ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Mode was saved correctly"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Mode was not saved correctly (got: $saved_mode)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_config_mode_works_normally
print_test_summary 1
