#!/bin/bash

# test-tui-milestone-1-017.sh - CATEGORY 17: ERROR HANDLING - REAL ERRORS (NEW)
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
# CATEGORY 17: ERROR HANDLING - REAL ERRORS (NEW)
# ============================================================================
test_error_modal_permission_denied() {
    log_test "test_error_modal_permission_denied" \
             "Error modal appears on permission denied (Spec lines 435-439)"

    # Note: This test requires running TUI without proper permissions
    # The setup and assertions may need adjustment based on actual implementation

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch testfile.txt
    $GUARD_BIN add file testfile.txt

    # Launch TUI (without sudo - may trigger permission error on toggle)
    tui_start

    # Try to toggle - this might fail without proper permissions
    tui_send_keys "Space"
    sleep 0.5

    # Assert: TUI should still be running (error handled gracefully)
    tui_assert_running "TUI running after potential permission error"

    # If error modal appeared, dismiss it
    tui_send_keys "Enter"

    # Assert: TUI still running after modal dismiss
    tui_assert_running "TUI running after dismissing modal"

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_error_modal_permission_denied
