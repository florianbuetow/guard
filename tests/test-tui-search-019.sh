#!/bin/bash

# test-tui-search-019.sh - BUG: Search prompt needs left padding
# Tests that the search box prompt has a leading space for visual padding.
# TDD: This test should FAIL until the prompt is changed to " Search: ".

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

if ! tui_check_tmux; then
    exit 1
fi

# ============================================================================
# TEST: Search prompt has leading space
# ============================================================================
test_search_prompt_has_padding() {
    log_test "test_search_prompt_has_padding" \
             "Search box prompt has leading space: ' Search: ' not 'Search: '"

    # Setup
    $GUARD_BIN init 000 flo staff
    touch file1.txt
    $GUARD_BIN add file1.txt

    # Launch TUI
    tui_start

    tui_assert_running "TUI session is active"

    # Activate search
    tui_send_keys "/"
    tui_assert_contains "Search:" "Search box is active"

    # Assert: The prompt should have a leading space
    # The frame renders as: ║ Search: ...... ║
    # So we look for " Search:" (space before Search)
    tui_assert_contains " Search:" "Search prompt has leading space padding"

    # Also verify it's NOT flush against the border
    # The frame border is ║, so flush would be ║Search:
    # With padding it should be ║ Search:
    local screen=$(tui_capture)
    local search_line=$(echo "$screen" | grep "Search:" | head -1)

    # The search line rendered inside the frame should have the space
    # Frame format: ║<content>║ where content starts with a space
    if [[ "$search_line" == *"║Search:"* ]]; then
        tui_fail "Search prompt is flush against frame border (no leading space)"
    fi

    echo -e "${GREEN}✓ PASS${NC}: Search prompt is not flush against frame border"
    ((TESTS_PASSED++))

    # Cleanup
    tui_stop
}

# Run test
run_test test_search_prompt_has_padding
print_test_summary 1
