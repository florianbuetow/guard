#!/bin/bash

# test-init-005.sh - Test 5: Init with valid mode range boundaries (Positive)
# Tests initialization of the guard system with various parameters

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# Test 5: Init with valid mode range boundaries (Positive)
# ============================================================================
test_init_valid_mode_range() {
    log_test "test_init_valid_mode_range" \
             "Positive test: guard init with boundary values 000 and 777"

    # Test with mode 000
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    local exit_code1=$?
    assert_exit_code $exit_code1 0 "guard init 000 should succeed"
    assert_guardfile_exists ".guardfile should be created for mode 000"

    local mode1=$(get_guard_mode_from_config)
    assert_equals "0000" "$mode1" "guard_mode should be 0000"

    # Clean up for second test
    rm -f .guardfile

    # Test with mode 777
    $GUARD_BIN init 777 flo staff
    local exit_code2=$?
    assert_exit_code $exit_code2 0 "guard init 777 should succeed"
    assert_guardfile_exists ".guardfile should be created for mode 777"

    local mode2=$(get_guard_mode_from_config)
    assert_equals "0777" "$mode2" "guard_mode should be 0777"
}

# Run test
run_test test_init_valid_mode_range
print_test_summary 1
