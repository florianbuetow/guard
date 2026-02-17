#!/bin/bash

# test-tui-search-004.sh - FUZZY SEARCH: Enter keeps filter active
# Tests that the filter remains applied after pressing Enter.
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
# TEST: Enter deactivates search but keeps filter
# ============================================================================
test_search_enter_keeps_filter() {
    log_test "test_search_enter_keeps_filter" \
             "Filter remains applied after pressing Enter"

    # Setup: Initialize guard and create flat files
    $GUARD_BIN init 000 flo staff
    touch apple.txt banana.txt cherry.txt
    $GUARD_BIN add apple.txt banana.txt cherry.txt

    # Launch TUI
    tui_start

    # Action: Activate search, type filter, press Enter
    tui_send_keys "/"
    tui_type "apple"

    # Verify filter is active
    tui_assert_contains "apple.txt" "apple.txt visible while searching"
    tui_assert_not_contains "banana.txt" "banana.txt hidden while searching"

    # Action: Press Enter to confirm filter and return to file tree
    tui_send_keys "Enter"

    # Assert: Filter is still applied (non-matching files still hidden)
    tui_assert_contains "apple.txt" "apple.txt still visible after Enter"
    tui_assert_not_contains "banana.txt" "banana.txt still hidden after Enter"

    # Assert: TUI is still running
    tui_assert_running "TUI still running after Enter"

    # Cleanup
    tui_stop
}

# Run test
run_test test_search_enter_keeps_filter
print_test_summary 1
