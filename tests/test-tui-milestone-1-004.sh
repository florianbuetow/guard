#!/bin/bash

# test-tui-milestone-1-004.sh - CATEGORY 4: COLLECTIONS PANEL NAVIGATION TESTS
# Tests the Text User Interface according to TUI-INTERFACE-SPECS-MILESTONE-1.md
#
# Prerequisites:
# - tmux must be installed (tests will fail if not available)
# - guard binary must be built
#
# Usage:
#   ./tests/test-tui-milestone-1.sh

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
set -e

# Find guard binary
find_guard_binary

# Check for tmux (required for TUI tests)
if ! tui_check_tmux; then
    exit 1
fi

# ============================================================================
# CATEGORY 4: COLLECTIONS PANEL NAVIGATION TESTS
# ============================================================================
test_collections_panel_switch() {
    log_test "test_collections_panel_switch" \
             "Tab switches focus to collections panel"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt
    $GUARD_BIN create mycollection
    $GUARD_BIN update mycollection add file1.txt

    # Launch TUI
    tui_start

    # Switch to collections panel
    tui_send_keys "Tab"

    # Assert: Collections panel should be active
    tui_assert_contains "mycollection" "Collection visible after tab"

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_collections_panel_switch
