package tui

import (
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
	ToggleAll   key.Binding // Shift+Space - toggle recursively (folders only)
	SwitchPanel key.Binding // Tab - switch between Files and Collections
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
			key.WithKeys("shift+space", "ctrl+space", "ctrl+@"),
			key.WithHelp("Shift+Space", "toggle recursive"),
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
	return "↑↓:Navigate  ←→:Expand/Collapse  Space:Toggle  Tab:Switch  /:Search  R:Refresh  Q:Quit"
}
