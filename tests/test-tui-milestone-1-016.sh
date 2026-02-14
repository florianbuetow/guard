#!/bin/bash

# test-tui-milestone-1-016.sh - CATEGORY 16: COLLECTION IMPLICIT GUARD (NEW)
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
# CATEGORY 16: COLLECTION IMPLICIT GUARD (NEW)
# ============================================================================
test_collection_indicator_implicit_guard() {
    log_test "test_collection_indicator_implicit_guard" \
             "Collection with [g] when not guarded but files guarded via another (Spec lines 341-342)"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch shared.txt other.txt

    # Create parent collection with both files, enable it
    $GUARD_BIN create parent
    $GUARD_BIN update parent add shared.txt other.txt
    $GUARD_BIN enable collection parent

    # Create child collection with subset (shared.txt only), don't enable
    $GUARD_BIN create child
    $GUARD_BIN update child add shared.txt
    # child guard flag is false, but shared.txt is guarded via parent

    # Launch TUI
    tui_start

    # Switch to Collections Panel
    tui_send_keys "Tab"

    # Assert: parent shows [G], child shows [g]
    tui_assert_contains "[G]" "Parent collection shows [G]"
    tui_assert_contains "[g]" "Child collection shows [g] for implicit guard"

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_collection_indicator_implicit_guard
