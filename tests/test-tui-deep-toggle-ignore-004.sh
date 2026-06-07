#!/bin/bash

# test-tui-deep-toggle-ignore-004.sh - Deep toggle with both ignore sources inactive

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
source "$SCRIPT_DIR/helpers-tui-deep-toggle.sh"
set -e

find_guard_binary

if ! tui_check_tmux; then
    exit 1
fi

test_deep_toggle_with_both_ignore_sources_inactive() {
    log_test "test_deep_toggle_with_both_ignore_sources_inactive" \
             "Enter recursively toggles every file when gitignore and guardignore are inactive"

    deep_create_fixture true
    deep_init_guard
    "$GUARD_BIN" config set use_gitignore false
    "$GUARD_BIN" config set use_guardignore false

    deep_select_tree_in_tui 100 40
    tui_send_keys "Enter"
    tui_assert_contains "[G] tree/" "Closed tree folder shows [G] after recursive guard"

    deep_assert_command_files_guard_flag "true" deep_all_files

    deep_expand_tree_left_ll
    tui_assert_contains "[G] left/" "Visible left folder shows [G]"
    tui_assert_contains "[G] ll/" "Visible ll folder shows [G]"
    tui_assert_contains "[G] ll.txt" "Visible txt descendant is guarded"
    tui_assert_contains "[G] ll_git.log" "Gitignore-inactive log descendant is visible and guarded"
    tui_assert_contains "[G] ll_guard.tmp" "Guardignore-inactive tmp descendant is visible and guarded"
    tui_stop
}

tui_run_test test_deep_toggle_with_both_ignore_sources_inactive
