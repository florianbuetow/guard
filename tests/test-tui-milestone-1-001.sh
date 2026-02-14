#!/bin/bash

# test-tui-milestone-1-001.sh - CATEGORY 1: STARTUP AND EXIT TESTS
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
# CATEGORY 1: STARTUP AND EXIT TESTS
# ============================================================================
test_tui_launch_success() {
    log_test "test_tui_launch_success" \
             "TUI launches successfully with valid .guardfile"

    # Setup: Initialize guard and create some files
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt file2.txt
    $GUARD_BIN add file file1.txt file2.txt

    # Launch TUI
    tui_start

    # Assert: Both panel headers should be visible
    tui_assert_contains "Files" "Screen shows Files panel header"
    tui_assert_contains "Collections" "Screen shows Collections panel header"

    # Assert: TUI is running
    tui_assert_running "TUI session is active"

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_tui_launch_success
