#!/bin/bash

# test-tui-search-021.sh - BUG: Search box cursor should blink when focused
# Tests that the cursor blink tea.Cmd is properly propagated when search activates.
# The textinput.Focus() returns a tea.Cmd that starts cursor blink animation.
# If SetActive() discards that Cmd, the cursor won't blink.

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
# TEST: Search box cursor blinks (Focus Cmd is propagated)
# ============================================================================
test_search_cursor_blink() {
    log_test "test_search_cursor_blink" \
             "Search box cursor blink Cmd is propagated from SetActive/Focus"

    # Setup: Initialize guard and create files
    $GUARD_BIN init 000 flo staff
    touch apple.txt banana.txt cherry.txt
    $GUARD_BIN add apple.txt banana.txt cherry.txt

    # Launch TUI
    tui_start

    # Assert: TUI is running
    tui_assert_running "TUI session is active"
    tui_assert_contains "apple.txt" "File tree shows apple.txt"

    # Action: Press '/' to activate search
    tui_send_keys "/"

    # Assert: Search box is visible
    tui_assert_contains "Search:" "Search box prompt is visible"

    # Action: Type some text to verify the textinput is focused and accepting input
    tui_type "app"

    # Assert: Typed text appears in the search box
    tui_assert_contains "app" "Typed text 'app' appears in search box"

    # Action: Tab away from search to files panel, then Tab back to search
    tui_send_keys Tab
    tui_send_keys Tab
    tui_send_keys Tab

    # Assert: After cycling back to search, typing still works (Focus Cmd propagated)
    tui_type "le"

    # Assert: The search box now shows "apple" (previous "app" + new "le")
    tui_assert_contains "apple" "Search box shows 'apple' after cycling focus and typing"

    # Cleanup
    tui_stop
}

# Run test
run_test test_search_cursor_blink
print_test_summary 1
