#!/bin/bash

# test-tui-milestone-1-005.sh - CATEGORY 5: FILES PANEL GUARD TOGGLE TESTS
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
# CATEGORY 5: FILES PANEL GUARD TOGGLE TESTS
# ============================================================================
test_file_toggle_unregistered() {
    log_test "test_file_toggle_unregistered" \
             "Toggle on unregistered file registers and guards it"

    # Setup
    $GUARD_BIN init 000 "$(get_current_user)" "$(get_current_group)"
    touch newfile.txt
    chmod 644 newfile.txt  # Set explicit initial permissions
    # Don't add to registry

    # Verify initial permissions before TUI
    assert_file_permissions "$(pwd)/newfile.txt" "644" "File starts with 644 permissions"

    # Launch TUI
    tui_start

    # Navigate to the file (from root folder)
    # Root folder is first, then children are sorted: .guardfile, newfile.txt
    # Navigate: Down to .guardfile, Down to newfile.txt
    tui_send_keys "Down"
    tui_send_keys "Down"

    # Toggle the unregistered file
    tui_send_keys "Space"

    # Wait a bit for the .guardfile to be written
    sleep 0.3

    # Capture screen before stopping
    local screen=$(tui_capture)

    # Stop TUI to verify .guardfile
    tui_stop

    # Assert: File should now be in registry and guarded
    if file_in_registry "$(pwd)/newfile.txt"; then
        echo -e "${GREEN}✓ PASS${NC}: File registered after toggle"
        ((TESTS_PASSED++))
    else
        tui_screenshot "ASSERT_FAIL_file_not_registered"
        echo -e "${RED}✗ FAIL${NC}: File not registered after toggle"
        echo -e "  Screenshot: $TUI_LAST_SCREENSHOT"
        tui_finalize_screenshots "FAIL"
        tui_cleanup
        exit 1
    fi

    local guard_flag=$(get_guard_flag "$(pwd)/newfile.txt")
    tui_assert_equals "true" "$guard_flag" "File should be guarded after toggle"

    # Verify permissions changed to 000 when guarded
    assert_file_permissions "$(pwd)/newfile.txt" "000" "File permissions should be 000 when guarded"
}

# Run test
tui_run_test test_file_toggle_unregistered
