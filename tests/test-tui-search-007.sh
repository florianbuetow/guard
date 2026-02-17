#!/bin/bash

# test-tui-search-007.sh - FUZZY SEARCH: Keys suppressed while search active
# Tests that q/esc are routed to the search box (not quit) when search is active.
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
# TEST: Typing 'q' in search box types 'q' instead of quitting
# ============================================================================
test_search_suppresses_quit() {
    log_test "test_search_suppresses_quit" \
             "Typing 'q' in search box types the character instead of quitting the TUI"

    # Setup: Initialize guard and create a file
    $GUARD_BIN init 000 flo staff
    touch query.txt
    $GUARD_BIN add query.txt

    # Launch TUI
    tui_start

    # Assert: TUI is running
    tui_assert_running "TUI session is active"

    # Action: Press '/' to activate search, then type 'q'
    tui_send_keys "/"
    tui_type "q"

    # Assert: TUI is still running (q did not quit)
    tui_assert_running "TUI still running after typing 'q' in search"

    # Assert: Search box shows the typed 'q'
    tui_assert_contains "Search:" "Search box is still visible"

    # Cleanup
    tui_stop
}

# Run test
run_test test_search_suppresses_quit
print_test_summary 1
