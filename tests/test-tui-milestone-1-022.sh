#!/bin/bash

# test-tui-milestone-1-022.sh - CATEGORY 22: EXIT CODE (NEW)
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
# CATEGORY 22: EXIT CODE (NEW)
# ============================================================================
test_exit_code_zero_on_quit() {
    log_test "test_exit_code_zero_on_quit" \
             "Exit code is 0 on normal quit (Spec line 57)"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"

    # Launch TUI with exit code capture
    tui_start_for_exit_code

    # Send Q to quit
    tui_send_keys "q"

    # Wait for TUI to exit
    sleep 0.5

    # Read the captured exit code
    local exit_code=$(tui_read_exit_code)

    # Assert: Exit code should be 0
    if [ "$exit_code" = "0" ]; then
        echo -e "${GREEN}✓ PASS${NC}: Exit code is 0 on normal quit"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: Exit code is not 0"
        echo -e "  Expected: 0"
        echo -e "  Actual:   $exit_code"
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi

    # Cleanup
    tui_force_stop
}

# Run test
tui_run_test test_exit_code_zero_on_quit
