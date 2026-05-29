#!/bin/bash

# test-tui-guard-states-004.sh - FOLDER GUARD STATE TOGGLE CYCLE
# Tests that toggling a folder cycles its guard indicator through [ ] -> [G] -> [-]
#
# Setup: A folder with a subfolder containing a file, plus a file at the folder level.
# The folder toggle (Space) operates on immediate children files, so we need at least
# one file directly in the folder for the toggle to take effect.
#
# Guard State Cycle:
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
# FOLDER GUARD STATE TOGGLE CYCLE: [ ] -> [G] -> [-]
# ============================================================================
test_folder_toggle_cycle() {
    log_test "test_folder_toggle_cycle" \
             "Folder guard state cycles through [ ] -> [G] -> [-] on toggle"

    # Setup: init guard, create folder structure
    $GUARD_BIN init 0644 "$(get_current_user)" "$(get_current_group)"
    mkdir -p myfolder/subfolder
    touch myfolder/file.txt
    touch myfolder/subfolder/deepfile.txt
    chmod 644 myfolder/file.txt
    chmod 644 myfolder/subfolder/deepfile.txt

    # Launch TUI
    tui_start

    # Navigate to myfolder/ (root is selected first, folders sorted before files)
    # Tree: root -> myfolder/ -> .guardfile
    tui_send_keys "Down"

    # Assert initial state: folder shows [ ] (no files registered)
    tui_assert_contains "[ ] myfolder/" "Folder starts with [ ] indicator (no files registered)"

    # First toggle: [ ] -> [G] (registers and guards immediate files)
    tui_send_keys "Space"
    sleep 0.3

    tui_assert_contains "[G] myfolder/" "Folder shows [G] after first toggle (all files guarded)"

    # Second toggle: [G] -> [-] (unguards immediate files)
    tui_send_keys "Space"
    sleep 0.3

    tui_assert_contains "[-] myfolder/" "Folder shows [-] after second toggle (all files unguarded)"

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_folder_toggle_cycle
