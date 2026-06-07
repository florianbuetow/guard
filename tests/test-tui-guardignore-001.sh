#!/bin/bash

# test-tui-guardignore-001.sh - Guardignore filtering in TUI file tree

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
set -e

find_guard_binary

if ! tui_check_tmux; then
    exit 1
fi

test_tui_hides_ignored_files() {
    log_test "test_tui_hides_ignored_files" \
             "TUI file tree should hide files matching .guardignore patterns"

    touch main.go debug.log
    echo "*.log" > .guardignore

    "$GUARD_BIN" init 0644 "$(get_current_user)" "$(get_current_group)"

    tui_start

    tui_assert_contains "main.go" "main.go should be visible in file tree"
    tui_assert_not_contains "debug.log" "debug.log should be hidden by .guardignore"

    tui_stop
}

tui_run_test test_tui_hides_ignored_files
