package tui

import (
	"strings"
)

// Frame constants for double-line box drawing characters
const (
	// Outer frame corners
	FrameTopLeft     = "╔"
	FrameTopRight    = "╗"
	FrameBottomLeft  = "╚"
	FrameBottomRight = "╝"

	// Outer frame borders
	FrameHorizontal = "═"
	FrameVertical   = "║"

	// Panel separator (single line vertical)
	FrameSeparator = "│"

	// Junction characters
	FrameTopJunction    = "╤" // Top border panel junction
	FrameBottomJunction = "╧" // Bottom junction at status bar
	FrameLeftJunction   = "╠" // Left junction at status bar
	FrameRightJunction  = "╣" // Right junction at status bar
)

// RenderFrame renders the complete TUI frame with embedded panel names
// and proper double-line border characters.
//
// Frame structure (without search):
// ╔═ Files ════════════════════════════════╤═ Collections ══════════════════════╗
// ║                                        │                                    ║
// ║ ...content...                          │ ...content...                      ║
// ╠════════════════════════════════════════╧════════════════════════════════════╣
// ║ ↑↓: Navigate  ←→: Expand/Collapse  Space: Toggle  Tab: Switch Panel  /: Search  R: Refresh  Q: Quit ║
// ║                                                                                                      ║
// ╚═════════════════════════════════════════════════════════════════════════════╝
//
// Frame structure (with search active):
// ╔═ Files ════════════════════════════════╤═ Collections ══════════════════════╗
// ║ ...content...                          │ ...content...                      ║
// ╠════════════════════════════════════════╧════════════════════════════════════╣
// ║ Search: query                                                               ║
// ╠════════════════════════════════════════════════════════════════════════════╣
// ║ ↑↓: Navigate  ...                                                           ║
// ╚═════════════════════════════════════════════════════════════════════════════╝
func RenderFrame(
	leftTitle string,
	rightTitle string,
	leftContent []string,
	rightContent []string,
	statusLines []string,
	leftWidth int,
	rightWidth int,
	contentHeight int,
	searchLine string,
) string {
	totalWidth := leftWidth + rightWidth + 3 // +3 for left border, separator, right border

	var result strings.Builder

	// === TOP BORDER with embedded panel names ===
	// Format: ╔═ Files ════...╤═ Collections ═══╗
	topBorder := renderTopBorder(leftTitle, rightTitle, leftWidth, rightWidth)
	result.WriteString(topBorder)
	result.WriteString("\n")

	// === CONTENT ROWS ===
	for i := range contentHeight {
		var leftLine, rightLine string

		if i < len(leftContent) {
			leftLine = leftContent[i]
		}
		if i < len(rightContent) {
			rightLine = rightContent[i]
		}

		// Ensure lines are properly sized
		leftLine = padOrTruncate(leftLine, leftWidth)
		rightLine = padOrTruncate(rightLine, rightWidth)

		// Build row: ║ leftContent │ rightContent ║
		result.WriteString(FrameVertical)
		result.WriteString(leftLine)
		result.WriteString(FrameSeparator)
		result.WriteString(rightLine)
		result.WriteString(FrameVertical)
		result.WriteString("\n")
	}

	// === SEARCH BAR (when active) ===
	if searchLine != "" {
		// Search junction: closes panel separator with ╧
		searchJunction := renderStatusJunction(leftWidth, rightWidth)
		result.WriteString(searchJunction)
		result.WriteString("\n")

		// Search box row: full width, no panel separator
		paddedSearch := padOrTruncate(searchLine, totalWidth-2)
		result.WriteString(FrameVertical)
		result.WriteString(paddedSearch)
		result.WriteString(FrameVertical)
		result.WriteString("\n")

		// Status junction: full width, no ╧ (panels already closed above)
		statusJunction := renderFullWidthJunction(totalWidth)
		result.WriteString(statusJunction)
		result.WriteString("\n")
	} else {
		// === STATUS BAR JUNCTION (no search) ===
		junctionLine := renderStatusJunction(leftWidth, rightWidth)
		result.WriteString(junctionLine)
		result.WriteString("\n")
	}

	// === STATUS BAR CONTENT ===
	for _, statusLine := range statusLines {
		paddedLine := padOrTruncate(statusLine, totalWidth-2) // -2 for left and right borders
		result.WriteString(FrameVertical)
		result.WriteString(paddedLine)
		result.WriteString(FrameVertical)
		result.WriteString("\n")
	}

	// === BOTTOM BORDER ===
	// Format: ╚═════════════════════════════════════════════════════════════════════════════╝
	bottomBorder := renderBottomBorder(totalWidth)
	result.WriteString(bottomBorder)

	return result.String()
}

