#!/bin/bash

# test-bug-tui-resize-001.sh - BUG: Terminal resize should use full height and not overflow
#
# From docs/todo/BUGS.md:
# "We need to test changing the size of the terminal while the TUI is running:
#  - Verify that when we make it larger, the additional space is used to render the files
#  - Verify that when we make it smaller, the rendering of the files is adjusted and doesn't overflow"
#
# This test resizes the terminal from 20 -> 30 -> 20 and verifies behavior.

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
set -e

# Find guard binary
GUARD_BIN=""
if [ -f "./guard" ]; then
    GUARD_BIN="$(pwd)/guard"
elif command -v guard &> /dev/null; then
    GUARD_BIN="guard"
else
    echo "Error: guard binary not found. Please build it first."
    exit 1
fi

# Check for tmux (required for TUI tests)
if ! tui_check_tmux; then
    exit 1
fi

count_visible_files() {
    local screen="$1"
    local count=0
    for i in $(seq -w 1 30); do
        if echo "$screen" | grep -q "file_${i}.txt"; then
            ((count++))
        fi
    done
    echo "$count"
}

# ==========================================================================
# BUG: Terminal resize behavior gaps
# ==========================================================================

test_tui_resize_uses_height_and_no_overflow() {
    log_test "test_tui_resize_uses_height_and_no_overflow" \
             "Resizing larger shows more files; resizing smaller keeps status bar intact"

    local user=$(get_current_user)
    local group=$(get_current_group)

    # Setup
    $GUARD_BIN init 000 "$user" "$group"

    for i in $(seq -w 1 30); do
        touch "file_${i}.txt"
    done

    # Start small
    tui_start 80 20
    local screen_small=$(tui_capture)
    local count_small=$(count_visible_files "$screen_small")

    # Resize larger
    tui_resize 80 30
    sleep 0.4
    local screen_large=$(tui_capture)
    local count_large=$(count_visible_files "$screen_large")

    if [ "$count_large" -gt "$count_small" ]; then
        echo -e "${GREEN}✓ PASS${NC}: More files visible after resize ($count_small -> $count_large)"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: Resize larger did not show more files ($count_small -> $count_large)"
        echo -e "  Expected more visible files after increasing height"
        ((TESTS_FAILED++))
    fi

    # Resize smaller and ensure no overflow into status bar
    tui_resize 80 20
    sleep 0.4
    local screen_small2=$(tui_capture)
    local last_lines=$(echo "$screen_small2" | tail -n 3)

    if echo "$last_lines" | grep -q "file_"; then
        echo -e "${RED}✗ FAIL${NC}: File list appears to overflow into status bar area"
        echo -e "  Last lines:\n$last_lines"
        ((TESTS_FAILED++))
    else
        echo -e "${GREEN}✓ PASS${NC}: No file overflow into status bar after resize smaller"
        ((TESTS_PASSED++))
    fi

    # Status bar should still be visible
    tui_assert_contains "R: Refresh" "Status bar still visible after resize smaller"

    # Cleanup
    tui_stop
}

# Run test
run_test test_tui_resize_uses_height_and_no_overflow
print_test_summary 1
