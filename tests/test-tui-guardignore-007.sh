#!/bin/bash

# test-tui-guardignore-007.sh - Gitignored folder with guarded descendants shows [g] indicator

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
set -e

find_guard_binary

if ! tui_check_tmux; then
    exit 1
fi

test_tui_gitignored_folder_shows_lowercase_g() {
    log_test "test_tui_gitignored_folder_shows_lowercase_g" \
             "Gitignored folder with all guarded descendants shows [g]"

    # Setup: a gitignored folder with a registered+guarded file inside
    mkdir -p ignored_dir
    touch ignored_dir/tracked.txt
    touch visible.txt
    echo 'ignored_dir/' > .gitignore

    "$GUARD_BIN" init 0644 "$(get_current_user)" "$(get_current_group)"
    "$GUARD_BIN" add visible.txt
    "$GUARD_BIN" add --force ignored_dir/tracked.txt
    "$GUARD_BIN" enable visible.txt ignored_dir/tracked.txt

    tui_start

    # Gitignored folder should be visible (has registered descendants)
    tui_assert_contains 'ignored_dir' 'gitignored folder with registered files should be visible'

    # Non-ignored guarded file shows [G]
    tui_assert_matches '\[G\].*visible.txt' 'non-ignored guarded file shows [G]'

    # Gitignored folder with all guarded descendants should show [g]
    tui_assert_matches '\[g\].*ignored_dir' 'gitignored folder with guarded descendants shows [g]'

    tui_stop
}

tui_run_test test_tui_gitignored_folder_shows_lowercase_g
