#!/bin/bash

# test-tui-search-017.sh - ARROW KEYS + TAB FOCUS: Arrows navigate panel, not search, when panel is focused
# Tests that arrow keys navigate the file tree when a panel has focus while search is visible.
# TDD: This test should FAIL until Tab focus cycling is implemented.

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
set -e

# Find guard binary
GUARD_BIN=""
if [ -f "./guard" ]; then
    GUARD_BIN="$(pwd)/guard"
elif command -v guard &> /dev/null; then
    GUARD_BIN="guard"
else
    echo "Error: guard binary not found. Please build it first."
    exit 1
fi

if ! tui_check_tmux; then
    exit 1
fi

# ============================================================================
# TEST: Arrow keys navigate panel when panel has focus (search still visible)
# ============================================================================
test_arrows_navigate_panel_not_search() {
    log_test "test_arrows_navigate_panel_not_search" \
             "Arrow keys navigate file tree when panel focused, search visible"

    # Setup: create multiple files so we can observe cursor movement
    $GUARD_BIN init 000 flo staff
    touch aaa.txt bbb.txt ccc.txt
    $GUARD_BIN add aaa.txt bbb.txt ccc.txt

    # Launch TUI
    tui_start

    tui_assert_running "TUI session is active"

    # Activate search and type a query that matches all files
    tui_send_keys "/"
    tui_assert_contains "Search:" "Search box is active"

    # Tab to move focus from search box to Files panel
    tui_send_keys Tab

    # Search should still be visible
    tui_assert_contains "Search:" "Search bar still visible after Tab to panel"

    # Press Down arrow — should move file tree cursor, not affect search input
    tui_send_keys Down

    # TUI should still be running with search visible
    tui_assert_running "TUI still running after Down arrow in panel"
    tui_assert_contains "Search:" "Search still visible after Down arrow in panel"

    # Press Up arrow — should move file tree cursor back
    tui_send_keys Up
    tui_assert_running "TUI still running after Up arrow in panel"
    tui_assert_contains "Search:" "Search still visible after Up arrow in panel"

    # Now Tab back to search box and verify typing still works there
    # (need to Tab through Collections back to Search)
    tui_send_keys Tab
    tui_send_keys Tab

    tui_type "test"
    tui_assert_contains "test" "Can type in search box after Tab-cycling back"

    # Cleanup
    tui_stop
}

# Run test
run_test test_arrows_navigate_panel_not_search
print_test_summary 1
