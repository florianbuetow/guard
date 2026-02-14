#!/bin/bash

# test-tui-milestone-1-018.sh - CATEGORY 18: INITIAL STATE (NEW)
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
# CATEGORY 18: INITIAL STATE (NEW)
# ============================================================================
test_initial_folders_collapsed() {
    log_test "test_initial_folders_collapsed" \
             "All folders are collapsed by default (Spec line 111)"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    mkdir -p folder1/subfolder
    mkdir -p folder2
    touch folder1/file.txt folder1/subfolder/nested.txt folder2/file2.txt

    # Launch TUI
    tui_start

    # Assert: Should show collapsed indicator for folders
    local screen=$(tui_capture)
    if [[ "$screen" == *"▶"* ]] || [[ "$screen" == *">"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Collapsed folder indicator visible"
        ((TESTS_PASSED++))
    else
        tui_screenshot "ASSERT_FAIL_no_collapsed_indicator"
        echo -e "${RED}✗ FAIL${NC}: No collapsed folder indicator found"
        echo -e "  Screenshot: $TUI_LAST_SCREENSHOT"
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi

    # Assert: Nested files should NOT be visible (folders collapsed)
    tui_assert_not_contains "nested.txt" "Nested file not visible (folder collapsed)"

    # Assert: Immediate children should also not be visible
    tui_assert_not_contains "file.txt" "Children not visible (folders collapsed)"

    # Cleanup
    tui_stop
}

# Run test
tui_run_test test_initial_folders_collapsed