// renderTopBorder creates the top border with embedded panel names
// Format: ╔═ Files ════...╤═ Collections ═══╗
// The junction ╤ must be aligned with the content row separator │
// which is at position 1 + leftWidth (after left border and left content)
func renderTopBorder(leftTitle, rightTitle string, leftWidth, rightWidth int) string {
	var result strings.Builder

	// Build left panel portion: ╔═ Files ════...
	// This must be exactly leftWidth + 1 characters (including the ╔)
	// so the junction ╤ aligns with the content separator │
	leftPart := FrameHorizontal + " " + leftTitle + " "
	leftPartWidth := StringWidth(leftPart)

	result.WriteString(FrameTopLeft)
	result.WriteString(leftPart)

	// Fill to reach exactly leftWidth characters after ╔
	leftFillLen := max(0, leftWidth-leftPartWidth)
	result.WriteString(strings.Repeat(FrameHorizontal, leftFillLen))

	// Junction: ╤ (at position 1 + leftWidth, same as │ in content rows)
	result.WriteString(FrameTopJunction)

	// Build right panel portion: ═ Collections ═══╗
	// This must be exactly rightWidth + 1 characters (including the ╗)
	rightPart := FrameHorizontal + " " + rightTitle + " "
	rightPartWidth := StringWidth(rightPart)

	result.WriteString(rightPart)

	// Fill to reach exactly rightWidth characters before ╗
	rightFillLen := max(0, rightWidth-rightPartWidth)
	result.WriteString(strings.Repeat(FrameHorizontal, rightFillLen))

	// Right corner: ╗
	result.WriteString(FrameTopRight)

	return result.String()
}

// renderStatusJunction creates the junction line between content and status bar
// Format: ╠════════════════════════════════════════╧════════════════════════════════════╣
func renderStatusJunction(leftWidth, rightWidth int) string {
	var result strings.Builder

	// Left junction: ╠
	result.WriteString(FrameLeftJunction)

	// Left horizontal fill
	result.WriteString(strings.Repeat(FrameHorizontal, leftWidth))

	// Center junction: ╧
	result.WriteString(FrameBottomJunction)

	// Right horizontal fill
	result.WriteString(strings.Repeat(FrameHorizontal, rightWidth))

	// Right junction: ╣
	result.WriteString(FrameRightJunction)

	return result.String()
}

// renderFullWidthJunction creates a full-width junction line (no panel separator)
// Format: ╠═══════════════════════════════════════════════════════════════════╣
func renderFullWidthJunction(totalWidth int) string {
	var result strings.Builder

	result.WriteString(FrameLeftJunction)
	result.WriteString(strings.Repeat(FrameHorizontal, totalWidth-2)) // -2 for left and right junctions
	result.WriteString(FrameRightJunction)

	return result.String()
}

// renderBottomBorder creates the bottom border
// Format: ╚═════════════════════════════════════════════════════════════════════════════╝
func renderBottomBorder(totalWidth int) string {
	var result strings.Builder

	result.WriteString(FrameBottomLeft)
	result.WriteString(strings.Repeat(FrameHorizontal, totalWidth-2)) // -2 for corners
	result.WriteString(FrameBottomRight)

	return result.String()
}

// padOrTruncate ensures a string is exactly the specified width
func padOrTruncate(s string, width int) string {
	sWidth := StringWidth(s)
	if sWidth > width {
		return TruncateRight(s, width)
	}
	if sWidth < width {
		return PadRight(s, width)
	}
	return s
}
