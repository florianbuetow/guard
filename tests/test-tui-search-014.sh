#!/bin/bash

# test-tui-search-014.sh - TAB FOCUS CYCLING: Tab cycles through search box
# Tests that Tab cycles focus through Files, Collections, and Search box.

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
# TEST: Tab cycles focus through search box when search is active
# ============================================================================
test_tab_cycles_through_search() {
    log_test "test_tab_cycles_through_search" \
             "Tab cycles focus: Files -> Collections -> Search box -> Files"

    # Setup
    $GUARD_BIN init 000 flo staff
    touch apple.txt banana.txt
    $GUARD_BIN add apple.txt banana.txt

    # Launch TUI
    tui_start

    tui_assert_running "TUI session is active"

    # Activate search
    tui_send_keys "/"
    tui_assert_contains "Search:" "Search box is active"

    # Type something to have a query
    tui_type "app"
    tui_assert_contains "app" "Search query entered"

    # Tab should cycle focus away from search box to Files panel
    tui_send_keys Tab

    # The search box should still be visible (search is still active)
    tui_assert_contains "Search:" "Search bar still visible after Tab"

    # Tab again should go to Collections panel
    tui_send_keys Tab

    tui_assert_running "TUI still running after second Tab"

    # Tab again should return focus to Search box
    tui_send_keys Tab

    # When search box has focus, typing should go to the search input
    tui_type "le"
    tui_assert_contains "apple" "Typing goes to search box when it has focus"

    # Cleanup
    tui_stop
}

# Run test
run_test test_tab_cycles_through_search
print_test_summary 1
