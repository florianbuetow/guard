#!/bin/bash

# test-tui-search-001.sh - FUZZY SEARCH: Activation
# Tests that pressing '/' activates the search box in the TUI.
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
# TEST: '/' activates search box
# ============================================================================
test_search_activation() {
    log_test "test_search_activation" \
             "Pressing '/' activates the search box with a visible prompt"

    # Setup: Initialize guard and create flat files (no subdirectories)
    $GUARD_BIN init 000 flo staff
    touch apple.txt banana.txt cherry.txt
    $GUARD_BIN add apple.txt banana.txt cherry.txt

    # Launch TUI
    tui_start

    # Assert: TUI is running and shows files
    tui_assert_running "TUI session is active"
    tui_assert_contains "apple.txt" "File tree shows apple.txt"

    # Action: Press '/' to activate search
    tui_send_keys "/"

    # Assert: Search box prompt is visible
    tui_assert_contains "Search:" "Search box prompt is visible after pressing '/'"

    # Assert: TUI is still running (didn't quit)
    tui_assert_running "TUI still running after activating search"

    # Cleanup
    tui_stop
}

# Run test
run_test test_search_activation
print_test_summary 1
