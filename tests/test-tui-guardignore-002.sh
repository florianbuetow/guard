#!/bin/bash

# test-tui-guardignore-002.sh - Registered ignored files stay visible in TUI

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
set -e

find_guard_binary

if ! tui_check_tmux; then
    exit 1
fi

test_tui_registered_ignored_files_visible() {
    log_test "test_tui_registered_ignored_files_visible" \
             "Registered files should remain visible even when matching ignore patterns"

    touch important.log other.log normal.txt
    echo "*.log" > .guardignore

    "$GUARD_BIN" init 0644 "$(get_current_user)" "$(get_current_group)"
    "$GUARD_BIN" add --force important.log

    tui_start

    tui_assert_contains "important.log" "registered ignored file should be visible"
    tui_assert_not_contains "other.log" "unregistered ignored file should be hidden"
    tui_assert_contains "normal.txt" "non-ignored file should be visible"

    tui_stop
}

tui_run_test test_tui_registered_ignored_files_visible
