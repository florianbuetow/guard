#!/bin/bash

# test-tui-search-022.sh - BUG: Focused panel title should use reverse video
# Tests that the focused panel title in the top border uses ANSI reverse video
# escape code \e[7m instead of bold \e[1m. Reverse video makes the focused
# panel title much more visually distinct.

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
# TEST: Focused panel title uses reverse video ANSI code
# ============================================================================
test_title_reverse_video() {
    log_test "test_title_reverse_video" \
             "Focused panel title uses reverse video (ANSI \\e[7m) not bold (\\e[1m)"

    # Setup: Initialize guard and create files
    $GUARD_BIN init 000 flo staff
    touch file1.txt
    $GUARD_BIN add file1.txt

    # Launch TUI
    tui_start

    # Assert: TUI is running
    tui_assert_running "TUI session is active"

    # Assert: Row 1 (top border) contains reverse video ANSI code for focused panel
    # Files panel is focused by default, so its title should have \e[7m
    tui_assert_row_has_ansi_code 1 $'\e[7m' "Focused Files title has reverse video styling"

    # Assert: Row 1 should NOT contain bold code (we replaced bold with reverse video)
    tui_assert_row_no_ansi_code 1 $'\e[1m' "Top border does not use bold styling"

    # Action: Press Tab to switch focus to Collections panel
    tui_send_keys Tab

    # Assert: Now Collections should have reverse video
    tui_assert_row_has_ansi_code 1 $'\e[7m' "Focused Collections title has reverse video after Tab"

    # Cleanup
    tui_stop
}

# Run test
run_test test_title_reverse_video
print_test_summary 1
