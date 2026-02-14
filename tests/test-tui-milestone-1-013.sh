#!/bin/bash

# test-tui-milestone-1-013.sh - CATEGORY 13: UNICODE AND TREE DISPLAY TESTS
# Tests the Text User Interface according to TUI-INTERFACE-SPECS-MILESTONE-1.md
#
# Prerequisites:
# - tmux must be installed (tests will fail if not available)
# - guard binary must be built
#
# Usage:
#   ./tests/test-tui-milestone-1.sh

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
# CATEGORY 13: UNICODE AND TREE DISPLAY TESTS
# ============================================================================
test_tree_collapsed_indicator() {
    log_test "test_tree_collapsed_indicator" \
             "Collapsed folder shows triangle indicator"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    mkdir -p testfolder
    touch testfolder/file.txt

    # Launch TUI
    tui_start

    # Assert: Should show collapsed indicator (▶ or similar)
    local screen=$(tui_capture)
    if [[ "$screen" == *"▶"* ]] || [[ "$screen" == *">"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Collapsed folder indicator visible"
        ((TESTS_PASSED++))
    else
        tui_screenshot "ASSERT_FAIL_collapsed_indicator_not_found"
        echo -e "${RED}✗ FAIL${NC}: Collapsed folder indicator not found"
        echo -e "  Screenshot: $TUI_LAST_SCREENSHOT"
        echo -e "  Screen content (first 20 lines):"
        echo "$screen" | head -20 | sed 's/^/    /'
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_tree_collapsed_indicator
