#!/bin/bash

# test-bug-tui-statusline-001.sh - BUG: Status line should show key hints, not status messages
#
# From docs/todo/BUGS.md:
# "The status line of the guard tool is not displaying the navigation and key hints as specified.
# Instead, it displays status information like 'Collection guarded' in the bottom status line."
#
# This test asserts the status bar keeps showing key hints even after a guard toggle.

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

# ==========================================================================
# BUG: Status line shows wrong information
# ==========================================================================

test_status_line_shows_key_hints_after_toggle() {
    log_test "test_status_line_shows_key_hints_after_toggle" \
             "Status bar should keep key hints even after toggling guard"

    local user=$(get_current_user)
    local group=$(get_current_group)

    # Setup
    $GUARD_BIN init 000 "$user" "$group"
    touch file1.txt

    # Launch TUI
    tui_start 80 24

    # Sanity: key hints should be visible at startup
    tui_assert_contains "/: Search" "Status bar shows search hint"
    tui_assert_contains "R: Refresh" "Status bar shows refresh hint"
    tui_assert_contains "Q: Quit" "Status bar shows quit hint"

    # Navigate to file and toggle guard
    # Root folder is first, then children are sorted: .guardfile, file1.txt
    tui_send_keys "Down"
    tui_send_keys "Down"
    tui_send_keys "Space"

    # After toggle, status bar should still show key hints
    tui_assert_contains "/: Search" "Status bar still shows search hint after toggle"
    tui_assert_contains "R: Refresh" "Status bar still shows refresh hint after toggle"
    tui_assert_contains "Q: Quit" "Status bar still shows quit hint after toggle"

    # Should NOT show temporary status messages
    tui_assert_not_contains "File guarded" "Status bar should not show file status messages"
    tui_assert_not_contains "Files guarded" "Status bar should not show multi-file status messages"
    tui_assert_not_contains "Collection guarded" "Status bar should not show collection status messages"
    tui_assert_not_contains "Refreshed" "Status bar should not show refresh status messages"

    # Cleanup
    tui_stop
}

# Run test
run_test test_status_line_shows_key_hints_after_toggle
print_test_summary 1
