#!/bin/bash

# test-tui-milestone-1-002.sh - CATEGORY 2: TERMINAL SIZE TESTS
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
# CATEGORY 2: TERMINAL SIZE TESTS
# ============================================================================
test_tui_minimum_size() {
    log_test "test_tui_minimum_size" \
             "TUI renders correctly at minimum size (40x25)"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch testfile.txt

    # Launch TUI at minimum size
    tui_start 40 25

    # Assert: Both panels should be visible
    tui_assert_contains "Files" "Files panel visible at minimum size"
    tui_assert_contains "Collections" "Collections panel visible at minimum size"

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_tui_minimum_size
