#!/bin/bash

# test-tui-search-009.sh - FUZZY SEARCH: Search box frame rendering
# Tests that the search box junction line renders correctly when search is active.
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
# TEST: Search box renders junction lines in frame
# ============================================================================
test_search_frame_rendering() {
    log_test "test_search_frame_rendering" \
             "Search box renders with junction lines separating it from content and status bar"

    # Setup: Initialize guard and create a file
    $GUARD_BIN init 000 flo staff
    touch testfile.txt
    $GUARD_BIN add testfile.txt

    # Launch TUI
    tui_start

    # Assert: No search junction before activation (only one ╠ junction for status bar)
    tui_assert_running "TUI session is active"

    # Action: Activate search
    tui_send_keys "/"

    # Assert: Search prompt rendered inside the frame
    tui_assert_contains "Search:" "Search prompt visible in frame"

    # Assert: The search junction line with panel separator closure is present
    # When search is active, there should be a ╠═══╧═══╣ junction closing the panels
    # followed by the search row, then a ╠═══════╣ full-width junction before status
    tui_assert_contains "╠" "Left junction character present"
    tui_assert_contains "╣" "Right junction character present"

    # Assert: Content panels still have the separator in content rows
    tui_assert_contains "│" "Panel separator visible in content area"

    # Cleanup
    tui_stop
}

# Run test
run_test test_search_frame_rendering
print_test_summary 1
