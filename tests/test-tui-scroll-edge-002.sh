#!/bin/bash

# test-tui-scroll-edge-002.sh - Bug fix: Cursor should float freely when scrolling up
# Verifies that when scrolling down past the viewport and then back up,
# the viewport doesn't scroll until the cursor reaches the top edge.
#
# Bug: CalculateScrollOffset is stateless, always pinning cursor to bottom
# Fix: ScrollState.Update preserves offset when cursor is within viewport

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
# Test: Cursor floats freely when scrolling up after scrolling down
# ============================================================================
test_scroll_up_free_float() {
    log_test "test_scroll_up_free_float" \
             "Cursor floats freely within viewport when moving up"

    # Setup: Create enough files to require scrolling
    # TUI height=20, contentHeight=15, viewport=15
    # 32 items total (1 dir + .guardfile + 30 files)
    $GUARD_BIN init 000 flo staff
    for i in $(seq -w 1 30); do
        touch "file${i}.txt"
    done
    $GUARD_BIN add file file*.txt

    # Launch TUI with known height
    tui_start 80 20

    # Scroll down past the viewport: press Down 16 times
    # This should scroll the viewport so the directory header is off-screen
    for i in $(seq 1 16); do
        tui_send_keys "Down"
    done

    # The directory (▼) should now be scrolled off-screen
    tui_assert_not_contains "▼" "Directory scrolled off after 16 Down presses"

    # Now press Up 3 times - cursor moves up but viewport should NOT scroll
    # because cursor is still within the visible area
    # Before pressing Up, capture what's on the first visible line
    local screen_before
    screen_before=$(tui_capture)

    for i in $(seq 1 3); do
        tui_send_keys "Up"
    done

    # The directory should still be off-screen (viewport didn't scroll up)
    tui_assert_not_contains "▼" "Directory still off-screen after 3 Up presses (no premature scroll up)"

    # Cleanup
    tui_stop
}

# Run test
run_test test_scroll_up_free_float
print_test_summary 1
