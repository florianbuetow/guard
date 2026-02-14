#!/bin/bash

# test-output-specs-001.sh - INIT COMMAND OUTPUT TESTS
# Validates that command output matches the formats defined in CLI-INTERFACE-SPECS.md

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# INIT COMMAND OUTPUT TESTS
# ============================================================================
test_init_success_output() {
    log_test "test_init_success_output" \
             "Verify init success output format matches spec"

    # Run
    set +e
    output=$($GUARD_BIN init 0640 $USER staff 2>&1)
    local exit_code=$?
    set -e

    # Assert exit code
    assert_exit_code $exit_code 0 "Should succeed"

    # Check for spec format: "Initialized .guardfile with:"
    if echo "$output" | grep -q "Initialized .guardfile with:"; then
        echo -e "${GREEN}✓ PASS${NC}: Output contains 'Initialized .guardfile with:'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output missing 'Initialized .guardfile with:'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for Mode line
    if echo "$output" | grep -q "Mode:"; then
        echo -e "${GREEN}✓ PASS${NC}: Output contains 'Mode:'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output missing 'Mode:'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for Owner line
    if echo "$output" | grep -q "Owner:"; then
        echo -e "${GREEN}✓ PASS${NC}: Output contains 'Owner:'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output missing 'Owner:'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for Group line
    if echo "$output" | grep -q "Group:"; then
        echo -e "${GREEN}✓ PASS${NC}: Output contains 'Group:'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output missing 'Group:'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_init_success_output
print_test_summary 1
