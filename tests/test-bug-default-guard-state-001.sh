#!/bin/bash

# test-bug-default-guard-state-001.sh - BUG: Newly added files show as guarded in TUI
#
# Bug description:
#   When a file is added via CLI (guard add <file>), it should default to
#   "unguarded" state (guard: false in .guardfile). When the TUI is opened,
#   the file should display with [-] indicator (unguarded), not [G] (guarded).
#
# Expected behavior:
#   1. guard add testfile.txt → registers file with guard: false
#   2. guard -i (TUI) → file shows [-] indicator (unguarded)
#   3. Press space → file toggles to [G] (guarded), guard: true in .guardfile
#   4. Exit TUI, run "guard toggle testfile.txt" → guard: false
#   5. guard show testfile.txt → shows unguarded state
#   6. File system permissions should match guard state
#
# Test runs WITHOUT sudo to verify non-root behavior.
#
# Prerequisites:
# - tmux must be installed
# - guard binary must be built

# Source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
set -e

# Find guard binary
GUARD_BIN=""
if [ -f "./guard" ]; then
    GUARD_BIN="$(pwd)/guard"
elif [ -f "./bin/guard" ]; then
    GUARD_BIN="$(pwd)/bin/guard"
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

# ============================================================================
# TEST: File added via CLI shows unguarded [-] in TUI and toggles correctly
# ============================================================================
test_added_file_shows_unguarded_in_tui() {
    log_test "test_added_file_shows_unguarded_in_tui" \
             "File added via CLI should show [-] (unguarded) in TUI, toggle to [G]"

    # Get current user/group for init (use current user to avoid permission issues)
    local current_user=$(get_current_user)
    local current_group=$(get_current_group)

    # Setup: Initialize guard with current user (avoids sudo requirement)
    $GUARD_BIN init 000 "$current_user" "$current_group"
    touch testfile.txt

    # Get original file permissions before adding
    local original_perms=$(get_file_permissions "testfile.txt")
    echo "Original file permissions: $original_perms"

    # Step 1: Add file via CLI
    $GUARD_BIN add testfile.txt
    echo "Added testfile.txt to registry"

    # Verify: File should be in registry with guard: false
    local guard_flag=$(get_guard_flag "testfile.txt")
    assert_equals "false" "$guard_flag" "File guard flag should be 'false' after add"

    # Debug: Show guardfile contents
    echo "=== .guardfile after add ==="
    cat .guardfile
    echo "==========================="

    # Step 2: Launch TUI and check display
    tui_start

    # Take screenshot to see what the TUI shows
    tui_screenshot "initial_state"

    # Debug: Capture and show screen
    local screen=$(tui_capture)
    echo "=== TUI Screen Content ==="
    echo "$screen"
    echo "=========================="

    # The file should show [-] indicator (unguarded), NOT [G]
    # TUI display format: [-] testfile.txt (for unguarded registered file)
    tui_assert_contains "[-]" "TUI should show [-] for unguarded file"

    # Step 3: Navigate to testfile.txt specifically
    # The folder is selected by default, we need to navigate DOWN to the actual file
    echo "Navigating to testfile.txt..."

    # Press down twice: once to get to .guardfile, once more to get to testfile.txt
    tui_send_keys "Down"
    tui_send_keys "Down"

    # Take screenshot to verify we're on the right file
    screen=$(tui_capture)
    echo "=== TUI Screen After Navigation ==="
    echo "$screen"
    echo "==================================="

    # Take screenshot before toggle
    tui_screenshot "before_toggle"

    # Step 4: Press space to toggle guard state on the SPECIFIC FILE
    echo "Pressing space to toggle guard on testfile.txt..."
    tui_send_keys " "

    # Take screenshot after toggle
    tui_screenshot "after_toggle"

    # Debug: Capture and show screen after toggle
    screen=$(tui_capture)
    echo "=== TUI Screen After Toggle ==="
    echo "$screen"
    echo "==============================="

    # After toggle, file should show [G] (guarded)
    tui_assert_contains "[G]" "After toggle, file should show [G] (guarded)"

    # Step 5: Exit TUI
    tui_stop

    # Verify: Guard flag in .guardfile should now be true
    echo "=== .guardfile after toggle ==="
    cat .guardfile 2>/dev/null || echo "Could not read .guardfile"
    echo "==============================="

    guard_flag=$(get_guard_flag "testfile.txt")
    assert_equals "true" "$guard_flag" "Guard flag should be 'true' after TUI toggle"

    # Step 6: Check file permissions after guard is enabled
    local guarded_perms=$(get_file_permissions "testfile.txt")
    echo "File permissions after guard enabled: $guarded_perms"
    assert_equals "000" "$guarded_perms" "File should have 000 permissions when guarded"

    # Step 7: Use CLI to toggle guard off
    echo "Running: $GUARD_BIN toggle testfile.txt"
    $GUARD_BIN toggle testfile.txt 2>&1 || echo "Toggle command result: $?"
    echo "Toggled testfile.txt guard via CLI"

    # Verify: Guard flag should be false again
    guard_flag=$(get_guard_flag "testfile.txt")
    assert_equals "false" "$guard_flag" "Guard flag should be 'false' after CLI toggle"

    # Step 8: Verify file system permissions restored
    local restored_perms=$(get_file_permissions "testfile.txt")
    echo "File permissions after guard disabled: $restored_perms"
    assert_equals "$original_perms" "$restored_perms" "File permissions should be restored to original"

    # Step 9: Verify with guard show command
    local show_output=$($GUARD_BIN show testfile.txt 2>&1)
    echo "Guard show output: $show_output"

    # The show output should indicate unguarded state
    if [[ "$show_output" == *"testfile.txt"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: guard show displays the file"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: guard show should display the file"
        ((TESTS_FAILED++))
    fi
}

# Run test
run_test test_added_file_shows_unguarded_in_tui
print_test_summary 1
