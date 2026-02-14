#!/bin/bash

# test-edge-cases-001.sh - ERROR HANDLING TESTS
# Tests special scenarios, error conditions, and system limits

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e


# Find guard binary
find_guard_binary

# ============================================================================
# ERROR HANDLING TESTS
# ============================================================================
test_guardfile_missing() {
    log_test "test_guardfile_missing" \
             "Error when .guardfile doesn't exist"

    # Setup: No .guardfile

    # Run (should fail)
    set +e
    output=$($GUARD_BIN show file 2>&1)
    local exit_code=$?
    set -e

    # Assert: Exit code 1, error message
    assert_exit_code $exit_code 1 "Should fail with exit code 1"

    # Check for error message
    if [[ "$output" == *"error"* ]] || [[ "$output" == *"Error"* ]] || [[ "$output" == *"not found"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Error message displayed"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${YELLOW}Note${NC}: Error message not detected"
        echo "Output: $output"
    fi
}

# Run test
run_test test_guardfile_missing
print_test_summary 1
