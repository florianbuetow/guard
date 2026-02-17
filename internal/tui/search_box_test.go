package tui

import (
	"strings"
	"testing"

	tea "github.com/charmbracelet/bubbletea"
)

func TestSearchBoxViewWidthDoesNotExceedSetWidth(t *testing.T) {
	sb := NewSearchBox()
	sb.SetActive(true)
	sb.SetWidth(40)

	view := sb.View()
	width := StringWidth(view)

	if width > 40 {
		t.Errorf("SearchBox.View() printable width is %d, exceeds set width of 40 (prompt not accounted for)", width)
	}
}

func TestSearchBoxViewEndsWithANSIReset(t *testing.T) {
	sb := NewSearchBox()
	sb.SetActive(true)
	sb.SetWidth(40)

	view := sb.View()

	// The View() output is used directly in the frame renderer, where
	// padOrTruncate appends plain spaces after it. In a real terminal,
	// the textinput emits ANSI codes for cursor/placeholder styling.
	// Without an explicit reset at the end, those styles bleed into
	// the padding spaces and subsequent frame content (junction line,
	// status bar), causing them to render in dark grey.
	//
	// The View() must end with "\033[0m" to terminate any active styling.
	if !strings.HasSuffix(view, "\033[0m") {
		t.Errorf("SearchBox.View() does not end with ANSI reset (\\033[0m); "+
			"styling will bleed into frame padding.\nView suffix: %q",
			view[max(0, len(view)-20):])
	}
}

func TestSearchBoxSetWidthClamp(t *testing.T) {
	sb := NewSearchBox()
	sb.SetWidth(0)

	if sb.textInput.Width < 1 {
		t.Fatalf("SearchBox width must be clamped to at least 1, got %d", sb.textInput.Width)
	}
}

func TestSearchBoxEscapeClearsAndDeactivates(t *testing.T) {
	sb := NewSearchBox()
	sb.SetActive(true)

	msg := tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune("abc")}
	var cmd tea.Cmd
	sb, cmd = sb.Update(msg)
	if cmd != nil {
		_ = cmd()
	}

	sb, cmd = sb.Update(tea.KeyMsg{Type: tea.KeyEscape})
	if cmd == nil {
		t.Fatal("expected command for escape handling")
	}

	if sb.IsActive() {
		t.Fatal("search box should be inactive after escape")
	}
	if sb.Query() != "" {
		t.Fatalf("search query should be cleared after escape, got %q", sb.Query())
	}

	got := cmd()
	filterMsg, ok := got.(FilterChangedMsg)
	if !ok {
		t.Fatalf("expected FilterChangedMsg, got %T", got)
	}
	if filterMsg.Query != "" {
		t.Fatalf("expected empty filter query after escape, got %q", filterMsg.Query)
	}
}
