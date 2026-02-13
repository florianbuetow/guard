#!/bin/bash

# test-bug-tui-resize-002b.sh - Resize expanded folder: no blank lines above status bar
#
# Resizes the terminal from height 35 to 15 in steps of 1 with an expanded
# folder and verifies no wasted blank lines at each height.

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
# Test: Expanded folder — resize down in steps of 1
# Verifies no wasted blank lines with folder+file mix
# Total entries when expanded: root + src/ + 20 modules + .guardfile + 10 roots = 33
# ==========================================================================
test_resize_expanded_folder_step_by_1() {
    log_test "test_resize_expanded_folder_step_by_1" \
             "Resize down from 35 to 15 with expanded folder, no blank lines"

    local user=$(get_current_user)
    local group=$(get_current_group)

    # Setup
    $GUARD_BIN init 000 "$user" "$group"

    # Create folder with files inside
    mkdir -p src
    for i in $(seq -w 1 20); do
        touch "src/module_${i}.go"
    done
    # Create root-level files
    for i in $(seq -w 1 10); do
        touch "root_${i}.txt"
    done

    # Start TUI at 80x35
    tui_start 80 35
    sleep 0.3

    # Navigate to src/ folder and expand it
    tui_send_keys "Down"
    # Expand src/ folder
    tui_send_keys "Right"
    sleep 0.3

    # Verify src/ was expanded by checking for a module file
    tui_assert_contains "module_" "src/ folder is expanded and shows module files"

    # Resize down from 35 to 15 in steps of 1
    for h in $(seq 35 -1 15); do
        tui_resize 80 "$h"
        sleep 0.3
        local screen=$(tui_capture)

        # With 33 total entries (more than any content area), all rows should be used
        local blanks=$(count_blank_content_lines_above_statusbar "$screen")
        tui_assert_equals "0" "$blanks" \
            "Height $h (expanded folder): no blank lines above status bar (got $blanks)"
    done

    # Cleanup
    tui_stop
}

# ==========================================================================
# Run test
# ==========================================================================
tui_run_test test_resize_expanded_folder_step_by_1

print_test_summary 1
