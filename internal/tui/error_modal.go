package tui

import (
	"strings"

	tea "github.com/charmbracelet/bubbletea"
)

// ErrorModal displays error messages in a modal overlay
type ErrorModal struct {
	err     error
	visible bool
	width   int
	height  int
	styles  *Styles
}

// NewErrorModal creates a new ErrorModal
func NewErrorModal(styles *Styles) ErrorModal {
	return ErrorModal{
		styles: styles,
	}
}

// Init initializes the error modal
func (m ErrorModal) Init() tea.Cmd {
	return nil
}

// Update handles messages
func (m ErrorModal) Update(msg tea.Msg) (ErrorModal, tea.Cmd) {
	switch msg := msg.(type) {
	case ErrorMsg:
		m.err = msg.Err
		m.visible = true

	case tea.KeyMsg:
		if m.visible {
			// Any key dismisses the modal
			m.visible = false
			m.err = nil
		}

	case WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
	}

	return m, nil
}

// Overlay composites the error modal as a centered overlay on top of base,
// returning base unchanged when the modal is hidden. The modal shows "Error" as
// the title and the error text (plus the dismiss hint) as the body; its size
// and position are derived from the current screen dimensions.
func (m ErrorModal) Overlay(base string) string {
	if !m.visible || m.err == nil {
		return base
	}

	text := m.err.Error() + "\n\nPress any key to dismiss"
	box := NewModal("Error", text, m.styles).Render(m.width, m.height)
	return OverlayCentered(base, box, m.width, m.height)
}

// IsVisible returns whether the modal is visible
func (m *ErrorModal) IsVisible() bool {
	return m.visible
}

// Show shows the modal with an error
func (m *ErrorModal) Show(err error) {
	m.err = err
	m.visible = true
}

// Hide hides the modal
func (m *ErrorModal) Hide() {
	m.visible = false
	m.err = nil
}

// SetSize sets the modal's available size
func (m *ErrorModal) SetSize(width, height int) {
	m.width = width
	m.height = height
}

// wrapText wraps text to fit within maxWidth
func wrapText(text string, maxWidth int) string {
	if maxWidth <= 0 {
		return text
	}

	var result strings.Builder
	var lineWidth int

	words := strings.Fields(text)
	for i, word := range words {
		wordWidth := StringWidth(word)

		if lineWidth+wordWidth+1 > maxWidth && lineWidth > 0 {
			result.WriteString("\n")
			lineWidth = 0
		} else if i > 0 && lineWidth > 0 {
			result.WriteString(" ")
			lineWidth++
		}

		result.WriteString(word)
		lineWidth += wordWidth
	}

	return result.String()
}
