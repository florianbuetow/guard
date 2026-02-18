#!/bin/bash

# test-tui-guardignore-005.sh - Toggle guard on gitignored folder only affects already-registered files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
set -e

find_guard_binary

if ! tui_check_tmux; then
    exit 1
fi

test_tui_toggle_gitignored_folder_affects_only_registered_files() {
    log_test "test_tui_toggle_gitignored_folder_affects_only_registered_files" \
             "Toggle guard on gitignored folder only affects already-registered files"

    mkdir -p ignored_dir
    touch ignored_dir/tracked.txt ignored_dir/untracked.txt
    echo 'ignored_dir/' > .gitignore

    "$GUARD_BIN" init 0644 "$(get_current_user)" "$(get_current_group)"
    "$GUARD_BIN" add --force ignored_dir/tracked.txt

    tui_start

    # Navigate to ignored_dir folder, expand it, then toggle guard on the folder.
    tui_send_keys "Down"
    tui_send_keys "Right"

    tui_assert_contains 'ignored_dir' 'gitignored folder with registered files should be visible'
    tui_assert_contains 'tracked.txt' 'registered file should be visible'
    tui_assert_not_contains 'untracked.txt' 'unregistered file in gitignored folder should be hidden'

    tui_send_keys "Space"
    tui_stop

    tracked_guard=$(get_guard_flag "ignored_dir/tracked.txt")
    assert_equals "true" "$tracked_guard" "tracked.txt should be guarded after folder toggle" || return 1

    untracked_count=$(grep -c 'untracked.txt' .guardfile || true)
    assert_equals "0" "$untracked_count" "untracked.txt must not appear in .guardfile" || return 1
}

tui_run_test test_tui_toggle_gitignored_folder_affects_only_registered_files
