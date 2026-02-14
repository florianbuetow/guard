#!/bin/bash

# test-enable-auto-detect-004.sh - ENABLE AUTO-DETECTION TESTS - FILE/COLLECTION PRIORITY
# Tests auto-detection of files vs collections: guard enable <arg>...
# Without explicit 'file' or 'collection' keyword

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# ENABLE AUTO-DETECTION TESTS - FILE/COLLECTION PRIORITY
# ============================================================================
test_enable_auto_detect_ambiguous() {
    log_test "test_enable_auto_detect_ambiguous" \
             "File on disk takes priority over collection with same name"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch foo
    $GUARD_BIN add file foo
    $GUARD_BIN create foo  # Same name as file

    # Run enable - should succeed, treating 'foo' as file (priority over collection)
    set +e
    output=$($GUARD_BIN enable foo 2>&1)
    local exit_code=$?
    set -e

    # Assert: Should succeed (file takes priority)
    assert_exit_code $exit_code 0 "guard enable should succeed (file takes priority)"

    # Check that the file was enabled
    local guard=$(get_guard_flag "foo")
    assert_equals "true" "$guard" "File 'foo' should be guarded"
}

# Run test
run_test test_enable_auto_detect_ambiguous
print_test_summary 1
