#!/bin/bash

# test-tui-active-pane-indicator-001.sh - ACTIVE PANE INDICATOR
# Tests that the selection highlight (blue background) only appears
# in the focused pane, not in both panes simultaneously.
#
# Prerequisites:
# - tmux must be installed
# - guard binary must be built
#
# Usage:
#   ./tests/test-tui-active-pane-indicator-001.sh

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

# ANSI code for blue background (basic ANSI SGR 44, lipgloss Color "4")
BLUE_BG="[44m"

# ============================================================================
# ACTIVE PANE INDICATOR
# ============================================================================
test_active_pane_indicator() {
    log_test "test_active_pane_indicator" \
             "Selection highlight only appears in the focused pane"

    # Setup: Initialize guard, create files, collections
    $GUARD_BIN init 000 flo staff
    touch file1.txt file2.txt
    $GUARD_BIN add file1.txt file2.txt
    $GUARD_BIN create alpha beta
    $GUARD_BIN update alpha add file1.txt
    $GUARD_BIN update beta add file2.txt

    # Launch TUI
    tui_start

    # Phase 1: Initial state - files pane is focused
    tui_assert_left_panel_has_ansi_code "$BLUE_BG" \
        "Phase 1: File tree has blue highlight when focused"
    tui_assert_right_panel_no_ansi_code "$BLUE_BG" \
        "Phase 1: Collections panel has no blue highlight when unfocused"

    # Phase 2: Tab to collections pane
    tui_send_keys "Tab"

    tui_assert_left_panel_no_ansi_code "$BLUE_BG" \
        "Phase 2: File tree has no blue highlight when unfocused"
    tui_assert_right_panel_has_ansi_code "$BLUE_BG" \
        "Phase 2: Collections panel has blue highlight when focused"

    # Phase 3: Navigate down in collections (cursor moves to second collection)
    tui_send_keys "Down"

    tui_assert_right_panel_has_ansi_code "$BLUE_BG" \
        "Phase 3: Collections still has highlight after navigating down"

    # Phase 4: Tab back to files pane
    tui_send_keys "Tab"

    tui_assert_left_panel_has_ansi_code "$BLUE_BG" \
        "Phase 4: File tree highlight restored when focused again"
    tui_assert_right_panel_no_ansi_code "$BLUE_BG" \
        "Phase 4: Collections highlight removed when unfocused"
    tui_assert_contains "file1.txt" \
        "Phase 4: File cursor position preserved (file1.txt still visible)"

    # Phase 5: Tab to collections again, verify cursor position preserved
    tui_send_keys "Tab"

    tui_assert_right_panel_has_ansi_code "$BLUE_BG" \
        "Phase 5: Collections highlight restored at preserved position"
    tui_assert_left_panel_no_ansi_code "$BLUE_BG" \
        "Phase 5: File tree highlight removed when unfocused"

    # Cleanup
    tui_stop
}

# Run test
run_test test_active_pane_indicator
print_test_summary 1
