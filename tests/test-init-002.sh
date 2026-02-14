#!/bin/bash

# test-init-002.sh - Test 2: Init without arguments (Negative)
# Tests initialization of the guard system with various parameters

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# Test 2: Init without arguments (Negative)
# ============================================================================
test_init_no_args() {
    log_test "test_init_no_args" \
             "Negative test: guard init without arguments should fail"

    # Run guard init without args (should fail)
    set +e
    $GUARD_BIN init > /dev/null 2>&1
    local exit_code=$?
    set -e

    # Assert exit code 1
    assert_exit_code $exit_code 1 "guard init without args should fail"

    # Assert .guardfile not created
    assert_guardfile_not_exists ".guardfile should not be created"
}

# Run test
run_test test_init_no_args
print_test_summary 1
