package tui

import (
	"strings"

	"github.com/charmbracelet/bubbles/key"
)

// KeyMap defines the key bindings for the TUI
type KeyMap struct {
	// Navigation
	Up    key.Binding
	Down  key.Binding
	Left  key.Binding
	Right key.Binding

	// Actions
	Toggle      key.Binding // Space - toggle guard
	ToggleAll   key.Binding // Enter/Shift+Space - toggle recursively (folders only)
	SwitchPanel key.Binding // Tab - cycle focus between Files, Collections, and Search (when active)
	Refresh     key.Binding // R - refresh/reload

	// Search
	Search key.Binding // / - activate search

	// Exit
	Quit key.Binding // Q - quit
}

// DefaultKeyMap returns the default key bindings
func DefaultKeyMap() KeyMap {
	return KeyMap{
		Up: key.NewBinding(
			key.WithKeys("up", "k"),
			key.WithHelp("↑/k", "up"),
		),
		Down: key.NewBinding(
			key.WithKeys("down", "j"),
			key.WithHelp("↓/j", "down"),
		),
		Left: key.NewBinding(
			key.WithKeys("left", "h"),
			key.WithHelp("←/h", "collapse/parent"),
		),
		Right: key.NewBinding(
			key.WithKeys("right", "l"),
			key.WithHelp("→/l", "expand/child"),
		),
		Toggle: key.NewBinding(
			key.WithKeys(" "),
			key.WithHelp("Space", "toggle guard"),
		),
		ToggleAll: key.NewBinding(
			key.WithKeys("enter", "shift+space", "ctrl+space", "ctrl+@"),
			key.WithHelp("Enter", "deep toggle"),
		),
		SwitchPanel: key.NewBinding(
			key.WithKeys("tab"),
			key.WithHelp("Tab", "switch panel"),
		),
		Refresh: key.NewBinding(
			key.WithKeys("r", "R"),
			key.WithHelp("r", "refresh"),
		),
		Search: key.NewBinding(
			key.WithKeys("/"),
			key.WithHelp("/", "search"),
		),
		Quit: key.NewBinding(
			key.WithKeys("q", "Q", "ctrl+c"),
			key.WithHelp("q", "quit"),
		),
	}
}

// ShortHelp returns the short help for the key bindings
func (k KeyMap) ShortHelp() []key.Binding {
	return []key.Binding{
		k.Up, k.Down, k.Toggle, k.SwitchPanel, k.Quit,
	}
}

// FullHelp returns the full help for the key bindings
func (k KeyMap) FullHelp() [][]key.Binding {
	return [][]key.Binding{
		{k.Up, k.Down, k.Left, k.Right},
		{k.Toggle, k.ToggleAll, k.SwitchPanel},
		{k.Refresh, k.Quit},
	}
}

// StatusBarHelp returns the help text for the status bar
func (k KeyMap) StatusBarHelp() string {
	return strings.Join(k.StatusBarHelpLines(), "  ")
}

// StatusBarHelpLines returns wrapped help text lines for frame-rendered status bars.
func (k KeyMap) StatusBarHelpLines() []string {
	return []string{
		"↑↓: Navigate  ←→: Expand/Collapse  Space: Toggle  /: Search",
		"Enter: Deep Toggle  Tab: Switch Panel  R: Refresh  Q: Quit",
	}
}
