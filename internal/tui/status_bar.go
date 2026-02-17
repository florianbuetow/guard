package tui

import (
	"strings"

	tea "github.com/charmbracelet/bubbletea"
)

// StatusBar displays keyboard shortcuts at the bottom of the screen
type StatusBar struct {
	width   int
	styles  *Styles
	keys    KeyMap
	message string // Temporary message to display (e.g., after toggle)
}

// NewStatusBar creates a new StatusBar
func NewStatusBar(styles *Styles, keys KeyMap) StatusBar {
	return StatusBar{
		styles: styles,
		keys:   keys,
	}
}

// Init initializes the status bar
func (s StatusBar) Init() tea.Cmd {
	return nil
}

// Update handles messages
func (s StatusBar) Update(msg tea.Msg) (StatusBar, tea.Cmd) {
	switch msg := msg.(type) {
	case WindowSizeMsg:
		s.width = msg.Width

	case GuardToggledMsg:
		if msg.IsCollection {
			if msg.NewGuardState {
				s.message = "Collection guarded"
			} else {
				s.message = "Collection unguarded"
			}
		} else {
			if msg.AffectedFiles == 1 {
				if msg.NewGuardState {
					s.message = "File guarded"
				} else {
					s.message = "File unguarded"
				}
			} else {
				if msg.NewGuardState {
					s.message = "Files guarded"
				} else {
					s.message = "Files unguarded"
				}
			}
		}

	case ErrorMsg:
		s.message = "Error: " + msg.Err.Error()

	case RefreshMsg:
		s.message = "Refreshed"
	}

	return s, nil
}

// View renders the status bar
func (s StatusBar) View() string {
	// Build help text
	helpText := s.keys.StatusBarHelp()

	// Truncate if needed
	if StringWidth(helpText) > s.width {
		helpText = TruncateRight(helpText, s.width)
	}

	// Pad to fill width
	helpText = PadRight(helpText, s.width)

	return s.styles.StatusBar.Render(helpText)
}

// SetWidth sets the status bar width
func (s *StatusBar) SetWidth(width int) {
	s.width = width
}

// ClearMessage clears the temporary message
func (s *StatusBar) ClearMessage() {
	s.message = ""
}

// SetMessage sets a temporary message
func (s *StatusBar) SetMessage(message string) {
	s.message = message
}

// RenderHelp renders the keyboard shortcuts help
func (s StatusBar) RenderHelp() string {
	var parts []string

	// Add key bindings
	bindings := []struct {
		key  string
		desc string
	}{
		{"↑↓", "Navigate"},
		{"←→", "Expand/Collapse"},
		{"Space", "Toggle"},
		{"Tab", "Switch Panel"},
		{"R", "Refresh"},
		{"Q", "Quit"},
	}

	for _, b := range bindings {
		part := s.styles.StatusKey.Render(b.key) + " " + s.styles.StatusValue.Render(b.desc)
		parts = append(parts, part)
	}

	return strings.Join(parts, "  ")
}

// ContentLines returns the status bar content as lines for the frame
func (s StatusBar) ContentLines() []string {
	// Keep frame-rendered status text aligned with the key map help string.
	return []string{
		" " + s.keys.StatusBarHelp(),
		"",
	}
}
