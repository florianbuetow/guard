#!/bin/bash

# test-tui-guardignore-003.sh - Registered files in gitignored subfolders must be visible in TUI

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
set -e

find_guard_binary

if ! tui_check_tmux; then
    exit 1
fi

test_tui_registered_files_in_gitignored_subfolder_visible() {
    log_test "test_tui_registered_files_in_gitignored_subfolder_visible" \
             "Registered files in gitignored subfolders must be visible in TUI"

    mkdir -p project/subfolder
    touch project/file1.txt project/subfolder/file2.txt project/subfolder/untracked.txt
    echo 'project/subfolder/' > .gitignore

    "$GUARD_BIN" init 0644 "$(get_current_user)" "$(get_current_group)"
    "$GUARD_BIN" add project/file1.txt
    "$GUARD_BIN" add --force project/subfolder/file2.txt

    tui_start

    # Expand project and then subfolder
    tui_send_keys "Down"
    tui_send_keys "Right"
    tui_send_keys "Down"
    tui_send_keys "Right"

    tui_assert_contains 'file1.txt' 'registered file in non-ignored folder should be visible'
    tui_assert_contains 'subfolder' 'gitignored subfolder with registered files should be visible'
    tui_assert_contains 'file2.txt' 'registered file in gitignored subfolder should be visible'
    tui_assert_not_contains 'untracked.txt' 'unregistered file in gitignored subfolder should be hidden'

    tui_stop
}

tui_run_test test_tui_registered_files_in_gitignored_subfolder_visible
