package tui

import (
	tea "github.com/charmbracelet/bubbletea"

	"github.com/florianbuetow/guard/internal/manager"
)

// FilesPanel is the container for the file tree with title and borders
type FilesPanel struct {
	tree    FileTree
	width   int
	height  int
	styles  *Styles
	focused bool
	title   string
}

// NewFilesPanel creates a new FilesPanel
func NewFilesPanel(root *FileNode, mgr *manager.Manager, styles *Styles, keys KeyMap) FilesPanel {
	return FilesPanel{
		tree:   NewFileTree(root, mgr, styles, keys),
		styles: styles,
		title:  "Files",
	}
}

// Init initializes the panel
func (p FilesPanel) Init() tea.Cmd {
	return p.tree.Init()
}

// Update handles messages
func (p FilesPanel) Update(msg tea.Msg) (FilesPanel, tea.Cmd) {
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
func (p *FilesPanel) SetFocused(focused bool) {
	p.focused = focused
	p.tree.SetFocused(focused)
}

// IsFocused returns whether the panel is focused
func (p *FilesPanel) IsFocused() bool {
	return p.focused
}

// SetSize sets the panel size
func (p *FilesPanel) SetSize(width, height int) {
	p.width = width
	p.height = height
	p.tree.SetSize(width, height)
}

// Refresh refreshes the panel content
func (p *FilesPanel) Refresh() {
	p.tree.refresh()
}

// GetTree returns the underlying file tree
func (p *FilesPanel) GetTree() *FileTree {
	return &p.tree
}

// ContentLines returns the panel content as lines without borders
func (p *FilesPanel) ContentLines() []string {
	return padContentToFit(p.tree.View(), p.width, p.height)
}

// Title returns the panel title
func (p *FilesPanel) Title() string {
	return p.title
}
