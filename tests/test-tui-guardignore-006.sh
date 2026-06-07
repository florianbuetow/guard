#!/bin/bash

# test-tui-guardignore-006.sh - Gitignored guarded files show [g] indicator, non-ignored show [G]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
set -e

find_guard_binary

if ! tui_check_tmux; then
    exit 1
fi

test_tui_gitignored_guarded_file_shows_lowercase_g() {
    log_test "test_tui_gitignored_guarded_file_shows_lowercase_g" \
             "Gitignored guarded file shows [g], non-ignored guarded file shows [G]"

    # Setup: two files, one gitignored and one not
    touch normal.txt ignored.txt
    echo 'ignored.txt' > .gitignore

    "$GUARD_BIN" init 0644 "$(get_current_user)" "$(get_current_group)"
    "$GUARD_BIN" add normal.txt
    "$GUARD_BIN" add --force ignored.txt
    "$GUARD_BIN" enable normal.txt ignored.txt

    tui_start

    # Both files should be visible
    tui_assert_contains 'normal.txt' 'non-ignored guarded file should be visible'
    tui_assert_contains 'ignored.txt' 'gitignored guarded file should be visible'

    # Non-ignored guarded file should show [G] (explicit guard)
    tui_assert_matches '\[G\].*normal.txt' 'non-ignored guarded file shows [G]'

    # Gitignored guarded file should show [g] (implicit/ignored guard)
    tui_assert_matches '\[g\].*ignored.txt' 'gitignored guarded file shows [g]'

    tui_stop
}

tui_run_test test_tui_gitignored_guarded_file_shows_lowercase_g
