#!/bin/bash

# test-tui-search-015.sh - ENTER NO-OP: Enter does nothing in search box
# Tests that pressing Enter in the search box does NOT deactivate it.
# TDD: This test should FAIL until Enter behavior is removed.

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
# TEST: Enter does not deactivate search box
# ============================================================================
test_enter_does_nothing_in_search() {
    log_test "test_enter_does_nothing_in_search" \
             "Pressing Enter in the search box does NOT deactivate it"

    # Setup
    $GUARD_BIN init 000 flo staff
    touch apple.txt banana.txt cherry.txt
    $GUARD_BIN add apple.txt banana.txt cherry.txt

    # Launch TUI
    tui_start

    tui_assert_running "TUI session is active"

    # Activate search
    tui_send_keys "/"
    tui_assert_contains "Search:" "Search box is active"

    # Type a query
    tui_type "apple"
    tui_assert_contains "apple" "Search query shows apple"

    # Press Enter
    tui_send_keys Enter

    # Assert: Search box is STILL active (prompt still visible)
    tui_assert_contains "Search:" "Search box still active after Enter"

    # Assert: Can still type in the search box (it's still receiving input)
    tui_type "x"
    tui_assert_contains "applex" "Can still type after pressing Enter"

    # Cleanup
    tui_stop
}

# Run test
run_test test_enter_does_nothing_in_search
print_test_summary 1
