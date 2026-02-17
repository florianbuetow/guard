#!/bin/bash

# test-tui-search-002.sh - FUZZY SEARCH: Real-time filtering
# Tests that typing in the search box filters the file tree in real time.
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
# TEST: Typing filters file tree in real time
# ============================================================================
test_search_filtering() {
    log_test "test_search_filtering" \
             "Typing in search box filters the file tree to matching entries"

    # Setup: Initialize guard and create flat files with distinct names
    $GUARD_BIN init 000 flo staff
    touch apple.txt banana.txt cherry.txt
    $GUARD_BIN add apple.txt banana.txt cherry.txt

    # Launch TUI
    tui_start

    # Assert: All files are visible initially
    tui_assert_contains "apple.txt" "apple.txt visible before search"
    tui_assert_contains "banana.txt" "banana.txt visible before search"
    tui_assert_contains "cherry.txt" "cherry.txt visible before search"

    # Action: Activate search and type a filter
    tui_send_keys "/"
    tui_type "apple"

    # Assert: Matching file is visible
    tui_assert_contains "apple.txt" "apple.txt visible after filtering for 'apple'"

    # Assert: Non-matching files are hidden
    tui_assert_not_contains "banana.txt" "banana.txt hidden after filtering for 'apple'"
    tui_assert_not_contains "cherry.txt" "cherry.txt hidden after filtering for 'apple'"

    # Cleanup
    tui_stop
}

# Run test
run_test test_search_filtering
print_test_summary 1
