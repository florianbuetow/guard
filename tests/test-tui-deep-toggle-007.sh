#!/bin/bash

# test-tui-deep-toggle-007.sh - Deep toggle indicators update through opened descendants

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
source "$SCRIPT_DIR/helpers-tui-deep-toggle.sh"
set -e

find_guard_binary

if ! tui_check_tmux; then
    exit 1
fi

test_deep_toggle_indicators_update_for_later_opened_descendants() {
    log_test "test_deep_toggle_indicators_update_for_later_opened_descendants" \
             "Closed root and later-opened descendants show recursive guard state after Enter"

    deep_create_fixture false
    deep_init_guard

    deep_select_tree_in_tui 100 40
    tui_send_keys "Enter"
    tui_assert_contains "[G] tree/" "Closed tree folder shows [G] after recursive guard"

    deep_expand_tree_left_ll
    tui_assert_contains "[G] left/" "Opened left folder shows [G]"
    tui_assert_contains "[G] ll/" "Opened ll folder shows [G]"
    tui_assert_contains "[G] ll.txt" "Deep ll.txt file shows [G]"

    deep_expand_no_ignore_right_rr_from_ll
    tui_assert_contains "[G] right/" "Opened right folder shows [G]"
    tui_assert_contains "[G] rr/" "Opened rr folder shows [G]"
    tui_assert_contains "[G] rr.txt" "Deep rr.txt file shows [G]"
    tui_stop

    deep_select_tree_in_tui 100 40
    tui_send_keys "Enter"
    tui_assert_contains "[-] tree/" "Closed tree folder shows [-] after recursive unguard"

    deep_expand_tree_left_ll
    tui_assert_contains "[-] left/" "Opened left folder shows [-]"
    tui_assert_contains "[-] ll/" "Opened ll folder shows [-]"
    tui_assert_contains "[-] ll.txt" "Deep ll.txt file shows [-]"

    deep_expand_no_ignore_right_rr_from_ll
    tui_assert_contains "[-] right/" "Opened right folder shows [-]"
    tui_assert_contains "[-] rr/" "Opened rr folder shows [-]"
    tui_assert_contains "[-] rr.txt" "Deep rr.txt file shows [-]"
    tui_stop
}

tui_run_test test_deep_toggle_indicators_update_for_later_opened_descendants
