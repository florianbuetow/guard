#!/bin/bash

# test-tui-search-003.sh - FUZZY SEARCH: Escape clears and restores
# Tests that Escape clears the search query and restores the full file tree.
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
# TEST: Escape clears search and restores full tree
# ============================================================================
test_search_escape_clears() {
    log_test "test_search_escape_clears" \
             "Escape clears search query and restores the full file tree"

    # Setup: Initialize guard and create flat files
    $GUARD_BIN init 000 flo staff
    touch apple.txt banana.txt cherry.txt
    $GUARD_BIN add apple.txt banana.txt cherry.txt

    # Launch TUI
    tui_start

    # Assert: All files visible initially
    tui_assert_contains "apple.txt" "apple.txt visible before search"
    tui_assert_contains "banana.txt" "banana.txt visible before search"

    # Action: Activate search, type filter, verify it works
    tui_send_keys "/"
    tui_type "apple"
    tui_assert_not_contains "banana.txt" "banana.txt hidden while filter active"

    # Action: Press Escape to clear search
    tui_send_keys "Escape"

    # Assert: Full tree is restored - all files visible again
    tui_assert_contains "apple.txt" "apple.txt visible after Escape"
    tui_assert_contains "banana.txt" "banana.txt restored after Escape"
    tui_assert_contains "cherry.txt" "cherry.txt restored after Escape"

    # Assert: Search prompt is gone
    tui_assert_not_contains "Search:" "Search prompt removed after Escape"

    # Assert: TUI is still running (Escape didn't quit)
    tui_assert_running "TUI still running after Escape from search"

    # Cleanup
    tui_stop
}

# Run test
run_test test_search_escape_clears
print_test_summary 1
