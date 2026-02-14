#!/bin/bash

# test-output-specs-014.sh - CONFIG SHOW COMMAND OUTPUT TESTS
# Validates that command output matches the formats defined in CLI-INTERFACE-SPECS.md

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# CONFIG SHOW COMMAND OUTPUT TESTS
# ============================================================================
test_config_show_success_output() {
    log_test "test_config_show_success_output" \
             "Verify config show output format"

    # Setup
    $GUARD_BIN init 0640 $USER staff > /dev/null 2>&1

    # Run
    set +e
    output=$($GUARD_BIN config show 2>&1)
    local exit_code=$?
    set -e

    # Assert exit code
    assert_exit_code $exit_code 0 "Should succeed"

    # Check for "Configuration:" header
    if echo "$output" | grep -q "^Configuration:$"; then
        echo -e "${GREEN}✓ PASS${NC}: Output starts with 'Configuration:'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should start with 'Configuration:'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for Mode line
    if echo "$output" | grep -qE "^  Mode:"; then
        echo -e "${GREEN}✓ PASS${NC}: Output contains indented 'Mode:'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output should contain indented 'Mode:'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_config_show_success_output
print_test_summary 1
