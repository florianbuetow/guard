#!/bin/bash

# test-tui-guardignore-008.sh - .guardfile hidden in TUI when gitignored and use_gitignore is true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
set -e

find_guard_binary

if ! tui_check_tmux; then
    exit 1
fi

test_tui_guardfile_hidden_when_gitignored() {
    log_test "test_tui_guardfile_hidden_when_gitignored" \
             ".guardfile should not appear in TUI when it is gitignored and use_gitignore is true"

    # Setup: .guardfile is in .gitignore, use_gitignore defaults to true
    touch main.go README.md
    echo '.guardfile' > .gitignore

    "$GUARD_BIN" init 0644 "$(get_current_user)" "$(get_current_group)"
    "$GUARD_BIN" add main.go README.md

    tui_start

    # Normal files should be visible
    tui_assert_contains 'main.go' 'main.go should be visible'
    tui_assert_contains 'README.md' 'README.md should be visible'

    # .guardfile should NOT appear since it is gitignored and use_gitignore is true
    tui_assert_not_contains '.guardfile' '.guardfile should be hidden when gitignored'

    tui_stop
}

tui_run_test test_tui_guardfile_hidden_when_gitignored
