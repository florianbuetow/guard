#!/bin/bash

# test-tui-milestone-1-006.sh - CATEGORY 6: COLLECTIONS PANEL GUARD TOGGLE TESTS
# Tests the Text User Interface according to TUI-INTERFACE-SPECS-MILESTONE-1.md
#
# Prerequisites:
# - tmux must be installed (tests will fail if not available)
# - guard binary must be built
#
# Usage:
#   ./tests/test-tui-milestone-1.sh

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
set -e

# Find guard binary
find_guard_binary

# Check for tmux (required for TUI tests)
if ! tui_check_tmux; then
    exit 1
fi

# ============================================================================
# CATEGORY 6: COLLECTIONS PANEL GUARD TOGGLE TESTS
# ============================================================================
test_collection_toggle_on() {
    log_test "test_collection_toggle_on" \
             "Toggle collection guard state to on"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt
    chmod 644 file1.txt  # Set explicit initial permissions
    $GUARD_BIN create mycoll
    $GUARD_BIN update mycoll add file1.txt

    # Verify initial state
    local initial_flag=$(get_collection_guard_flag "mycoll")
    tui_assert_equals "false" "$initial_flag" "Collection starts unguarded"

    # Verify initial file permissions
    assert_file_permissions "$(pwd)/file1.txt" "644" "file1.txt starts with 644"

    # Launch TUI
    tui_start

    # Switch to collections and toggle
    tui_send_keys "Tab"
    tui_send_keys "Space"
    sleep 0.3

    # Stop TUI
    tui_stop

    # Assert: Collection should be guarded
    local guard_flag=$(get_collection_guard_flag "mycoll")
    tui_assert_equals "true" "$guard_flag" "Collection should be guarded after toggle"

    # Verify file permissions changed to 000 when collection guarded
    assert_file_permissions "$(pwd)/file1.txt" "000" "file1.txt should be 000 when collection guarded"
}

# Run test
tui_run_test test_collection_toggle_on
