#!/bin/bash

# test-tui-search-008.sh - FUZZY SEARCH: Re-activate search after dismiss
# Tests that pressing '/' again after Escape re-opens the search box.
#
# Prerequisites:
# - tmux must be installed
# - guard binary must be built

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

# Check for tmux (required for TUI tests)
if ! tui_check_tmux; then
    exit 1
fi

# ============================================================================
# TEST: Re-activate search with '/' after Escape dismisses it
# ============================================================================
test_search_reactivate_after_escape() {
    log_test "test_search_reactivate_after_escape" \
             "Pressing '/' after Escape re-opens the search box with empty query"

    # Setup: Initialize guard and create files
    $GUARD_BIN init 000 flo staff
    touch apple.txt banana.txt
    $GUARD_BIN add apple.txt banana.txt

    # Launch TUI
    tui_start

    # Action: Activate search, type something unique, dismiss with Escape
    tui_send_keys "/"
    tui_assert_contains "Search:" "Search box visible on first activation"
    tui_type "xyzquery"
    tui_assert_contains "xyzquery" "Typed query visible in search box"
    tui_send_keys "Escape"

    # Assert: Search box is gone after Escape
    tui_assert_not_contains "Search:" "Search box hidden after Escape"

    # Assert: TUI is still running (Escape in search didn't quit)
    tui_assert_running "TUI still running after Escape from search"

    # Action: Press '/' again to re-activate
    tui_send_keys "/"

    # Assert: Search box is visible again
    tui_assert_contains "Search:" "Search box visible on re-activation"

    # Assert: Previous query is cleared (Escape cleared it)
    tui_assert_not_contains "xyzquery" "Previous query cleared after Escape"

    # Cleanup
    tui_stop
}

# Run test
run_test test_search_reactivate_after_escape
print_test_summary 1
