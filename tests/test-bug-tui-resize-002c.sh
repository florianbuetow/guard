#!/bin/bash

# test-bug-tui-resize-002c.sh - Resize while scrolled: no blank lines above status bar
#
# Resizes the terminal from height 20 to 12 while scrolled partway into the
# list and verifies no blank lines at each height.

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

# ==========================================================================
# Helper: count visible file_XX.txt entries on screen
# ==========================================================================
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
# Helper: count blank content lines immediately above the status bar junction
# ==========================================================================
count_blank_content_lines_above_statusbar() {
    local screen="$1"
    local blank_count=0

    local -a lines
    while IFS= read -r line; do
        lines+=("$line")
    done <<< "$screen"

    local total=${#lines[@]}

    # Find the junction line (╠)
    local junction_idx=-1
    for ((i=0; i<total; i++)); do
        if [[ "${lines[$i]}" == *"╠"* ]]; then
            junction_idx=$i
            break
        fi
    done

    if [ "$junction_idx" -le 0 ]; then
        echo "0"
        return
    fi

    # Walk upward from junction, counting blank content rows
    for ((i=junction_idx-1; i>=1; i--)); do
        local line="${lines[$i]}"
        local content=$(echo "$line" | sed 's/[║│╔╗╚╝╠╣╤╧═]//g' | tr -d ' ')
        if [ -z "$content" ]; then
            ((blank_count++))
        else
            break
        fi
    done

    echo "$blank_count"
}

# ==========================================================================
# Test: Scrolled position — resize down in steps of 1
# Verifies no blank lines when viewport is scrolled partway into the list
# ==========================================================================
test_resize_scrolled_step_by_1() {
    log_test "test_resize_scrolled_step_by_1" \
             "Resize down from 20 to 12 while scrolled, no blank lines"

    local user=$(get_current_user)
    local group=$(get_current_group)

    # Setup
    $GUARD_BIN init 000 "$user" "$group"

    for i in $(seq -w 1 30); do
        touch "file_${i}.txt"
    done

    # Start TUI at 80x20
    tui_start 80 20
    sleep 0.3

    # Scroll down ~15 times to move viewport into the middle of the list
    for i in $(seq 1 15); do
        tui_send_keys "Down"
    done
    sleep 0.3

    # Resize down from 20 to 12 in steps of 1
    for h in $(seq 20 -1 12); do
        tui_resize 80 "$h"
        sleep 0.3
        local screen=$(tui_capture)

        # With 32 total entries and viewport scrolled partway, all rows should be used
        local blanks=$(count_blank_content_lines_above_statusbar "$screen")
        tui_assert_equals "0" "$blanks" \
            "Height $h (scrolled): no blank lines above status bar (got $blanks)"

        # Verify we still see some files (content area is being used)
        local visible=$(count_visible_files "$screen")
        if [ "$visible" -eq 0 ]; then
            tui_screenshot "no_visible_files_h${h}"
            echo -e "${RED}✗ FAIL${NC}: Height $h: no visible files at all"
            tui_cleanup
            exit 1
        fi
        echo -e "${GREEN}✓ PASS${NC}: Height $h (scrolled): $visible files visible, content area used"
        ((TESTS_PASSED++))
    done

    # Cleanup
    tui_stop
}

# ==========================================================================
# Run test
# ==========================================================================
tui_run_test test_resize_scrolled_step_by_1

print_test_summary 1
