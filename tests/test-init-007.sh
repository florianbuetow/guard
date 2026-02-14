#!/bin/bash

# test-init-007.sh - Test 7: Init when .guardfile already exists (Negative)
# Tests initialization of the guard system with various parameters

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# Test 7: Init when .guardfile already exists (Negative)
# ============================================================================
test_init_already_exists() {
    log_test "test_init_already_exists" \
             "Negative test: guard init when .guardfile already exists"

    # Create a .guardfile first
    $GUARD_BIN init 644 flo staff

    # Try to init again (should fail immediately before prompting)
    set +e
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)" > /dev/null 2>&1
    local exit_code=$?
    set -e

    # Assert exit code 1 (error)
    assert_exit_code $exit_code 1 "guard init should fail when .guardfile exists"

    # Assert .guardfile still exists
    assert_guardfile_exists ".guardfile should still exist"
}

# Run test
run_test test_init_already_exists
print_test_summary 1
