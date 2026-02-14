package tui

import (
	tea "github.com/charmbracelet/bubbletea"

	"github.com/florianbuetow/guard/internal/manager"
)

// CollectionsPanel is the container for the collection tree with title and borders
type CollectionsPanel struct {
	tree    CollectionTree
	width   int
	height  int
	styles  *Styles
	focused bool
	title   string
}

// NewCollectionsPanel creates a new CollectionsPanel
func NewCollectionsPanel(mgr *manager.Manager, styles *Styles, keys KeyMap) CollectionsPanel {
	return CollectionsPanel{
		tree:   NewCollectionTree(mgr, styles, keys),
		styles: styles,
		title:  "Collections",
	}
}

// Init initializes the panel
func (p CollectionsPanel) Init() tea.Cmd {
	return p.tree.Init()
}

// Update handles messages
func (p CollectionsPanel) Update(msg tea.Msg) (CollectionsPanel, tea.Cmd) {
	switch msg := msg.(type) {
	case WindowSizeMsg:
		p.width = msg.Width
		p.height = msg.Height
		p.tree.SetSize(msg.Width, msg.Height)
	}

	var cmd tea.Cmd
	p.tree, cmd = p.tree.Update(msg)
	return p, cmd
}

// SetFocused sets the focus state
func (p *CollectionsPanel) SetFocused(focused bool) {
	p.focused = focused
	p.tree.SetFocused(focused)
}

// IsFocused returns whether the panel is focused
func (p *CollectionsPanel) IsFocused() bool {
	return p.focused
}

// SetSize sets the panel size
func (p *CollectionsPanel) SetSize(width, height int) {
	p.width = width
	p.height = height
	p.tree.SetSize(width, height)
}

// Refresh refreshes the panel content
func (p *CollectionsPanel) Refresh() {
	p.tree.Refresh()
}

// GetTree returns the underlying collection tree
func (p *CollectionsPanel) GetTree() *CollectionTree {
	return &p.tree
}

// ContentLines returns the panel content as lines without borders
func (p *CollectionsPanel) ContentLines() []string {
	return padContentToFit(p.tree.View(), p.width, p.height)
}

// Title returns the panel title
func (p *CollectionsPanel) Title() string {
	return p.title
}
