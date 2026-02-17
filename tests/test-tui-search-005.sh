#!/bin/bash

# test-tui-search-005.sh - FUZZY SEARCH: No matches warning
# Tests that a warning message is shown when no files match the search query.
# TDD: This test should FAIL until the search feature is implemented.
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
# TEST: No matches shows warning message
# ============================================================================
test_search_no_matches() {
    log_test "test_search_no_matches" \
             "Warning message shown when no files match the search query"

    # Setup: Initialize guard and create flat files
    $GUARD_BIN init 000 flo staff
    touch apple.txt banana.txt
    $GUARD_BIN add apple.txt banana.txt

    # Launch TUI
    tui_start

    # Action: Activate search and type a query that matches nothing
    tui_send_keys "/"
    tui_type "xyznonexistent"

    # Assert: Warning message is shown
    tui_assert_contains "No matches" "No matches warning is displayed"

    # Assert: Original files are not shown
    tui_assert_not_contains "apple.txt" "apple.txt hidden when no matches"
    tui_assert_not_contains "banana.txt" "banana.txt hidden when no matches"

    # Assert: TUI is still running
    tui_assert_running "TUI still running with no matches"

    # Cleanup
    tui_stop
}

# Run test
run_test test_search_no_matches
print_test_summary 1
