#!/bin/bash

# test-error-messages-001.sh - ERROR MESSAGE FORMAT TESTS
# Verifies that error/warning messages match the formats specified in CLI-INTERFACE-SPECS.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# ERROR MESSAGE FORMAT TESTS
# ============================================================================
test_error_not_found() {
    log_test "test_error_not_found" \
             "Error message format: 'not found' for non-existent target"

    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"

    set +e
    output=$($GUARD_BIN toggle nonexistent 2>&1)
    local exit_code=$?
    set -e

    assert_exit_code $exit_code 1 "Toggle should fail for non-existent target"
    assert_contains "$output" "not found" "Error should contain 'not found'"
}

# Run test
run_test test_error_not_found
print_test_summary 1
