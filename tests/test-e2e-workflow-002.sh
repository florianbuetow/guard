#!/bin/bash

# test-e2e-workflow-002.sh - OUTPUT FORMAT VALIDATION TESTS
# Tests complete workflows through the guard CLI to verify command sequences work correctly

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# OUTPUT FORMAT VALIDATION TESTS
# ============================================================================
test_init_output_format() {
    log_test "test_init_output_format" \
             "Verify init command output format matches CLI-INTERFACE-SPECS.md"

    output=$($GUARD_BIN init 000 testowner testgroup 2>&1)

    # Should have header
    assert_contains "$output" "Initialized .guardfile with:" "Init has correct header"

    # Should have indented config values
    if echo "$output" | grep -q "^  Mode:"; then
        echo -e "${GREEN}✓ PASS${NC}: Mode is indented"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Mode should be indented"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    if echo "$output" | grep -q "^  Owner:"; then
        echo -e "${GREEN}✓ PASS${NC}: Owner is indented"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Owner should be indented"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_init_output_format
print_test_summary 1
