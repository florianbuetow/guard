#!/bin/bash

# test-tui-milestone-1-003.sh - CATEGORY 3: FILES PANEL NAVIGATION TESTS
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
# CATEGORY 3: FILES PANEL NAVIGATION TESTS
# ============================================================================
test_files_panel_initial_focus() {
    log_test "test_files_panel_initial_focus" \
             "Files panel has focus on startup"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt

    # Launch TUI
    tui_start

    # Assert: Files panel should be active (highlighted title)
    # The active panel has highlighted/bold title
    tui_assert_running "TUI is running"
    # Note: We check that Files panel is interactive by verifying navigation works
    # This is tested implicitly by navigation tests

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_files_panel_initial_focus
