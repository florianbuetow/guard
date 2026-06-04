#!/bin/bash

# Shared fixture and assertions for deep recursive TUI toggle tests.

deep_create_fixture() {
    local with_ignore="${1:-false}"

    mkdir -p tree/left/ll tree/left/lr tree/right/rl tree/right/rr

    touch \
        tree/root.txt \
        tree/root_git.log \
        tree/root_guard.tmp \
        tree/left/left.txt \
        tree/left/left_git.log \
        tree/left/left_guard.tmp \
        tree/left/ll/ll.txt \
        tree/left/ll/ll_git.log \
        tree/left/ll/ll_guard.tmp \
        tree/left/lr/lr.txt \
        tree/right/right.txt \
        tree/right/right_git.log \
        tree/right/right_guard.tmp \
        tree/right/rl/rl.txt \
        tree/right/rr/rr.txt \
        tree/right/rr/rr_guard.tmp

    chmod 644 tree/root.txt tree/root_git.log tree/root_guard.tmp \
        tree/left/left.txt tree/left/left_git.log tree/left/left_guard.tmp \
        tree/left/ll/ll.txt tree/left/ll/ll_git.log tree/left/ll/ll_guard.tmp \
        tree/left/lr/lr.txt tree/right/right.txt tree/right/right_git.log \
        tree/right/right_guard.tmp tree/right/rl/rl.txt tree/right/rr/rr.txt \
        tree/right/rr/rr_guard.tmp

    if [ "$with_ignore" = "true" ]; then
        echo "*.log" > .gitignore
        echo "*.tmp" > .guardignore
    fi
}

deep_init_guard() {
    "$GUARD_BIN" init 0644 "$(get_current_user)" "$(get_current_group)"
}

deep_txt_files() {
    printf '%s\n' \
        tree/root.txt \
        tree/left/left.txt \
        tree/left/ll/ll.txt \
        tree/left/lr/lr.txt \
        tree/right/right.txt \
        tree/right/rl/rl.txt \
        tree/right/rr/rr.txt
}

deep_gitignored_files() {
    printf '%s\n' \
        tree/root_git.log \
        tree/left/left_git.log \
        tree/left/ll/ll_git.log \
        tree/right/right_git.log
}

deep_guardignored_files() {
    printf '%s\n' \
        tree/root_guard.tmp \
        tree/left/left_guard.tmp \
        tree/left/ll/ll_guard.tmp \
        tree/right/right_guard.tmp \
        tree/right/rr/rr_guard.tmp
}

deep_all_files() {
    deep_txt_files
    deep_gitignored_files
    deep_guardignored_files
}

deep_assert_files_guard_flag() {
    local expected="$1"
    shift

    local file actual
    for file in "$@"; do
        actual=$(get_guard_flag "$file" || true)
        assert_equals "$expected" "$actual" "$file guard flag should be $expected" || return 1
    done
}

deep_assert_files_absent() {
    local file actual
    for file in "$@"; do
        actual=$(get_guard_flag "$file" || true)
        assert_equals "" "$actual" "$file should be absent from .guardfile" || return 1
    done
}

deep_assert_command_files_guard_flag() {
    local expected="$1"
    local command_name="$2"
    shift 2

    local files
    files=()
    while IFS= read -r file; do
        [ -n "$file" ] && files+=("$file")
    done < <("$command_name")

    deep_assert_files_guard_flag "$expected" "${files[@]}"
}

deep_assert_command_files_absent() {
    local command_name="$1"

    local files
    files=()
    while IFS= read -r file; do
        [ -n "$file" ] && files+=("$file")
    done < <("$command_name")

    deep_assert_files_absent "${files[@]}"
}

deep_select_tree_in_tui() {
    tui_start "${1:-80}" "${2:-30}"
    tui_send_keys "Down"
}

deep_expand_tree_left_ll() {
    tui_send_keys "Right"
    tui_send_keys "Down"
    tui_send_keys "Right"
    tui_send_keys "Down"
    tui_send_keys "Right"
}

deep_expand_no_ignore_right_rr_from_ll() {
    local i
    for i in 1 2 3 4 5 6 7 8; do
        tui_send_keys "Down"
    done
    tui_send_keys "Right"
    tui_send_keys "Down"
    tui_send_keys "Down"
    tui_send_keys "Right"
}

deep_expand_default_ignore_right_rr_from_ll() {
    local i
    for i in 1 2 3 4 5; do
        tui_send_keys "Down"
    done
    tui_send_keys "Right"
    tui_send_keys "Down"
    tui_send_keys "Down"
    tui_send_keys "Right"
}
