#!/bin/bash

# test-tui-guard-states-001.sh - FILE GUARD STATE INDICATORS
# Tests all guard state indicators for files, folders, and collections
# according to TUI-EFFECTIVE-GUARD-STATES.md
#
# Guard State Indicators:
#   Files:       [G] guarded, [-] unguarded, [ ] untracked
#   Folders:     [G] all guarded, [-] all unguarded, [~] mixed, [ ] no collection
#   Collections: [G] guarded, [g] implicitly guarded, [~] mixed, [-] unguarded
#
# Prerequisites:
# - tmux must be installed
# - guard binary must be built
#
# Usage:
#   ./tests/test-tui-guard-states.sh

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
# FILE GUARD STATE INDICATORS
# ============================================================================
test_file_indicator_untracked() {
    log_test "test_file_indicator_untracked" \
             "File shows [ ] when not in registry (untracked)"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch untracked.txt
    # Don't add to registry

    # Launch TUI
    tui_start

    # Assert: Should show [ ] for untracked file
    tui_assert_contains "[ ]" "Untracked file shows [ ] indicator"

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_file_indicator_untracked
