#!/bin/bash

# test-bug-tui-resize-002.sh - BUG: TUI wastes vertical lines above status bar
#
# The TUI renders 3 blank rows between the last visible file entry and the
# status bar junction line. This is caused by a mismatch between SetSize()
# (which subtracts 3 for borders/title) and ContentLines() (which pads to
# the full height). Since the frame-based rendering path handles borders,
# the subtraction is incorrect and creates wasted space.
#
# This test resizes the terminal in steps of 1 and verifies that the full
# content area is used at each height with no blank lines above the status bar.

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
#
# The junction line starts with "╠". We find it, then count consecutive
# blank-only lines (or lines with only whitespace/box-drawing borders)
# immediately above it within the content area.
# A "blank content line" is a frame row like "║      │      ║" where the
# content portions (between the border characters) are all whitespace.
# ==========================================================================
count_blank_content_lines_above_statusbar() {
    local screen="$1"
    local blank_count=0

    # Convert screen to an array of lines
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
        # Strip the frame border characters (║ and │) and whitespace
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
# Helper: count total visible entries (non-blank content lines)
# ==========================================================================
count_visible_entries() {
    local screen="$1"
    local entry_count=0

    local -a lines
    while IFS= read -r line; do
        lines+=("$line")
    done <<< "$screen"

    local total=${#lines[@]}

    # Find the top border (╔) and junction line (╠)
    local top_idx=-1
    local junction_idx=-1
    for ((i=0; i<total; i++)); do
        if [[ "${lines[$i]}" == *"╔"* ]] && [ "$top_idx" -eq -1 ]; then
            top_idx=$i
        fi
        if [[ "${lines[$i]}" == *"╠"* ]]; then
            junction_idx=$i
            break
        fi
    done

    if [ "$top_idx" -eq -1 ] || [ "$junction_idx" -eq -1 ]; then
        echo "0"
        return
    fi

    # Count non-blank content lines between top border and junction
    for ((i=top_idx+1; i<junction_idx; i++)); do
        local line="${lines[$i]}"
        # Strip the frame border characters and whitespace
        local content=$(echo "$line" | sed 's/[║│╔╗╚╝╠╣╤╧═]//g' | tr -d ' ')
        if [ -n "$content" ]; then
            ((entry_count++))
        fi
    done

    echo "$entry_count"
}

# ==========================================================================
# Test A: Flat files — resize down in steps of 1
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

        # With 32 total entries (root + .guardfile + 30 files), more than enough
        # to fill any content area at these heights, so blank lines = wasted space
        local blanks=$(count_blank_content_lines_above_statusbar "$screen")
        tui_assert_equals "0" "$blanks" \
            "Height $h: no blank lines above status bar (got $blanks)"
    done

    # Cleanup
    tui_stop
}

# ==========================================================================
# Test B: Expanded folder — resize down in steps of 1
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
    # Tree order (sorted): root folder (cursor starts here), then children:
    #   src/ (directories first), .guardfile, root_01..root_10
    # src/ is at position 1 (Down once from root)
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
# Test C: Scrolled position — resize down in steps of 1
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
# Run tests using tui_run_test for proper screenshot support and cleanup
# ==========================================================================
tui_run_test test_resize_flat_files_step_by_1
tui_run_test test_resize_expanded_folder_step_by_1
tui_run_test test_resize_scrolled_step_by_1

print_test_summary 3
