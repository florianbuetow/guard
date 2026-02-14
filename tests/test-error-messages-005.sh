#!/bin/bash

# test-error-messages-005.sh - PersistentPreRunE centralized error formatting tests
# Verifies that the centralized error path in main.go produces correct output

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# PersistentPreRunE ERROR FORMAT TESTS
# ============================================================================

test_missing_guardfile_error_prefix() {
    log_test "test_missing_guardfile_error_prefix" \
             "Registry-dependent command without .guardfile shows 'Error:' prefix"

    # Do NOT run guard init — no .guardfile should exist

    set +e
    stderr_output=$($GUARD_BIN show 2>&1 1>/dev/null)
    combined_output=$($GUARD_BIN show 2>&1)
    local exit_code=$?
    set -e

    assert_exit_code $exit_code 1 "Should fail with exit code 1 when .guardfile missing"
    assert_contains "$combined_output" "Error:" "Error output should have 'Error:' prefix"
}

test_error_goes_to_stderr() {
    log_test "test_error_goes_to_stderr" \
             "Error output goes to stderr, not stdout"

    # No .guardfile

    set +e
    stdout_only=$($GUARD_BIN show 2>/dev/null)
    stderr_only=$($GUARD_BIN show 2>&1 1>/dev/null)
    set -e

    if [ -z "$stdout_only" ]; then
        echo -e "${GREEN}✓ PASS${NC}: No error output on stdout"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: Error output appeared on stdout: $stdout_only"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    assert_contains "$stderr_only" "Error:" "Error should appear on stderr"
}

test_unknown_command_error() {
    log_test "test_unknown_command_error" \
             "Unknown command surfaces Cobra error properly"

    set +e
    output=$($GUARD_BIN notarealcommand 2>&1)
    local exit_code=$?
    set -e

    assert_exit_code $exit_code 1 "Unknown command should fail with exit code 1"
    assert_contains "$output" "unknown command" "Should contain 'unknown command'"
}

# Run tests
run_test test_missing_guardfile_error_prefix
run_test test_error_goes_to_stderr
run_test test_unknown_command_error
print_test_summary 3
