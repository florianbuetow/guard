package tui

import (
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

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

// View renders the panel
func (p CollectionsPanel) View() string {
	// Choose style based on focus
	var borderStyle lipgloss.Style
	if p.focused {
		borderStyle = p.styles.PanelActive
	} else {
		borderStyle = p.styles.PanelInactive
	}

	// Calculate inner dimensions
	innerWidth := p.width - 2
	innerHeight := p.height - 3
	if innerWidth < 1 {
		innerWidth = 1
	}
	if innerHeight < 1 {
		innerHeight = 1
	}

	// Build title
	title := p.styles.PanelTitle.Render(p.title)
	if p.focused {
		title = "● " + title
	} else {
		title = "○ " + title
	}
	// Pad title to match panel width for proper horizontal joining
	if StringWidth(title) < p.width {
		title = PadRight(title, p.width)
	}

	// Render tree content
	content := p.tree.View()

	// Pad content to fill the panel
	lines := strings.Split(content, "\n")
	var paddedLines []string
	for i := 0; i < innerHeight; i++ {
		if i < len(lines) {
			line := lines[i]
			// Ensure line fills width, truncating if too long
			lineWidth := StringWidth(line)
			if lineWidth > innerWidth {
				line = TruncateRight(line, innerWidth)
			} else if lineWidth < innerWidth {
				line = PadRight(line, innerWidth)
			}
			paddedLines = append(paddedLines, line)
		} else {
			paddedLines = append(paddedLines, strings.Repeat(" ", innerWidth))
		}
	}

	paddedContent := strings.Join(paddedLines, "\n")

	// Apply border style
	panel := borderStyle.
		Width(innerWidth).
		Height(innerHeight).
		Render(paddedContent)

	return lipgloss.JoinVertical(lipgloss.Left, title, panel)
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
	// Calculate inner dimensions (no borders needed since frame handles them)
	innerWidth := p.width
	innerHeight := p.height

	if innerWidth < 1 {
		innerWidth = 1
	}
	if innerHeight < 1 {
		innerHeight = 1
	}

	// Render tree content
	content := p.tree.View()

	// Pad content to fill the panel
	lines := strings.Split(content, "\n")
	var paddedLines []string
	for i := 0; i < innerHeight; i++ {
		if i < len(lines) {
			line := lines[i]
			// Ensure line fills width, truncating if too long
			lineWidth := StringWidth(line)
			if lineWidth > innerWidth {
				line = TruncateRight(line, innerWidth)
			} else if lineWidth < innerWidth {
				line = PadRight(line, innerWidth)
			}
			paddedLines = append(paddedLines, line)
		} else {
			paddedLines = append(paddedLines, strings.Repeat(" ", innerWidth))
		}
	}

	return paddedLines
}

// Title returns the panel title
func (p *CollectionsPanel) Title() string {
	return p.title
}
