#!/bin/bash

# test-tui-search-006.sh - FUZZY SEARCH: Filter persists across panel switches
# Tests that the search filter persists when switching to collections and back.
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
# TEST: Search filter persists across panel switches
# ============================================================================
test_search_persists_across_panels() {
    log_test "test_search_persists_across_panels" \
             "Search filter remains active after switching panels with Tab"

    # Setup: Initialize guard and create flat files + a collection
    $GUARD_BIN init 000 flo staff
    touch apple.txt banana.txt cherry.txt
    $GUARD_BIN add apple.txt banana.txt cherry.txt
    $GUARD_BIN create mygroup
    $GUARD_BIN update mygroup add apple.txt

    # Launch TUI
    tui_start

    # Action: Activate search, type filter, press Enter to confirm
    tui_send_keys "/"
    tui_type "apple"
    tui_send_keys "Enter"

    # Verify filter is active
    tui_assert_contains "apple.txt" "apple.txt visible with filter"
    tui_assert_not_contains "banana.txt" "banana.txt hidden with filter"

    # Action: Tab to collections panel
    tui_send_keys "Tab"

    # Action: Tab back to files panel
    tui_send_keys "Tab"

    # Assert: Filter is still active after round-trip
    tui_assert_contains "apple.txt" "apple.txt still visible after panel switch"
    tui_assert_not_contains "banana.txt" "banana.txt still hidden after panel switch"

    # Cleanup
    tui_stop
}

# Run test
run_test test_search_persists_across_panels
print_test_summary 1
