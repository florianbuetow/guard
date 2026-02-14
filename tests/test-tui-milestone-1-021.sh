#!/bin/bash

# test-tui-milestone-1-021.sh - CATEGORY 21: REFRESH PRESERVATION (NEW)
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
# CATEGORY 21: REFRESH PRESERVATION (NEW)
# ============================================================================
test_refresh_preserves_folder_expansion() {
    log_test "test_refresh_preserves_folder_expansion" \
             "Refresh preserves folder expansion state (Spec line 466)"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    mkdir -p folder1 folder2
    touch folder1/file1.txt folder2/file2.txt

    # Launch TUI
    tui_start

    # Tree structure (root expanded):
    # ▼ root/
    # ├─ ▶ folder1/
    # ├─ ▶ folder2/
    # └─   .guardfile

    # Navigate to folder1 (Down from root)
    tui_send_keys "Down"
    # Expand folder1 (Right on collapsed folder)
    tui_send_keys "Right"

    # Now tree is:
    # ▼ root/
    # ├─ ▼ folder1/       <- cursor here
    # │  └─ file1.txt
    # ├─ ▶ folder2/
    # └─   .guardfile

    # Navigate down to folder2 (Down -> file1.txt, Down -> folder2)
    tui_send_keys "Down"
    tui_send_keys "Down"
    # Expand folder2
    tui_send_keys "Right"

    # Verify both children visible before refresh
    tui_assert_contains "file1.txt" "folder1 child visible before refresh"
    tui_assert_contains "file2.txt" "folder2 child visible before refresh"

    # Refresh
    tui_send_keys "r"
    sleep 0.5

    # Assert: Both folders still expanded after refresh
    tui_assert_contains "file1.txt" "folder1 child still visible after refresh"
    tui_assert_contains "file2.txt" "folder2 child still visible after refresh"

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_refresh_preserves_folder_expansion
