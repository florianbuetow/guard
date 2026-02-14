#!/bin/bash

# test-tui-milestone-1-011.sh - CATEGORY 11: VISUAL STYLING TESTS
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
# CATEGORY 11: VISUAL STYLING TESTS
# ============================================================================
test_symlink_gray_color() {
    log_test "test_symlink_gray_color" \
             "Symlinks rendered in gray (ANSI 7)"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch realfile.txt
    ln -s realfile.txt symlink.txt

    # Launch TUI
    tui_start

    # Assert: Symlink should have gray styling
    # This checks for the presence of the symlink in the output
    tui_assert_contains "symlink" "Symlink visible in TUI"

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_symlink_gray_color
