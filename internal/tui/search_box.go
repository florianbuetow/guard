package tui

import (
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
)

// SearchBox is a Bubble Tea model wrapping a textinput for search/filter functionality.
type SearchBox struct {
	textInput textinput.Model
	active    bool
}

// NewSearchBox creates a new SearchBox with default settings.
func NewSearchBox() SearchBox {
	ti := textinput.New()
	ti.Placeholder = "Type to search..."
	ti.Prompt = " Search: "
	return SearchBox{
		textInput: ti,
	}
}

// Init implements tea.Model.
func (s SearchBox) Init() tea.Cmd {
	return nil
}

// Update handles key events when the search box is active.
func (s SearchBox) Update(msg tea.Msg) (SearchBox, tea.Cmd) {
	if !s.active {
		return s, nil
	}

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.Type {
		case tea.KeyEscape:
			s.textInput.SetValue("")
			deactivateCmd := s.SetActive(false)
			return s, tea.Batch(
				deactivateCmd,
				func() tea.Msg {
					return FilterChangedMsg{Query: ""}
				},
			)

		default:
			var cmd tea.Cmd
			s.textInput, cmd = s.textInput.Update(msg)
			query := s.textInput.Value()
			return s, tea.Batch(cmd, func() tea.Msg {
				return FilterChangedMsg{Query: query}
			})
		}
	}

	// Forward non-key messages to textinput as well (e.g., blink messages)
	var cmd tea.Cmd
	s.textInput, cmd = s.textInput.Update(msg)
	return s, cmd
}

// View renders the search box as a single line.
func (s SearchBox) View() string {
	return s.textInput.View() + "\033[0m"
}

// SetWidth sets the total display width of the search box (prompt + input + cursor).
// The textinput.Width controls the text area only; the rendered output also includes
// the prompt and a 1-cell cursor, so we subtract both.
func (s *SearchBox) SetWidth(width int) {
	promptWidth := StringWidth(s.textInput.Prompt)
	inputWidth := width - promptWidth - 1
	if inputWidth < 1 {
		inputWidth = 1
	}
	s.textInput.Width = inputWidth
}

// SetActive activates or deactivates the search box.
// When activating: focuses the textinput and enables cursor blink.
// When deactivating: blurs the textinput.
func (s *SearchBox) SetActive(active bool) tea.Cmd {
	s.active = active
	if active {
		cmd := s.textInput.Focus()
		s.textInput.CursorEnd()
		return cmd
	}
	s.textInput.Blur()
	return nil
}

// Blur blurs the textinput (stops cursor blinking) without deactivating the search box.
func (s *SearchBox) Blur() {
	s.textInput.Blur()
}

// Focus focuses the textinput (starts cursor blinking) without changing active state.
func (s *SearchBox) Focus() tea.Cmd {
	cmd := s.textInput.Focus()
	s.textInput.CursorEnd()
	return cmd
}

// Query returns the current query text.
func (s SearchBox) Query() string {
	return s.textInput.Value()
}

// IsActive returns whether the search box is currently active.
func (s SearchBox) IsActive() bool {
	return s.active
}

// Clear clears the query text.
func (s *SearchBox) Clear() {
	s.textInput.SetValue("")
}
