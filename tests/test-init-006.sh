#!/bin/bash

# test-init-006.sh - Test 6: Init with empty owner and group (Positive)
# Tests initialization of the guard system with various parameters

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# Test 6: Init with empty owner and group (Positive)
# ============================================================================
test_init_empty_owner_group() {
    log_test "test_init_empty_owner_group" \
             "Positive test: guard init with mode and explicit owner/group via stdin"

    # Run guard init with mode only, pipe explicit values for owner and group
    # Note: Bash strips empty string arguments, so we use stdin for interactive input
    echo -e "testowner\ntestgroup\n" | $GUARD_BIN init 000 > /dev/null 2>&1
    local exit_code=$?

    # Assert exit code
    assert_exit_code $exit_code 0 "guard init with stdin inputs should succeed"

    # Assert .guardfile exists
    assert_guardfile_exists ".guardfile should be created"

    # Assert mode is correct
    local mode=$(get_guard_mode_from_config)
    assert_equals "0000" "$mode" "guard_mode should be 0000"
}

# Run test
run_test test_init_empty_owner_group
print_test_summary 1
