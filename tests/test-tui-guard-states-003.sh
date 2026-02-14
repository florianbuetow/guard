#!/bin/bash

# test-tui-guard-states-003.sh - COLLECTION GUARD STATE INDICATORS
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
# COLLECTION GUARD STATE INDICATORS
# ============================================================================
test_collection_indicator_guarded() {
    log_test "test_collection_indicator_guarded" \
             "Collection shows [G] when explicitly guarded with all files guarded"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt file2.txt
    # Create and enable collection
    $GUARD_BIN create mycoll
    $GUARD_BIN update mycoll add file1.txt file2.txt
    $GUARD_BIN enable collection mycoll

    # Launch TUI
    tui_start

    # Switch to Collections Panel
    tui_send_keys "Tab"

    # Assert: Should show [G] for explicitly guarded collection
    tui_assert_contains "[G]" "Guarded collection shows [G] indicator"

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_collection_indicator_guarded
