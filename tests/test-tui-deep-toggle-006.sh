#!/bin/bash

# test-tui-deep-toggle-006.sh - Recursive toggle affects all levels without ignores

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
source "$SCRIPT_DIR/helpers-tui-deep-toggle.sh"
set -e

find_guard_binary

if ! tui_check_tmux; then
    exit 1
fi

test_deep_toggle_affects_all_levels_without_ignores() {
    log_test "test_deep_toggle_affects_all_levels_without_ignores" \
             "Enter recursively guards and unguards all descendant files when no ignore files exist"

    deep_create_fixture false
    deep_init_guard

    deep_select_tree_in_tui
    tui_send_keys "Enter"
    tui_assert_contains "[G] tree/" "Closed tree folder shows [G] after first Enter"
    deep_assert_command_files_guard_flag "true" deep_all_files

    tui_send_keys "Enter"
    tui_assert_contains "[-] tree/" "Closed tree folder shows [-] after second Enter"
    tui_stop

    deep_assert_command_files_guard_flag "false" deep_all_files
}

tui_run_test test_deep_toggle_affects_all_levels_without_ignores
