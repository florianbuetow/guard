#!/bin/bash

# test-tui-deep-toggle-ignore-005.sh - Registered ignored descendants remain toggleable

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
source "$SCRIPT_DIR/helpers-tui-deep-toggle.sh"
set -e

find_guard_binary

if ! tui_check_tmux; then
    exit 1
fi

test_deep_toggle_keeps_registered_ignored_descendants_toggleable() {
    log_test "test_deep_toggle_keeps_registered_ignored_descendants_toggleable" \
             "Enter recursively toggles force-registered ignored descendants while leaving other ignored files absent"

    deep_create_fixture true
    deep_init_guard
    "$GUARD_BIN" add --force tree/left/ll/ll_git.log
    "$GUARD_BIN" add --force tree/right/rr/rr_guard.tmp

    deep_select_tree_in_tui 100 40
    tui_send_keys "Enter"
    tui_assert_contains "[G] tree/" "Closed tree folder shows [G] after recursive guard"

    deep_assert_command_files_guard_flag "true" deep_txt_files
    deep_assert_files_guard_flag "true" \
        tree/left/ll/ll_git.log \
        tree/right/rr/rr_guard.tmp
    deep_assert_files_absent \
        tree/root_git.log \
        tree/left/left_git.log \
        tree/right/right_git.log \
        tree/root_guard.tmp \
        tree/left/left_guard.tmp \
        tree/left/ll/ll_guard.tmp \
        tree/right/right_guard.tmp

    deep_expand_tree_left_ll
    tui_assert_contains "[G] ll.txt" "Non-ignored descendant shows [G]"
    tui_assert_matches '\[g\].*ll_git.log' "Registered gitignored descendant shows [g]"
    tui_assert_not_contains "ll_guard.tmp" "Unregistered guardignored descendant is hidden"

    deep_expand_default_ignore_right_rr_from_ll
    tui_assert_contains "[G] rr.txt" "Non-ignored rr descendant shows [G]"
    tui_assert_matches '\[g\].*rr_guard.tmp' "Registered guardignored descendant shows [g]"
    tui_stop
}

tui_run_test test_deep_toggle_keeps_registered_ignored_descendants_toggleable
