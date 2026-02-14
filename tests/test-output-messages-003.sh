#!/bin/bash

# test-output-messages-003.sh - DISABLE COLLECTION OUTPUT TESTS (Issue 4)
# Tests enable/disable/uninstall operation messages

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e


# Find guard binary
find_guard_binary

# ============================================================================
# DISABLE COLLECTION OUTPUT TESTS (Issue 4)
# ============================================================================
test_output_disable_single_collection() {
    log_test "test_output_disable_single_collection" \
             "Verify output shows 'Guard disabled for collection' and each file"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch alice1.txt alice2.txt shared.txt
    # OLD: $GUARD_BIN add file alice1.txt alice2.txt shared.txt to alice > /dev/null 2>&1
    # NEW:
    $GUARD_BIN create alice
    $GUARD_BIN update alice add alice1.txt alice2.txt shared.txt
    # Enable guard first so we can disable it
    $GUARD_BIN enable collection alice > /dev/null 2>&1

    # Run
    set +e
    output=$($GUARD_BIN disable collection alice 2>&1)
    local exit_code=$?
    set -e

    # Assert exit code
    assert_exit_code $exit_code 0 "Should succeed"

    # Check for "Guard disabled for collection alice" message
    if echo "$output" | grep -q "Guard disabled for collection alice"; then
        echo -e "${GREEN}✓ PASS${NC}: Output contains 'Guard disabled for collection alice'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output missing 'Guard disabled for collection alice'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for "Guard disabled for alice1.txt" message
    if echo "$output" | grep -q "Guard disabled for .*alice1.txt"; then
        echo -e "${GREEN}✓ PASS${NC}: Output contains 'Guard disabled for alice1.txt'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output missing 'Guard disabled for alice1.txt'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for "Guard disabled for alice2.txt" message
    if echo "$output" | grep -q "Guard disabled for .*alice2.txt"; then
        echo -e "${GREEN}✓ PASS${NC}: Output contains 'Guard disabled for alice2.txt'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output missing 'Guard disabled for alice2.txt'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Check for "Guard disabled for shared.txt" message
    if echo "$output" | grep -q "Guard disabled for .*shared.txt"; then
        echo -e "${GREEN}✓ PASS${NC}: Output contains 'Guard disabled for shared.txt'"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Output missing 'Guard disabled for shared.txt'"
        echo "Actual output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_output_disable_single_collection
print_test_summary 1
