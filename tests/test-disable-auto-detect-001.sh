#!/bin/bash

# test-disable-auto-detect-001.sh - DISABLE AUTO-DETECTION TESTS - FILE ONLY
# Tests auto-detection of files vs collections: guard disable <arg>...
# Without explicit 'file' or 'collection' keyword

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
set -e

# Find guard binary
find_guard_binary

# ============================================================================
# DISABLE AUTO-DETECTION TESTS - FILE ONLY
# ============================================================================
test_disable_auto_detect_single_file() {
    log_test "test_disable_auto_detect_single_file" \
             "Auto-detect: disable single file when only file exists"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch myfile.txt
    $GUARD_BIN add file myfile.txt
    $GUARD_BIN enable file myfile.txt

    # Verify initial state
    local initial_flag=$(get_guard_flag "$(pwd)/myfile.txt")
    assert_equals "true" "$initial_flag" "File should start guarded"

    # Run disable without 'file' keyword
    $GUARD_BIN disable myfile.txt
    local exit_code=$?

    # Assert
    assert_exit_code $exit_code 0 "guard disable should succeed"

    local disabled_flag=$(get_guard_flag "$(pwd)/myfile.txt")
    assert_equals "false" "$disabled_flag" "File should be unguarded after disable"
}

# Run test
run_test test_disable_auto_detect_single_file
print_test_summary 1
