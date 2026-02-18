#!/bin/bash

# test-tui-guardignore-009.sh - Gitignored files and folders render in light blue color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
set -e

find_guard_binary

if ! tui_check_tmux; then
    exit 1
fi

# ANSI 256-color code for the gitignored/light blue color.
# This must match ColorIgnored in internal/tui/styles.go.
# 38;5;117 = light sky blue (ANSI 256-color palette)
ANSI_LIGHT_BLUE="38;5;117"

test_tui_gitignored_items_render_in_light_blue() {
    log_test "test_tui_gitignored_items_render_in_light_blue" \
             "Gitignored files and folders should render in light blue, non-ignored should not"

    # Setup: a gitignored folder with a registered file, plus a normal file
    mkdir -p vendor
    touch vendor/lib.go
    touch main.go
    echo 'vendor/' > .gitignore

    "$GUARD_BIN" init 0644 "$(get_current_user)" "$(get_current_group)"
    "$GUARD_BIN" add main.go
    "$GUARD_BIN" add --force vendor/lib.go

    tui_start

    # Both items should be visible
    tui_assert_contains 'main.go' 'non-ignored file should be visible'
    tui_assert_contains 'vendor' 'gitignored folder with registered file should be visible'

    # Find which rows contain vendor/ and main.go
    local screen
    screen=$(tui_capture)
    local vendor_row=$(echo "$screen" | grep -n 'vendor' | head -1 | cut -d: -f1)
    local main_row=$(echo "$screen" | grep -n 'main.go' | head -1 | cut -d: -f1)

    # Gitignored folder should have light blue ANSI code
    tui_assert_row_has_ansi_code "$vendor_row" "$ANSI_LIGHT_BLUE" \
        "gitignored folder vendor/ should render in light blue"

    # Non-ignored file should NOT have light blue ANSI code
    tui_assert_row_no_ansi_code "$main_row" "$ANSI_LIGHT_BLUE" \
        "non-ignored file main.go should NOT render in light blue"

    # Expand vendor/ and check the gitignored registered file inside
    # Navigate to vendor row first
    local current_row=1
    while [ "$current_row" -lt "$vendor_row" ]; do
        tui_send_keys "Down"
        ((current_row++))
    done
    tui_send_keys "Right"

    # Re-capture after expansion
    screen=$(tui_capture)
    local lib_row=$(echo "$screen" | grep -n 'lib.go' | head -1 | cut -d: -f1)

    # Gitignored registered file should also render in light blue
    tui_assert_row_has_ansi_code "$lib_row" "$ANSI_LIGHT_BLUE" \
        "gitignored registered file vendor/lib.go should render in light blue"

    tui_stop
}

tui_run_test test_tui_gitignored_items_render_in_light_blue
