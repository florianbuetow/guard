#!/bin/bash

# test-tui-milestone-1-008.sh - CATEGORY 8: COLLECTIONS PANEL HIERARCHY TESTS
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
# CATEGORY 8: COLLECTIONS PANEL HIERARCHY TESTS
# ============================================================================
test_collection_parent_child() {
    log_test "test_collection_parent_child" \
             "Parent-child relationship shown with indentation"

    # Setup: Create parent collection (superset) and child (subset)
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt file2.txt
    $GUARD_BIN create parent
    $GUARD_BIN update parent add file1.txt file2.txt
    $GUARD_BIN create child
    $GUARD_BIN update child add file1.txt  # child is subset of parent

    # Launch TUI
    tui_start

    # Switch to collections
    tui_send_keys "Tab"

    # Assert: Both collections visible
    tui_assert_contains "parent" "Parent collection visible"
    tui_assert_contains "child" "Child collection visible"

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_collection_parent_child
