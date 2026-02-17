#!/bin/bash

# test-tui-guardignore-004.sh - Deeply nested registered file in gitignored folder tree shows all ancestors

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
set -e

find_guard_binary

if ! tui_check_tmux; then
    exit 1
fi

test_tui_deep_registered_file_shows_ancestor_folders() {
    log_test "test_tui_deep_registered_file_shows_ancestor_folders" \
             "Deeply nested registered file in gitignored folder tree shows all ancestors"

    mkdir -p A/B/C
    touch A/B/C/testfile.txt
    touch A/noise1.txt B_noise.txt A/B/noise2.txt A/B/C/noise3.txt
    echo 'A/' > .gitignore

    "$GUARD_BIN" init 0644 "$(get_current_user)" "$(get_current_group)"
    "$GUARD_BIN" add --force A/B/C/testfile.txt

    tui_start

    # Expand A -> B -> C
    tui_send_keys "Down"
    tui_send_keys "Right"
    tui_send_keys "Down"
    tui_send_keys "Right"
    tui_send_keys "Down"
    tui_send_keys "Right"

    tui_assert_contains 'A' 'ancestor folder A should be visible because it contains a registered file'
    tui_assert_contains 'B' 'ancestor folder B should be visible because it contains a registered file'
    tui_assert_contains 'C' 'ancestor folder C should be visible because it contains a registered file'
    tui_assert_contains 'testfile.txt' 'deeply nested registered file should be visible'
    tui_assert_not_contains 'noise1.txt' 'unregistered file in gitignored folder A should be hidden'
    tui_assert_not_contains 'noise2.txt' 'unregistered file in gitignored folder B should be hidden'
    tui_assert_not_contains 'noise3.txt' 'unregistered file in gitignored folder C should be hidden'

    tui_stop
}

tui_run_test test_tui_deep_registered_file_shows_ancestor_folders
