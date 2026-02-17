#!/bin/bash

# test-tui-search-013.sh - ESC DOES NOT QUIT: Pressing Escape does not quit the TUI
# Tests that pressing Escape does not quit the TUI when search is not active.
# TDD: This test should FAIL until ESC is removed from quit bindings.

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

# Check for tmux
if ! tui_check_tmux; then
    exit 1
fi

# ============================================================================
# TEST: ESC does not quit the TUI
# ============================================================================
test_esc_does_not_quit() {
    log_test "test_esc_does_not_quit" \
             "Pressing ESC does not quit the TUI when search is not active"

    # Setup: Initialize guard and create files
    $GUARD_BIN init 000 flo staff
    touch file1.txt file2.txt
    $GUARD_BIN add file1.txt file2.txt

    # Launch TUI
    tui_start

    # Assert: TUI is running
    tui_assert_running "TUI session is active"
    tui_assert_contains "file1.txt" "File tree shows files"

    # Action: Press ESC (should NOT quit)
    tui_send_keys Escape

    # Assert: TUI is still running after ESC
    tui_assert_running "TUI still running after pressing ESC"
    tui_assert_contains "file1.txt" "File tree still visible after ESC"

    # Verify q still quits (control check)
    tui_send_keys "q"
    tui_assert_exited "TUI exits when pressing q"
}

# Run test
run_test test_esc_does_not_quit
print_test_summary 1
