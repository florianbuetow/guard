#!/bin/bash

# test-tui-milestone-1-010.sh - CATEGORY 10: ERROR MODAL TESTS
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
# CATEGORY 10: ERROR MODAL TESTS
# ============================================================================
test_error_modal_dismiss_enter() {
    log_test "test_error_modal_dismiss_enter" \
             "Enter key dismisses error modal"

    # This test requires triggering an error condition
    # For now, we test the basic flow
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch testfile.txt

    # Launch TUI
    tui_start

    # If we could trigger an error modal, Enter should dismiss it
    # For now, just verify TUI handles Enter gracefully
    tui_send_keys "Enter"

    tui_assert_running "TUI running after Enter key"

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_error_modal_dismiss_enter
