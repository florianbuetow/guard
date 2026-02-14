#!/bin/bash

# test-tui-milestone-1-012.sh - CATEGORY 12: STATUS BAR TESTS
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
# CATEGORY 12: STATUS BAR TESTS
# ============================================================================
test_status_bar_files_panel() {
    log_test "test_status_bar_files_panel" \
             "Status bar shows correct shortcuts for files panel"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file.txt

    # Launch TUI
    tui_start

    # Assert: Status bar should show collapse/expand shortcut
    tui_assert_contains "Collapse" "Status bar shows Collapse option"

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_status_bar_files_panel
