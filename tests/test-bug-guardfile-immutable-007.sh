#!/bin/bash

# test-bug-guardfile-immutable-007.sh - Verify enable/disable uses SaveRegistry
#
# This file tests that enable/disable commands correctly use SaveRegistry(),
# which includes clearGuardfileImmutableFlag(). This is the correct pattern
# that config commands should follow.

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# FUNCTIONAL TEST: Verify SaveRegistry path works correctly
# ============================================================================

test_enable_disable_uses_save_registry() {
    log_test "test_enable_disable_uses_save_registry" \
             "Verify: enable/disable commands use SaveRegistry (correct path)"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch testfile.txt
    $GUARD_BIN add testfile.txt

    # Enable guard (should use SaveRegistry which calls clearGuardfileImmutableFlag)
    local output
    output=$($GUARD_BIN enable testfile.txt 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "Enable command should succeed"

    # Verify the guard flag was set
    local guard_flag=$(get_guard_flag "testfile.txt")
    assert_equals "true" "$guard_flag" "File should be guarded after enable"

    # Disable guard
    output=$($GUARD_BIN disable testfile.txt 2>&1)
    exit_code=$?

    assert_exit_code "$exit_code" 0 "Disable command should succeed"

    # Verify the guard flag was cleared
    guard_flag=$(get_guard_flag "testfile.txt")
    assert_equals "false" "$guard_flag" "File should not be guarded after disable"

    echo ""
    echo "  NOTE: enable/disable commands correctly use SaveRegistry(),"
    echo "  which includes clearGuardfileImmutableFlag(). This is the"
    echo "  correct pattern that config commands should follow."
}

# Run test
run_test test_enable_disable_uses_save_registry
print_test_summary 1
