#!/bin/bash

# test-toggle-auto-detect-005.sh - TOGGLE AUTO-DETECTION TESTS - NOT FOUND
# Tests auto-detection of files vs collections: guard toggle <arg>...
# Without explicit 'file' or 'collection' keyword

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# TOGGLE AUTO-DETECTION TESTS - NOT FOUND
# ============================================================================
test_toggle_auto_detect_not_found() {
    log_test "test_toggle_auto_detect_not_found" \
             "Error when neither file nor collection exists"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"

    # Run toggle on non-existent target
    set +e
    output=$($GUARD_BIN toggle nonexistent 2>&1)
    local exit_code=$?
    set -e

    # Assert: Should fail with not found error
    assert_exit_code $exit_code 1 "guard toggle should fail for non-existent target"

    # Check for not found error message
    if [[ "$output" == *"not found"* ]] || [[ "$output" == *"not exist"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Not found error message displayed"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Not found error message not found"
        echo "Got: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run test
run_test test_toggle_auto_detect_not_found
print_test_summary 1
