#!/bin/bash

# test-tui-guard-states-005.sh - DEEP RECURSIVE FOLDER GUARD STATE TOGGLE CYCLE
# Tests that Enter (deep recursive toggle) on a folder with only subdirectories
# cycles its guard indicator through [ ] -> [G] -> [-]
#
# Setup: A folder with NO immediate files, only a subfolder containing a file.
# Regular Space toggle has nothing to operate on (no immediate files).
# Enter (deep recursive toggle) reaches files in all subdirectories.
#
# Key bindings tested:
#   Space = shallow toggle (immediate children files only)
#   Enter = deep recursive toggle (all descendant files)
#
# Guard State Cycle (via Enter):
#   [ ] (no files registered) -> [G] (all files guarded) -> [-] (all files unguarded)
#
# Prerequisites:
# - tmux must be installed
# - guard binary must be built

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
# DEEP RECURSIVE FOLDER GUARD STATE TOGGLE CYCLE: [ ] -> [G] -> [-]
# ============================================================================
test_folder_recursive_toggle_cycle() {
    log_test "test_folder_recursive_toggle_cycle" \
             "Deep recursive toggle (Enter) cycles folder guard state [ ] -> [G] -> [-] when folder has only subdirectories"

    # Setup: init guard, create folder with only a subfolder (no immediate files)
    $GUARD_BIN init 0644 "$(get_current_user)" "$(get_current_group)"
    mkdir -p myfolder/subfolder
    touch myfolder/subfolder/deepfile.txt
    chmod 644 myfolder/subfolder/deepfile.txt

    # Launch TUI
    tui_start

    # Navigate to myfolder/ (root is selected first, folders sorted before files)
    tui_send_keys "Down"

    # Assert initial state: folder shows [ ] (no files registered)
    tui_assert_contains "[ ] myfolder/" "Folder starts with [ ] indicator (no files registered)"

    # Regular Space should have no effect (no immediate files)
    tui_send_keys "Space"
    sleep 0.3

    tui_assert_contains "[ ] myfolder/" "Folder still shows [ ] after Space (no immediate files to toggle)"

    # Deep recursive toggle (Enter): [ ] -> [G]
    tui_send_keys "Enter"
    sleep 0.3

    tui_assert_contains "[G] myfolder/" "Folder shows [G] after Enter (all descendant files guarded)"

    # Deep recursive toggle again (Enter): [G] -> [-]
    tui_send_keys "Enter"
    sleep 0.3

    tui_assert_contains "[-] myfolder/" "Folder shows [-] after second Enter (all descendant files unguarded)"

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_folder_recursive_toggle_cycle
