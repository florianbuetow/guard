#!/bin/bash

# test-tui-search-016.sh - ARROW KEYS: Arrow keys work in search box
# Tests that arrow keys move cursor in search box and don't leak to file tree.
# TDD: This test should verify arrow key behavior in the search box.

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
# TEST: Arrow keys work within search box
# ============================================================================
test_arrow_keys_in_search() {
    log_test "test_arrow_keys_in_search" \
             "Arrow keys move cursor in search box, not in file tree"

    # Setup
    $GUARD_BIN init 000 flo staff
    touch alpha.txt beta.txt gamma.txt
    $GUARD_BIN add alpha.txt beta.txt gamma.txt

    # Launch TUI
    tui_start

    tui_assert_running "TUI session is active"

    # Activate search
    tui_send_keys "/"
    tui_assert_contains "Search:" "Search box is active"

    # Type "abc"
    tui_type "abc"
    tui_assert_contains "abc" "Query shows abc"

    # Press Left arrow to move cursor left, then type "X"
    # If arrow keys work in search box, result should be "abXc"
    # If arrow keys leak to file tree, cursor stays at end and result would be "abcX"
    tui_send_keys Left
    tui_type "X"

    # The search input should show "abXc" (X inserted before c)
    tui_assert_contains "abXc" "Left arrow moved cursor, X inserted before c"

    # Press Up arrow - should NOT navigate file tree (cursor stays in search)
    tui_send_keys Up
    tui_assert_contains "Search:" "Search box still active after Up arrow"
    tui_assert_running "TUI still running after Up arrow"

    # Press Down arrow - should NOT navigate file tree
    tui_send_keys Down
    tui_assert_contains "Search:" "Search box still active after Down arrow"
    tui_assert_running "TUI still running after Down arrow"

    # Cleanup
    tui_stop
}

# Run test
run_test test_arrow_keys_in_search
print_test_summary 1
