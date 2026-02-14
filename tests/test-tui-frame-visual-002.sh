#!/bin/bash

# test-tui-frame-visual-002.sh - PANEL SEPARATOR ALIGNMENT TESTS
# Tests verify the double-line frame characters and embedded panel names
# as specified in TUI-INTERFACE-SPECS-MILESTONE-1.md
#
# Prerequisites:
# - tmux must be installed
# - guard binary must be built
#
# Usage:
#   ./tests/test-tui-frame-visual.sh

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
set -e

# Find guard binary
find_guard_binary

# Check for tmux (required for TUI tests)
if ! tui_check_tmux; then
    exit 1
fi

# ============================================================================
# PANEL SEPARATOR ALIGNMENT TESTS
# ============================================================================
test_tui_frame_separator_alignment_even_width() {
    log_test "test_tui_frame_separator_alignment_even_width" \
             "Panel separator aligns correctly with even terminal width (80)"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch file1.txt
    $GUARD_BIN add file file1.txt

    # Launch TUI with even width (80)
    tui_start 80 25

    # Capture screen
    local screen=$(tui_capture)

    # Get the top border (row 1) and find the character position of ╤
    # Use bash parameter expansion to get prefix before the character
    local top_border=$(echo "$screen" | sed -n '1p')
    local top_prefix="${top_border%%╤*}"
    local junction_pos_top=${#top_prefix}

    # Get a content row (row 2) and find the character position of │
    local content_row=$(echo "$screen" | sed -n '2p')
    local content_prefix="${content_row%%│*}"
    local separator_pos=${#content_prefix}

    # Get the status bar junction (row with ╧) and find the character position
    local junction_row=$(echo "$screen" | grep '╧')
    local junction_prefix="${junction_row%%╧*}"
    local junction_pos_bottom=${#junction_prefix}

    # Verify all three align
    if [ "$junction_pos_top" = "$separator_pos" ] && [ "$separator_pos" = "$junction_pos_bottom" ]; then
        echo -e "${GREEN}✓ PASS${NC}: Panel separator aligns at position $separator_pos (even width 80)"
        ((TESTS_PASSED++))
    else
        tui_screenshot "ASSERT_FAIL_separator_alignment_even"
        echo -e "${RED}✗ FAIL${NC}: Panel separator misaligned"
        echo -e "  Top junction (╤) position: $junction_pos_top"
        echo -e "  Content separator (│) position: $separator_pos"
        echo -e "  Bottom junction (╧) position: $junction_pos_bottom"
        echo -e "  Screenshot: $TUI_LAST_SCREENSHOT"
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_tui_frame_separator_alignment_even_width
