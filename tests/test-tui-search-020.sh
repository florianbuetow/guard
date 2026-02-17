#!/bin/bash

# test-tui-search-020.sh - BUG: Panel titles should not have bullet prefixes
# Tests that panel titles use highlight styling instead of ● / ○ bullet characters.
# TDD: This test should FAIL until bullets are removed and styling is applied.

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
# TEST: Panel titles have no bullet prefixes
# ============================================================================
test_no_bullet_in_titles() {
    log_test "test_no_bullet_in_titles" \
             "Panel titles do not have ● or ○ bullet prefixes"

    # Setup
    $GUARD_BIN init 000 flo staff
    touch file1.txt
    $GUARD_BIN add file1.txt

    # Launch TUI
    tui_start

    tui_assert_running "TUI session is active"

    # Assert: No bullet characters anywhere in the top border
    tui_assert_not_contains "●" "No filled bullet ● in panel titles"
    tui_assert_not_contains "○" "No empty bullet ○ in panel titles"

    # Assert: Panel titles are still present (without bullets)
    tui_assert_contains "Files" "Files title is present"
    tui_assert_contains "Collections" "Collections title is present"

    # Assert: The active panel (Files by default) has bold styling
    # Bold ANSI code is \e[1m — check the ANSI capture for it on the top border row
    local screen_ansi=$(tui_capture_ansi)
    local top_row=$(echo "$screen_ansi" | head -1)

    # The top row should contain bold ANSI code for the active title
    if [[ "$top_row" == *$'\e[7m'* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Active panel title has reverse video styling"
        ((TESTS_PASSED++))
    else
        tui_fail "Active panel title does not have reverse video ANSI styling on top border"
    fi

    # Switch to Collections panel
    tui_send_keys Tab

    # Still no bullets
    tui_assert_not_contains "●" "No filled bullet after Tab switch"
    tui_assert_not_contains "○" "No empty bullet after Tab switch"

    # Cleanup
    tui_stop
}

# Run test
run_test test_no_bullet_in_titles
print_test_summary 1
