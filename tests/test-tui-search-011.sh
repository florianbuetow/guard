#!/bin/bash

# test-tui-search-011.sh - FUZZY SEARCH: '/' keeps query after Enter no-op
# Tests that pressing '/' after Enter keeps the active search box and preserved query.
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
# TEST: '/' after Enter keeps active search and preserves query
# ============================================================================
test_search_slash_after_enter_preserves_query() {
    log_test "test_search_slash_after_enter_preserves_query" \
             "Pressing '/' after Enter keeps search active with the previous query preserved"

    # Setup: Initialize guard and create files
    $GUARD_BIN init 000 flo staff
    touch apple.txt banana.txt
    $GUARD_BIN add apple.txt banana.txt

    # Launch TUI
    tui_start

    # Action: Activate search, type a unique query, press Enter (no-op)
    tui_send_keys "/"
    tui_type "xyzquery"
    tui_assert_contains "xyzquery" "Typed query visible in search box"
    tui_send_keys Enter

    # Assert: Search box remains visible after Enter
    tui_assert_contains "Search:" "Search box still visible after Enter"

    # Action: Press '/' again
    tui_send_keys "/"

    # Assert: Search is still visible with previous query preserved
    tui_assert_contains "Search:" "Search box remains visible after pressing '/' again"
    tui_assert_contains "xyzquery" "Previous query preserved after pressing '/' again"

    # Cleanup
    tui_stop
}

# Run test
run_test test_search_slash_after_enter_preserves_query
print_test_summary 1
