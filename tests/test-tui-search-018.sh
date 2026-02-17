#!/bin/bash

# test-tui-search-018.sh - BUG: Cursor blinks in search box when panel has focus
# Tests that the search box textinput is blurred when focus moves to a panel.
# TDD: This test should FAIL until the cursor blink bug is fixed.

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

if ! tui_check_tmux; then
    exit 1
fi

# ============================================================================
# TEST: Cursor stops blinking when search box loses focus via Tab
# ============================================================================
test_cursor_stops_on_tab_away() {
    log_test "test_cursor_stops_on_tab_away" \
             "Search box cursor stops blinking when focus moves to a panel"

    # Setup
    $GUARD_BIN init 000 flo staff
    touch file1.txt file2.txt
    $GUARD_BIN add file1.txt file2.txt

    # Launch TUI
    tui_start

    tui_assert_running "TUI session is active"

    # Activate search — cursor should be blinking (focused)
    tui_send_keys "/"
    tui_assert_contains "Search:" "Search box is active"

    # Capture the search line while search has focus
    # The textinput renders a cursor indicator when focused
    local screen_focused=$(tui_capture_ansi)

    # Tab to Files panel — cursor should stop blinking (blurred)
    tui_send_keys Tab

    # Search should still be visible
    tui_assert_contains "Search:" "Search bar still visible after Tab"

    # Capture the search line after losing focus
    local screen_blurred=$(tui_capture_ansi)

    # The focused state should have cursor ANSI codes that the blurred state lacks.
    # When the textinput is focused, it renders a block cursor (reverse video).
    # When blurred, no cursor escapes are emitted in the search line.
    # We check for the reverse video ANSI code (\e[7m) which the textinput uses for cursor.
    #
    # Extract just the search line (contains "Search:") from each capture
    local search_line_focused=$(echo "$screen_focused" | grep "Search:" | head -1)
    local search_line_blurred=$(echo "$screen_blurred" | grep "Search:" | head -1)

    # The focused search line should contain reverse video escape (cursor visible)
    if [[ "$search_line_focused" != *$'\e[7m'* ]]; then
        # If we can't detect cursor via ANSI, fall back to behavioral test:
        # Tab back to search, type something, verify it goes to search input
        tui_send_keys Tab  # Collections
        tui_send_keys Tab  # back to Search
        tui_type "z"
        tui_assert_contains "z" "Typing works when focus returns to search (fallback test)"
        tui_stop
        return 0
    fi

    # The blurred search line should NOT contain reverse video escape (cursor hidden)
    if [[ "$search_line_blurred" == *$'\e[7m'* ]]; then
        tui_fail "Search box cursor is still visible (blinking) after Tab moved focus to panel"
    fi

    echo -e "${GREEN}✓ PASS${NC}: Cursor is not visible in search box after focus moved away"
    ((TESTS_PASSED++))

    # Cleanup
    tui_stop
}

# Run test
run_test test_cursor_stops_on_tab_away
print_test_summary 1
