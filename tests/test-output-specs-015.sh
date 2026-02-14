#!/bin/bash

# test-output-specs-015.sh - CONFIG SET COMMAND OUTPUT TESTS
# Validates that command output matches the formats defined in CLI-INTERFACE-SPECS.md

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# CONFIG SET COMMAND OUTPUT TESTS
# ============================================================================
test_config_set_success_output() {
    log_test "test_config_set_success_output" \
             "Verify config set success output format"

    # Setup
    $GUARD_BIN init 0640 $USER staff > /dev/null 2>&1

    # Run
    set +e
    output=$($GUARD_BIN config set mode 0600 2>&1)
    local exit_code=$?
    set -e

    # Assert exit code
    assert_exit_code $exit_code 0 "Should succeed"

    # Check for "Config updated:" header
    if echo "$output" | grep -q "^Config updated:$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output starts with 'Config updated:'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should start with 'Config updated:'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for Mode value
    if echo "$output" | grep -qE "^  Mode: 0600$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output contains 'Mode: 0600'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should contain 'Mode: 0600'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_config_set_success_output
print_test_summary 1
