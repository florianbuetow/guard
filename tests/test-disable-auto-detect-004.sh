#!/bin/bash

# test-disable-auto-detect-004.sh - DISABLE AUTO-DETECTION TESTS - AMBIGUOUS
# Tests auto-detection of files vs collections: guard disable <arg>...
# Without explicit 'file' or 'collection' keyword

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# DISABLE AUTO-DETECTION TESTS - AMBIGUOUS
# ============================================================================
test_disable_auto_detect_ambiguous() {
    log_test "test_disable_auto_detect_ambiguous" \
             "File on disk takes priority over collection with same name"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch foo
    $GUARD_BIN add file foo
    $GUARD_BIN enable file foo
    $GUARD_BIN create foo  # Same name as file

    # Run disable - should succeed, treating 'foo' as file (priority over collection)
    set +e
    output=$($GUARD_BIN disable foo 2>&1)
    local exit_code=$?
    set -e

    # Assert: Should succeed (file takes priority)
    assert_exit_code $exit_code 0 "guard disable should succeed (file takes priority)"

    # Check that the file was disabled
    local guard=$(get_guard_flag "foo")
    assert_equals "false" "$guard" "File 'foo' should be unguarded"
}

# Run test
run_test test_disable_auto_detect_ambiguous
print_test_summary 1
