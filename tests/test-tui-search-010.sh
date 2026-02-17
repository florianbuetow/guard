#!/bin/bash

# test-tui-search-010.sh - FUZZY SEARCH: Enter does not hide the search box
# Tests that pressing Enter does not deactivate the search box and keeps the prompt visible.
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
# TEST: Enter keeps search box active
# ============================================================================
test_search_enter_keeps_prompt() {
    log_test "test_search_enter_keeps_prompt" \
             "Enter keeps the search box active and retains the Search: prompt"

    # Setup: Initialize guard and create files
    $GUARD_BIN init 000 flo staff
    touch apple.txt banana.txt
    $GUARD_BIN add apple.txt banana.txt

    # Launch TUI
    tui_start

    # Action: Activate search and type a query
    tui_send_keys "/"
    tui_assert_contains "Search:" "Search box visible after activation"
    tui_type "xyztest"
    tui_assert_contains "xyztest" "Typed query visible in search box"

    # Action: Press Enter (should be a no-op)
    tui_send_keys Enter

    # Assert: Search prompt is still visible
    tui_assert_contains "Search:" "Search prompt remains visible after Enter"

    # Assert: Query is preserved and still editable
    tui_assert_contains "xyztest" "Search query preserved after Enter"
    tui_type "x"
    tui_assert_contains "xyztestx" "Search query remains editable after Enter"

    # Assert: TUI is still running
    tui_assert_running "TUI still running after Enter"

    # Cleanup
    tui_stop
}

# Run test
run_test test_search_enter_keeps_prompt
print_test_summary 1
