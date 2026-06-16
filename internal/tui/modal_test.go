package tui

import (
	"strings"
	"testing"

	"github.com/charmbracelet/x/ansi"
)

// boxCornerRunes are the four DoubleBorder corners that mark a rendered modal.
const boxCornerRunes = "╔╗╚╝"

// interiorCorners parses a composited screen and returns the bounding box of all
// box-drawing corners that do NOT touch the viewport edges, mirroring the
// geometry check in tests/test-tui-toggle-error-display-001.sh. It returns the
// top/bottom/left/right margins of that bounding box and the number of interior
// corners found.
func interiorCorners(screen string, width, height int) (top, bottom, left, right, count int) {
	lines := strings.Split(screen, "\n")
	minR, maxR, minC, maxC := height, -1, width, -1
	for r := range height {
		if r >= len(lines) {
			break
		}
		runes := []rune(ansi.Strip(lines[r]))
		for c, ch := range runes {
			if !strings.ContainsRune(boxCornerRunes, ch) {
				continue
			}
			if r <= 0 || r >= height-1 || c <= 0 || c >= width-1 {
				continue // viewport-edge corner, excluded
			}
			count++
			if r < minR {
				minR = r
			}
			if r > maxR {
				maxR = r
			}
			if c < minC {
				minC = c
			}
			if c > maxC {
				maxC = c
			}
		}
	}
	if count == 0 {
		return 0, 0, 0, 0, 0
	}
	return minR, (height - 1) - maxR, minC, (width - 1) - maxC, count
}

func abs(n int) int {
	if n < 0 {
		return -n
	}
	return n
}

func TestModalRenderIsCentered(t *testing.T) {
	styles := DefaultStyles()
	cases := []struct {
		name string
		w, h int
		text string
	}{
		{"standard 80x30", 80, 30, "permission denied"},
		{"small 40x20", 40, 20, "chgrp failed"},
		{"large 120x50", 120, 50, "operation not permitted on /tmp/x"},
		{"multiline body", 80, 30, "line one\nline two\nline three\nline four"},
		{"long wrapping body", 80, 30, strings.Repeat("verylongtoken ", 30)},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			box := NewModal("Error", tc.text, styles).Render(tc.w, tc.h)

			if box.Height != len(box.Rows) {
				t.Fatalf("Height %d != len(Rows) %d", box.Height, len(box.Rows))
			}
			if box.Width <= 0 || box.Height <= 0 {
				t.Fatalf("degenerate box: %dx%d", box.Width, box.Height)
			}
			if box.Width > tc.w {
				t.Errorf("box width %d exceeds screen width %d (no wrap)", box.Width, tc.w)
			}

			// The box must fit so the centering invariant is meaningful.
			if box.Width > tc.w || box.Height > tc.h {
				t.Fatalf("box %dx%d does not fit screen %dx%d", box.Width, box.Height, tc.w, tc.h)
			}

			// Margins must be balanced within 1 (odd leftover splits as n / n+1).
			topMargin := box.Y
			bottomMargin := tc.h - (box.Y + box.Height)
			leftMargin := box.X
			rightMargin := tc.w - (box.X + box.Width)

			if d := abs(topMargin - bottomMargin); d > 1 {
				t.Errorf("vertical not centered: top=%d bottom=%d diff=%d", topMargin, bottomMargin, d)
			}
			if d := abs(leftMargin - rightMargin); d > 1 {
				t.Errorf("horizontal not centered: left=%d right=%d diff=%d", leftMargin, rightMargin, d)
			}
			// Interior: corners must not sit on the viewport edge.
			if box.X < 1 || box.Y < 1 {
				t.Errorf("box not interior: X=%d Y=%d", box.X, box.Y)
			}

			stripped := ansi.Strip(strings.Join(box.Rows, "\n"))
			if !strings.Contains(stripped, "Error") {
				t.Errorf("rendered modal missing title %q in:\n%s", "Error", stripped)
			}
		})
	}
}

func TestModalRenderMultilineGrowsHeight(t *testing.T) {
	styles := DefaultStyles()
	one := NewModal("Error", "single", styles).Render(80, 30)
	many := NewModal("Error", "a\nb\nc\nd\ne", styles).Render(80, 30)
	if many.Height <= one.Height {
		t.Errorf("multiline modal (%d rows) should be taller than single-line (%d rows)", many.Height, one.Height)
	}
}

func TestModalRenderTinyScreenClamps(t *testing.T) {
	styles := DefaultStyles()
	// Screen smaller than the smallest possible box: must clamp, not panic.
	box := NewModal("Error", "boom", styles).Render(6, 3)
	if box.X < 0 || box.Y < 0 {
		t.Errorf("position not clamped: X=%d Y=%d", box.X, box.Y)
	}
	if len(box.Rows) == 0 {
		t.Errorf("expected non-empty rows even on a tiny screen")
	}
}

func TestOverlayCenteredProducesCenteredInteriorBox(t *testing.T) {
	styles := DefaultStyles()
	const w, h = 80, 30
	// A full-screen base of dots: the only box corners will be the modal's.
	baseLine := strings.Repeat(".", w)
	base := strings.Repeat(baseLine+"\n", h-1) + baseLine

	box := NewModal("Error", "permission denied\n\nPress any key to dismiss", styles).Render(w, h)
	screen := OverlayCentered(base, box, w, h)

	top, bottom, left, right, count := interiorCorners(screen, w, h)
	if count < 4 {
		t.Fatalf("expected >=4 interior corners, found %d:\n%s", count, ansi.Strip(screen))
	}
	if d := abs(top - bottom); d > 1 {
		t.Errorf("vertical not centered: top=%d bottom=%d diff=%d", top, bottom, d)
	}
	if d := abs(left - right); d > 1 {
		t.Errorf("horizontal not centered: left=%d right=%d diff=%d", left, right, d)
	}

	// Width must be preserved on every row (no drift from the splice).
	for i, line := range strings.Split(screen, "\n") {
		if i >= h {
			break
		}
		if got := StringWidth(line); got != w {
			t.Errorf("row %d width %d != %d", i, got, w)
		}
	}
}

func TestOverlayCenteredPadsShortBase(t *testing.T) {
	styles := DefaultStyles()
	const w, h = 80, 30
	// Base far shorter than the screen: OverlayCentered must pad it up so the
	// modal's lower border is not clipped (the real-world regression).
	base := "only one line"

	box := NewModal("Error", "permission denied", styles).Render(w, h)
	screen := OverlayCentered(base, box, w, h)

	if lines := strings.Split(screen, "\n"); len(lines) < h {
		t.Fatalf("base not padded to screen height: got %d lines, want >= %d", len(lines), h)
	}
	if _, _, _, _, count := interiorCorners(screen, w, h); count < 4 {
		t.Fatalf("modal clipped on short base: found %d interior corners, want >= 4", count)
	}
}
