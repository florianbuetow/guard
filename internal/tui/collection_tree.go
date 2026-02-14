package tui

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/florianbuetow/guard/internal/manager"
)

// CollectionTree is a Bubble Tea model for the collection tree navigation
type CollectionTree struct {
	nodes   []CollectionNode
	cursor  int
	scroll  *ScrollState
	width   int
	height  int
	styles  *Styles
	keys    KeyMap
	mgr     *manager.Manager
	focused bool
}

// NewCollectionTree creates a new CollectionTree model
func NewCollectionTree(mgr *manager.Manager, styles *Styles, keys KeyMap) CollectionTree {
	ct := CollectionTree{
		scroll: NewScrollState(10),
		styles: styles,
		keys:   keys,
		mgr:    mgr,
	}
	ct.refresh()
	return ct
}

// refresh rebuilds the node list
func (ct *CollectionTree) refresh() {
	ct.nodes = BuildCollectionNodes(ct.mgr)
	if ct.cursor >= len(ct.nodes) {
		ct.cursor = len(ct.nodes) - 1
	}
	if ct.cursor < 0 {
		ct.cursor = 0
	}
	ct.scroll.Update(ct.cursor, len(ct.nodes))
}

// Init initializes the model
func (ct CollectionTree) Init() tea.Cmd {
	return nil
}

// Update handles messages
func (ct CollectionTree) Update(msg tea.Msg) (CollectionTree, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		if !ct.focused {
			return ct, nil
		}

		switch {
		case matchKey(msg, ct.keys.Up):
			ct.moveCursorUp()
		case matchKey(msg, ct.keys.Down):
			ct.moveCursorDown()
		case matchKey(msg, ct.keys.Toggle):
			return ct, ct.toggleGuard()
		}

	case WindowSizeMsg:
		ct.width = msg.Width
		ct.height = msg.Height
		ct.scroll.SetViewportSize(msg.Height)

	case RefreshMsg:
		ct.refresh()
	}

	return ct, nil
}

// View renders the collection tree
func (ct CollectionTree) View() string {
	if len(ct.nodes) == 0 {
		return ct.styles.ItemEmpty.Render("No collections")
	}

	start, end := ct.scroll.GetVisibleRange()
	var sb strings.Builder

	for i := start; i < end && i < len(ct.nodes); i++ {
		node := ct.nodes[i]
		line := ct.renderNode(node, i == ct.cursor)
		sb.WriteString(line)
		if i < end-1 {
			sb.WriteString("\n")
		}
	}

	return sb.String()
}

// renderNode renders a single collection node
func (ct CollectionTree) renderNode(node CollectionNode, selected bool) string {
	var sb strings.Builder

	// Tree prefix based on depth
	prefix := BuildTreePrefix(node.Depth, node.AncestorLast)
	sb.WriteString(ct.styles.TreePrefix.Render(prefix))

	// Guard state indicator
	stateStr := ct.styles.RenderGuardState(node.GuardState)
	sb.WriteString(stateStr)
	sb.WriteString(" ")

	// Name with optional equivalence and empty indicators
	name := GetCollectionDisplayName(CollectionInfo{
		Name:         node.Name,
		IsEmpty:      node.IsEmpty,
		EquivalentTo: node.EquivalentTo,
	})

	// Calculate available width for name
	prefixWidth := StringWidth(prefix) + 3 + 1 // prefix + guard (3 chars) + space
	availableWidth := ct.width - prefixWidth - 2
	if availableWidth < 10 {
		availableWidth = 10
	}

	name = TruncateMiddle(name, availableWidth)

	// Apply styling
	var nameStyle lipgloss.Style
	if node.IsEmpty {
		nameStyle = ct.styles.ItemEmpty
	} else {
		nameStyle = ct.styles.ItemNormal
	}

	if selected && ct.focused {
		nameStyle = ct.styles.ItemSelected
	}

	sb.WriteString(nameStyle.Render(name))

	// Pad to fill width
	line := sb.String()
	lineWidth := StringWidth(line)
	if lineWidth < ct.width {
		line = PadRight(line, ct.width)
	}

	return line
}

// Navigation methods

func (ct *CollectionTree) moveCursorUp() {
	if ct.cursor > 0 {
		ct.cursor--
		ct.scroll.Update(ct.cursor, len(ct.nodes))
	}
}

func (ct *CollectionTree) moveCursorDown() {
	if ct.cursor < len(ct.nodes)-1 {
		ct.cursor++
		ct.scroll.Update(ct.cursor, len(ct.nodes))
	}
}

// toggleGuard toggles the guard state of the current collection
func (ct *CollectionTree) toggleGuard() tea.Cmd {
	if len(ct.nodes) == 0 || ct.cursor >= len(ct.nodes) {
		return nil
	}

	node := ct.nodes[ct.cursor]

	// Empty collections cannot be toggled
	if node.IsEmpty {
		return nil
	}

	if ct.mgr == nil {
		return nil
	}

	// Get current guard state
	status, err := ct.mgr.GetCollectionStatus(node.Name, false)
	if err != nil {
		return func() tea.Msg { return ErrorMsg{Err: err} }
	}
	if !status.Exists {
		return func() tea.Msg { return ErrorMsg{Err: fmt.Errorf("collection not found: %s", node.Name)} }
	}

	// Use manager's ToggleCollections to toggle both collection and file permissions
	if err := ct.mgr.ToggleCollections([]string{node.Name}); err != nil {
		return func() tea.Msg { return ErrorMsg{Err: err} }
	}

	// Update node state
	ct.nodes[ct.cursor].GuardState = ComputeEffectiveCollectionGuardState(ct.mgr, node.Name)

	return func() tea.Msg {
		return GuardToggledMsg{
			Path:          node.Name,
			IsCollection:  true,
			NewGuardState: !status.Guard,
			AffectedFiles: node.FileCount,
		}
	}
}

// SetFocused sets the focus state
func (ct *CollectionTree) SetFocused(focused bool) {
	ct.focused = focused
}

// IsFocused returns whether the tree is focused
func (ct *CollectionTree) IsFocused() bool {
	return ct.focused
}

// GetSelectedNode returns the currently selected node
func (ct *CollectionTree) GetSelectedNode() *CollectionNode {
	if len(ct.nodes) == 0 || ct.cursor >= len(ct.nodes) {
		return nil
	}
	return &ct.nodes[ct.cursor]
}

// SetSize sets the viewport size
func (ct *CollectionTree) SetSize(width, height int) {
	ct.width = width
	ct.height = height
	ct.scroll.SetViewportSize(height)
}

// Refresh refreshes the tree
func (ct *CollectionTree) Refresh() {
	ct.refresh()
}
