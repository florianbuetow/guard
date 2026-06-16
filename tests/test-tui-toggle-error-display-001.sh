#!/bin/bash

# test-tui-toggle-error-display-001.sh
# A failed toggle (chgrp to a group the current user is not a member of) must
# surface as a CENTERED OVERLAY modal -- never as text appended below the
# panels -- and must dismiss on any key, redrawing the tree underneath.
#
# Centering is verified geometrically and independently of the message height.
# The overlay is the only box-drawing rectangle that does NOT touch the viewport
# edges (the panel frame owns row 0, the last row, column 0 and the last column).
# We take the bounding box of the interior box-corners and require:
#   - vertical:   rows above the top border  == rows below the bottom border  (+/-1)
#   - horizontal: cols left of the left side == cols right of the right side  (+/-1)
# The +/-1 tolerance allows an odd amount of leftover space to split as n / n+1.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers-cli.sh"
source "$SCRIPT_DIR/helpers-tui.sh"
set -e

find_guard_binary

if ! tui_check_tmux; then
    exit 1
fi

# Skip if running as root -- root can chgrp to any group, so the toggle would
# succeed and there would be no error to display.
if [ "$(id -u)" -eq 0 ]; then
    echo "Skipping: test requires non-root user to trigger chgrp failure"
    exit 0
fi

# A group that EXISTS but the current user is NOT a member of, so chgrp fails.
TARGET_GROUP="wheel"
if ! getent group "$TARGET_GROUP" >/dev/null 2>&1 && ! dscl . -read /Groups/"$TARGET_GROUP" >/dev/null 2>&1; then
    echo "Skipping: group '$TARGET_GROUP' does not exist on this system"
    exit 0
fi
if id -Gn | tr ' ' '\n' | grep -qx "$TARGET_GROUP"; then
    echo "Skipping: current user is a member of '$TARGET_GROUP' (chgrp would succeed)"
    exit 0
fi

# Assert the error overlay box is centered on a WIDTH x HEIGHT viewport.
# Usage: assert_overlay_centered <screen> <width> <height> <message>
assert_overlay_centered() {
    local screen="$1" width="$2" height="$3" message="$4"
    local report rc
    report=$(printf '%s\n' "$screen" | GW="$width" GH="$height" perl -CSD -e '
        my ($W, $H) = ($ENV{GW}, $ENV{GH});
        my @rows; while (my $l = <STDIN>) { chomp $l; push @rows, $l; }
        # double- and rounded-corner glyphs that mark a box rectangle
        my $corner = qr/[\x{2554}\x{2557}\x{255A}\x{255D}\x{256D}\x{256E}\x{2570}\x{256F}]/;
        my (@rs, @cs);
        for my $r (0 .. $H - 1) {
            my @ch = split //, ($r <= $#rows ? $rows[$r] : "");
            for my $c (0 .. $#ch) {
                next unless $ch[$c] =~ $corner;
                next unless $r > 0 && $r < $H - 1 && $c > 0 && $c < $W - 1;
                push @rs, $r; push @cs, $c;
            }
        }
        if (@rs < 4) { print "no centered overlay box (interior corners found: " . scalar(@rs) . ")"; exit 1; }
        @rs = sort { $a <=> $b } @rs; @cs = sort { $a <=> $b } @cs;
        my ($rt, $rb, $cl, $cr) = ($rs[0], $rs[-1], $cs[0], $cs[-1]);
        my ($top, $bottom) = ($rt, ($H - 1) - $rb);
        my ($left, $right) = ($cl, ($W - 1) - $cr);
        printf "vertical top=%d bottom=%d (diff %d); horizontal left=%d right=%d (diff %d)",
               $top, $bottom, abs($top - $bottom), $left, $right, abs($left - $right);
        exit((abs($top - $bottom) <= 1 && abs($left - $right) <= 1 && $rb > $rt && $cr > $cl) ? 0 : 2);
    ')
    rc=$?
    if [ "$rc" -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $message"
        echo "    $report"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: $message"
        echo "    ${report:-overlay geometry could not be parsed}"
        tui_screenshot "ASSERT_FAIL_overlay_centered"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

test_tui_toggle_error_is_centered_overlay() {
    log_test "test_tui_toggle_error_is_centered_overlay" \
             "Failed toggle shows a centered overlay modal, dismissed by any key"

    $GUARD_BIN init 0700 "$(get_current_user)" "$TARGET_GROUP"
    echo "content" > target.txt

    tui_start
    tui_assert_running "TUI session is active"
    tui_assert_contains "target.txt" "File tree shows target.txt"

    # Move the cursor to target.txt (it starts on the root) and toggle it.
    tui_send_keys "j"
    tui_send_keys "j"
    tui_send_keys " "
    sleep 1.5

    # The failure must surface as a visible error...
    tui_assert_contains "Error" "Failed toggle raises an error modal"
    # ...rendered as a centered overlay, NOT appended below the panels.
    assert_overlay_centered "$(tui_capture)" "$TUI_DEFAULT_WIDTH" "$TUI_DEFAULT_HEIGHT" \
        "Error modal is a centered overlay (vertically and horizontally)"

    # Any key dismisses the overlay and the tree is redrawn without it.
    tui_send_keys "x"
    sleep 0.5
    tui_assert_not_contains "Press any key to dismiss" "Any key dismisses the overlay"
    tui_assert_contains "target.txt" "Tree is redrawn after the overlay is dismissed"

    tui_stop
}

run_test test_tui_toggle_error_is_centered_overlay
print_test_summary 1
