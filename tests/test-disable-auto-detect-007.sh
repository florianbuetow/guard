#!/bin/bash

# test-disable-auto-detect-007.sh - DISABLE AUTO-DETECTION TESTS - OUTPUT VERIFICATION
# Tests auto-detection of files vs collections: guard disable <arg>...
# Without explicit 'file' or 'collection' keyword

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# DISABLE AUTO-DETECTION TESTS - OUTPUT VERIFICATION
# ============================================================================
test_disable_nonexistent_has_output_autodetect() {
    log_test "test_disable_nonexistent_has_output_autodetect" \
             "Verify informative output when disabling non-existent target (auto-detect)"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    # nonexistent doesn't exist on disk or in registry

    # Run disable on non-existent target
    set +e
    output=$($GUARD_BIN disable nonexistent 2>&1)
    local exit_code=$?
    set -e

    # Assert: Output should NOT be empty
    if [[ -z "$output" ]]; then
        echo -e "${RED}✗ FAIL${NC}: Output is empty - user gets no feedback"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        echo -e "${GREEN}✓ PASS${NC}: Informative output provided"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi

    # Assert: Should have exit code 1
    assert_exit_code $exit_code 1 "Should fail for non-existent target"
}

# Run test
run_test test_disable_nonexistent_has_output_autodetect
print_test_summary 1
