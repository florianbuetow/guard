#!/bin/bash

# test-tui-milestone-1-019.sh - CATEGORY 19: DISPLAY/LAYOUT (NEW)
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
# CATEGORY 19: DISPLAY/LAYOUT (NEW)
# ============================================================================
test_terminal_resize_redraws() {
    log_test "test_terminal_resize_redraws" \
             "Application redraws when terminal is resized (Spec lines 126-129)"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch testfile.txt
    $GUARD_BIN create testcoll
    $GUARD_BIN update testcoll add testfile.txt

    # Launch TUI at initial size
    tui_start 80 30

    # Capture initial screen
    local screen_before=$(tui_capture)

    # Resize terminal
    tui_resize 120 40

    # Capture after resize
    local screen_after=$(tui_capture)

    # Assert: TUI still running
    tui_assert_running "TUI running after resize"

    # Assert: Both panels still visible
    tui_assert_contains "Files" "Files panel visible after resize"
    tui_assert_contains "Collections" "Collections panel visible after resize"

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_terminal_resize_redraws
