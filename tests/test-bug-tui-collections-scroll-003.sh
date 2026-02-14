#!/bin/bash

# test-bug-tui-collections-scroll-003.sh - REGRESSION: Collections pane viewport sizing
#
# Regression test for a fixed bug where CollectionTree.SetSize() subtracted 4
# from height for its scroll viewport (height-4), but ContentLines() rendered
# (height) lines — causing blank padding and zero-height viewports at small sizes.
#
# This test creates a nested collection hierarchy and verifies that scrolling
# through all collections works correctly when the content area is only 1 line
# tall (terminal height 6).
#
# Expected collection tree (7 nodes, sorted alphabetically with hierarchy):
#   [G] docs
#   [~] go lang
#   ├─ [~] core
#   │  ├─ [G] folders
#   │  └─ [G] registry
#   [G] tests
#   [-] yaml (empty)
#
# At terminal height 6:
#   contentHeight = 6 - 1 (top border) - 4 (status bar) = 1
#   BUG:  scroll viewport = 1 - 4 = -3 → no items visible
#   FIX:  scroll viewport = 1          → one item visible, scrollable

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

# ==========================================================================
# Helper: set up the nested collection hierarchy
#
# File assignments create subset relationships that produce the hierarchy:
#   folders  {go1, go2}           ⊂ core
#   registry {go3, go4}           ⊂ core
#   core     {go1..go5}           ⊂ go lang
#   go lang  {go1..go6}           (root)
#   docs     {doc1, doc2}         (root)
#   tests    {test1}              (root)
#   yaml     {}                   (root, empty)
#
# Guard states after enabling docs, folders, registry, tests:
#   docs      → guard=true                              → [G]
#   go lang   → guard=false, go1-4 guarded, go5-6 not   → [~]
#   core      → guard=false, go1-4 guarded, go5 not     → [~]
#   folders   → guard=true                              → [G]
#   registry  → guard=true                              → [G]
#   tests     → guard=true                              → [G]
#   yaml      → empty, guard=false                      → [-]
# ==========================================================================
setup_nested_collections() {
    local user=$(get_current_user)
    local group=$(get_current_group)

    # Initialize guard
    $GUARD_BIN init 000 "$user" "$group"

    # Create test files
    touch doc1.txt doc2.txt
    touch go1.go go2.go go3.go go4.go go5.go go6.go
    touch test1.sh

    # Register all files
    $GUARD_BIN add doc1.txt doc2.txt \
        go1.go go2.go go3.go go4.go go5.go go6.go \
        test1.sh

    # Create collections (including empty "yaml")
    $GUARD_BIN create docs "go lang" core folders registry tests yaml

    # Build file-to-collection memberships that create the hierarchy
    $GUARD_BIN update docs add doc1.txt doc2.txt
    $GUARD_BIN update "go lang" add go1.go go2.go go3.go go4.go go5.go go6.go
    $GUARD_BIN update core add go1.go go2.go go3.go go4.go go5.go
    $GUARD_BIN update folders add go1.go go2.go
    $GUARD_BIN update registry add go3.go go4.go
    $GUARD_BIN update tests add test1.sh

    # Enable guard on specific collections → sets collection guard=true
    # and enables guard on their member files
    $GUARD_BIN enable docs folders registry tests
}

# ==========================================================================
# Test: Scroll through all 7 collections at viewport size 1
#
# At height 6, only 1 content line is available. With the bug, the scroll
# viewport is -3 so nothing renders. After fix, viewport=1 and each
# Down/Up press shows the next/previous collection.
# ==========================================================================
test_collections_scroll_viewport_1() {
    log_test "test_collections_scroll_viewport_1" \
             "Scroll through 7 nested collections with content area = 1 line"

    setup_nested_collections

    # Start TUI at height 6 (minimum for 1 content line)
    tui_start 80 6

    # Switch focus to collections pane
    tui_send_keys "Tab"

    # --- Scroll DOWN through all 7 collections ---

    # Position 0 (initial): [G] docs
    tui_assert_row_contains 2 "[G] docs" \
        "Pos 0: shows [G] docs"

    # Position 1: [~] go lang
    tui_send_keys "Down"
    tui_assert_row_contains 2 "[~] go lang" \
        "Pos 1: shows [~] go lang"

    # Position 2: core (child of go lang, with tree prefix)
    tui_send_keys "Down"
    tui_assert_row_contains 2 "[~] core" \
        "Pos 2: shows [~] core"

    # Position 3: folders (child of core, with tree prefix)
    tui_send_keys "Down"
    tui_assert_row_contains 2 "[G] folders" \
        "Pos 3: shows [G] folders"

    # Position 4: registry (child of core, with tree prefix)
    tui_send_keys "Down"
    tui_assert_row_contains 2 "[G] registry" \
        "Pos 4: shows [G] registry"

    # Position 5: [G] tests
    tui_send_keys "Down"
    tui_assert_row_contains 2 "[G] tests" \
        "Pos 5: shows [G] tests"

    # Position 6: yaml (empty)
    tui_send_keys "Down"
    tui_assert_row_contains 2 "yaml" \
        "Pos 6: shows yaml"
    tui_assert_row_contains 2 "(empty)" \
        "Pos 6: yaml shows (empty) indicator"

    # Verify cursor stops at end (pressing Down again stays on yaml)
    tui_send_keys "Down"
    tui_assert_row_contains 2 "yaml" \
        "Past end: still shows yaml"

    # --- Scroll UP back through all positions ---

    tui_send_keys "Up"
    tui_assert_row_contains 2 "[G] tests" \
        "Up to pos 5: shows [G] tests"

    tui_send_keys "Up"
    tui_assert_row_contains 2 "[G] registry" \
        "Up to pos 4: shows [G] registry"

    tui_send_keys "Up"
    tui_assert_row_contains 2 "[G] folders" \
        "Up to pos 3: shows [G] folders"

    tui_send_keys "Up"
    tui_assert_row_contains 2 "[~] core" \
        "Up to pos 2: shows [~] core"

    tui_send_keys "Up"
    tui_assert_row_contains 2 "[~] go lang" \
        "Up to pos 1: shows [~] go lang"

    tui_send_keys "Up"
    tui_assert_row_contains 2 "[G] docs" \
        "Up to pos 0: shows [G] docs"

    # Verify cursor stops at beginning
    tui_send_keys "Up"
    tui_assert_row_contains 2 "[G] docs" \
        "Past start: still shows [G] docs"

    # Cleanup
    tui_stop
}

# ==========================================================================
# Run test
# ==========================================================================
tui_run_test test_collections_scroll_viewport_1
print_test_summary 1
