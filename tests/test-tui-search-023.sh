#!/bin/bash

# test-tui-search-023.sh - Root directory name should not influence fuzzy search results
#
# Bug: When the root directory name matches the search query, all files remain
# visible because the root is a directory and markDescendantsVisible shows everything.
# The root directory should be excluded from fuzzy search candidates.
#
# This test uses a custom TUI start to ensure the root directory name contains
# the search term (the standard tui_start helper masks the real name via symlink).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
set -e

find_guard_binary

if ! tui_check_tmux; then
    exit 1
fi

test_root_dir_excluded_from_fuzzy_search() {
    log_test "test_root_dir_excluded_from_fuzzy_search" \
             "Root directory name should not affect fuzzy search filtering"

    # Create a subdirectory whose name contains 'foobar'
    mkdir -p project-foobar
    cd project-foobar

    # Create files: one matches 'foobar', two do not
    touch foobar-config.txt unrelated.txt other.txt

    "$GUARD_BIN" init 0644 "$(get_current_user)" "$(get_current_group)"

    # Custom TUI start: use a symlink whose basename contains the search term
    # (tui_start uses _gt<pid> which would mask the real directory name)
    local width=80
    local height=30

    tmux kill-session -t "$TUI_SESSION" 2>/dev/null || true
    sleep 0.3
    while tmux has-session -t "$TUI_SESSION" 2>/dev/null; do
        sleep 0.1
    done

    tmux new-session -d -s "$TUI_SESSION" -x "$width" -y "$height"

    # Symlink with a name that contains the search term 'foobar'
    local project_link="/tmp/project-foobar-$$"
    ln -sfn "$(pwd)" "$project_link"
    tmux send-keys -t "$TUI_SESSION" "cd $project_link" Enter
    sleep 0.5

    tmux send-keys -t "$TUI_SESSION" "$GUARD_BIN -i" Enter
    sleep "$TUI_STARTUP_DELAY"
    tui_screenshot "tui_start_custom"

    # All files visible initially
    tui_assert_contains 'foobar-config.txt' 'matching file visible before search'
    tui_assert_contains 'unrelated.txt' 'non-matching file visible before search'
    tui_assert_contains 'other.txt' 'non-matching file visible before search'

    # Activate search and type 'foobar'
    tui_send_keys "/"
    tui_type "foobar"

    # The matching file should be visible
    tui_assert_contains 'foobar-config.txt' 'foobar-config.txt visible after searching foobar'

    # Non-matching files should be filtered out — this fails if the root dir
    # name 'project-foobar-<pid>' matches and keeps all descendants visible
    tui_assert_not_contains 'unrelated.txt' 'unrelated.txt hidden after searching foobar'
    tui_assert_not_contains 'other.txt' 'other.txt hidden after searching foobar'

    # Clean up symlink
    rm -f "$project_link"

    tui_stop
}

tui_run_test test_root_dir_excluded_from_fuzzy_search
