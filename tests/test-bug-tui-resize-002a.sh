#!/bin/bash

# test-bug-tui-resize-002a.sh - Resize flat files: no blank lines above status bar
#
# Resizes the terminal from height 35 to 15 in steps of 1 with 30 flat files
# and verifies the full content area is used at each height.

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
# Test: Flat files — resize down in steps of 1
# Verifies correct file count and no blank lines at each height
# With 30 files (more than any content area), blank lines = wasted space
# ==========================================================================
test_resize_flat_files_step_by_1() {
    log_test "test_resize_flat_files_step_by_1" \
             "Resize down from 35 to 15 in steps of 1 with 30 flat files"

    local user=$(get_current_user)
    local group=$(get_current_group)

    # Setup
    $GUARD_BIN init 000 "$user" "$group"

    for i in $(seq -w 1 30); do
        touch "file_${i}.txt"
    done

    # Start TUI at 80x35
    tui_start 80 35
    sleep 0.3

    # Resize down from 35 to 15 in steps of 1
    for h in $(seq 35 -1 15); do
        tui_resize 80 "$h"
        sleep 0.3
        local screen=$(tui_capture)

        # Count visible files
        local visible=$(count_visible_files "$screen")

        # Expected visible files = min(30, height - 7)
        # Overhead: top border (1) + junction (1) + 2 status lines + bottom border (1) = 5
        # Tree also shows: root folder entry (1) + .guardfile entry (1) = 2
        # Total overhead from file_XX.txt perspective: 5 + 2 = 7
        local expected=$((h - 7))
        if [ "$expected" -gt 30 ]; then
            expected=30
        fi
        if [ "$expected" -lt 0 ]; then
            expected=0
        fi

        tui_assert_equals "$expected" "$visible" \
            "Height $h: expected $expected visible files, got $visible"

        local blanks=$(count_blank_content_lines_above_statusbar "$screen")
        tui_assert_equals "0" "$blanks" \
            "Height $h: no blank lines above status bar (got $blanks)"
    done

    # Cleanup
    tui_stop
}

# ==========================================================================
# Run test
# ==========================================================================
tui_run_test test_resize_flat_files_step_by_1

print_test_summary 1
