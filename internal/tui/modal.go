package tui

import (
	"strings"

	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/x/ansi"
)

// Modal is a reusable, centered overlay box with a title and body text. It owns
// modal *generation* only: given the current screen dimensions it computes its
// own size and position and renders into a slice of rows (a ModalBox). Drawing
// that box onto existing content is a separate concern handled by
// OverlayCentered, which keeps generation independent of compositing.
type Modal struct {
	Title  string
	Text   string
	styles *Styles
}

// NewModal builds a Modal with the given title and body text. The text may
// contain '\n' to force line breaks; long lines are word-wrapped to fit.
func NewModal(title, text string, styles *Styles) Modal {
	return Modal{Title: title, Text: text, styles: styles}
}

// ModalBox is a generated, positioned modal: the bordered rows plus the
// top-left coordinate at which to draw them so the box is centered on screen.
// Each entry in Rows is exactly Width display columns wide.
type ModalBox struct {
	Rows   []string // bordered box, one string per row
	X      int      // left column of the box (0-based, clamped to >= 0)
	Y      int      // top row of the box (0-based, clamped to >= 0)
	Width  int      // display width of the box
	Height int      // number of rows in the box
}

// Render builds the modal for a screenWidth x screenHeight viewport. The box is
// sized to fit its title and (word-wrapped, multi-line) text, then positioned
// so it is centered both horizontally and vertically. When the box is larger
// than the screen the position is clamped to the top-left corner.
func (m Modal) Render(screenWidth, screenHeight int) ModalBox {
	// Budget for the wrapped text: leave room for the border (2), the
	// horizontal padding (4) and a small margin from the screen edges.
	innerWidth := max(screenWidth-10, 1)

	title := m.styles.ErrorTitle.Render(m.Title)
	body := m.styles.ErrorMessage.Render(wrapMultiline(m.Text, innerWidth))
	content := lipgloss.JoinVertical(lipgloss.Left, title, "", body)
	box := m.styles.ErrorBorder.Render(content)

	rows := strings.Split(box, "\n")
	width := 0
	for _, r := range rows {
		if w := StringWidth(r); w > width {
			width = w
		}
	}

	x := (screenWidth - width) / 2
	y := (screenHeight - len(rows)) / 2
	if x < 0 {
		x = 0
	}
	if y < 0 {
		y = 0
	}

	return ModalBox{Rows: rows, X: x, Y: y, Width: width, Height: len(rows)}
}

// OverlayCentered composites box.Rows onto base so the box sits at
// (box.X, box.Y). base is split into lines and padded up to screenHeight so the
// box never falls off the bottom (which would drop its lower border). For each
// covered row the cells in [box.X, box.X+box.Width) are replaced by the box row,
// preserving the base cells outside that span; ANSI styling and wide runes are
// handled by ansi.Cut.
func OverlayCentered(base string, box ModalBox, screenWidth, screenHeight int) string {
	if len(box.Rows) == 0 {
		return base
	}

	lines := strings.Split(base, "\n")
	for len(lines) < screenHeight {
		lines = append(lines, "")
	}

	for i, row := range box.Rows {
		y := box.Y + i
		if y < 0 || y >= len(lines) {
			continue
		}
		lines[y] = spliceLine(lines[y], row, box.X, screenWidth)
	}

	return strings.Join(lines, "\n")
}

// spliceLine overlays `overlay` onto `base` starting at visible column x,
// preserving base cells before x and after x+width(overlay). The base is
// treated as `screenWidth` columns wide so the right-hand remainder (e.g. the
// frame's right border) is kept intact.
func spliceLine(base, overlay string, x, screenWidth int) string {
	ow := StringWidth(overlay)

	left := ansi.Cut(base, 0, x)
	if lw := StringWidth(left); lw < x {
		left += strings.Repeat(" ", x-lw)
	}

	var right string
	if x+ow < screenWidth {
		right = ansi.Cut(base, x+ow, screenWidth)
	}

	return left + "\x1b[0m" + overlay + "\x1b[0m" + right
}

// wrapMultiline wraps each line of text to maxWidth while preserving explicit
// line breaks (including blank lines), so callers can pass multi-paragraph text.
func wrapMultiline(text string, maxWidth int) string {
	lines := strings.Split(text, "\n")
	out := make([]string, 0, len(lines))
	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			out = append(out, "")
			continue
		}
		out = append(out, wrapText(line, maxWidth))
	}
	return strings.Join(out, "\n")
}
