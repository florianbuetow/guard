#!/bin/bash

# test-tui-search-012.sh - BUG: Fuzzy search does not match folder names
# Tests that searching for a folder name shows the folder in results.
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
# TEST: Fuzzy search matches folder names
# ============================================================================
test_search_matches_folders() {
    log_test "test_search_matches_folders" \
             "Fuzzy search matches folder names and shows them in results"

    # Setup: Initialize guard with files in a subdirectory
    $GUARD_BIN init 000 flo staff
    mkdir -p tests
    touch tests/foo.txt tests/bar.txt
    touch readme.md
    $GUARD_BIN add tests/foo.txt tests/bar.txt readme.md

    # Launch TUI
    tui_start

    # Assert: folder and file visible before search
    tui_assert_contains "tests/" "tests/ folder visible before search"
    tui_assert_contains "readme.md" "readme.md visible before search"

    # Action: Search for the folder name
    tui_send_keys "/"
    tui_type "tests"

    # Assert: tests/ folder is visible (matched by name)
    tui_assert_contains "tests/" "tests/ folder visible after searching for 'tests'"

    # Assert: unrelated file is hidden
    tui_assert_not_contains "readme.md" "readme.md hidden after searching for 'tests'"

    # Cleanup
    tui_stop
}

# Run test
run_test test_search_matches_folders
print_test_summary 1
