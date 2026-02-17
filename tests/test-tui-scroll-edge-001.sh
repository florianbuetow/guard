#!/bin/bash

# test-tui-scroll-edge-001.sh - Bug fix: Edge-only scroll behavior
# Verifies that the files pane only scrolls when cursor reaches the viewport edge,
# not when cursor is still several lines away from the edge.
#
# Bug: scrollMargin = viewportHeight / 4 causes premature scrolling
# Fix: scrollMargin = 0 so scrolling only triggers at viewport edge

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

if ! tui_check_tmux; then
    exit 1
fi

# ============================================================================
# Test: Cursor moves through list without premature scrolling
# ============================================================================
test_scroll_edge_only() {
    log_test "test_scroll_edge_only" \
             "Files pane only scrolls when cursor hits viewport edge"

    # Setup: Create enough files to require scrolling
    # TUI height=20, contentHeight = 20 - 1(top border) - 4(status bar) = 15
    # With bug (scrollMargin = 15/4 = 3): scroll starts at cursor 12
    # With fix (scrollMargin = 0): scroll starts at cursor 15
    $GUARD_BIN init 000 flo staff
    for i in $(seq -w 1 30); do
        touch "file${i}.txt"
    done
    $GUARD_BIN add file file*.txt

    # Launch TUI with known height
    tui_start 80 20

    # The first file should be visible and selected
    tui_assert_contains "file01.txt" "First file visible at start"

    # The directory row (▼) is the first item at position 0
    tui_assert_contains "▼" "Directory indicator visible at start"

    # Move cursor down 12 times (cursor at position 12, 0-indexed)
    # Flat list: 0=dir, 1=.guardfile, 2=file01..., viewport=15, total=32
    # With bug: scrollMargin=3, minOffset = 12 - 15 + 3 + 1 = 1 => dir scrolls off
    # With fix: scrollMargin=0, minOffset = 12 - 15 + 0 + 1 = -2 => clamped to 0, no scroll
    for i in $(seq 1 12); do
        tui_send_keys "Down"
    done

    # After 12 Down presses, the directory row (position 0) should still be visible
    # because cursor hasn't reached the viewport bottom edge yet
    tui_assert_contains "▼" "Directory still visible after 12 Down presses (no premature scroll)"

    # Cleanup
    tui_stop
}

# Run test
run_test test_scroll_edge_only
print_test_summary 1
