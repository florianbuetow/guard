package tui

import (
	"testing"

	tea "github.com/charmbracelet/bubbletea"
)

func TestAppUpdate_AllowsSlashWhileSearchFocused(t *testing.T) {
	a := App{
		searchBox: NewSearchBox(),
		keys:      DefaultKeyMap(),
		focus:     FocusSearch,
	}
	a.searchBox.SetActive(true)

	model, _ := a.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'/'}})
	updated := model.(App)

	if got := updated.searchBox.Query(); got != "/" {
		t.Fatalf("expected '/' to be routed into search input, got %q", got)
	}
}
