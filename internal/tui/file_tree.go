package tui

import (
	"strings"

	"github.com/charmbracelet/bubbles/key"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/florianbuetow/guard/internal/manager"
)

// FileTree is a Bubble Tea model for the file tree navigation
type FileTree struct {
	root      *FileNode
	flatNodes []FlattenedNode
	cursor    int
	scroll    *ScrollState
	width     int
	height    int
	styles    *Styles
	keys      KeyMap
	mgr       *manager.Manager
	focused   bool
}

// NewFileTree creates a new FileTree model
func NewFileTree(root *FileNode, mgr *manager.Manager, styles *Styles, keys KeyMap) FileTree {
	ft := FileTree{
		root:   root,
		scroll: NewScrollState(10),
		styles: styles,
		keys:   keys,
		mgr:    mgr,
	}
	ft.refreshFlatNodes()
	return ft
}

// refreshFlatNodes rebuilds the flattened node list
func (ft *FileTree) refreshFlatNodes() {
	ft.flatNodes = Flatten(ft.root)
	if ft.cursor >= len(ft.flatNodes) {
		ft.cursor = len(ft.flatNodes) - 1
	}
	if ft.cursor < 0 {
		ft.cursor = 0
	}
	ft.scroll.Update(ft.cursor, len(ft.flatNodes))
}

// Init initializes the model
func (ft FileTree) Init() tea.Cmd {
	return nil
}

// Update handles messages
func (ft FileTree) Update(msg tea.Msg) (FileTree, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		if !ft.focused {
			return ft, nil
		}

		switch {
		case matchKey(msg, ft.keys.Up):
			ft.moveCursorUp()
		case matchKey(msg, ft.keys.Down):
			ft.moveCursorDown()
		case matchKey(msg, ft.keys.Left):
			ft.handleLeft()
		case matchKey(msg, ft.keys.Right):
			ft.handleRight()
		case matchKey(msg, ft.keys.Toggle):
			return ft, ft.toggleGuard()
		case matchKey(msg, ft.keys.ToggleAll):
			return ft, ft.toggleGuardRecursive()
		}

	case WindowSizeMsg:
		ft.width = msg.Width
		ft.height = msg.Height
		ft.scroll.SetViewportSize(msg.Height) // Panel already accounts for borders

	case RefreshMsg:
		ft.refresh()
	}

	return ft, nil
}

// View renders the file tree
func (ft FileTree) View() string {
	if len(ft.flatNodes) == 0 {
		return "No files"
	}

	start, end := ft.scroll.GetVisibleRange()
	var sb strings.Builder

	for i := start; i < end && i < len(ft.flatNodes); i++ {
		fn := ft.flatNodes[i]
		line := ft.renderNode(fn, i == ft.cursor)
		sb.WriteString(line)
		if i < end-1 {
			sb.WriteString("\n")
		}
	}

	return sb.String()
}

// renderNode renders a single node line
func (ft FileTree) renderNode(fn FlattenedNode, selected bool) string {
	node := fn.Node
	var sb strings.Builder

	// Tree prefix
	sb.WriteString(ft.styles.TreePrefix.Render(fn.TreePrefix))

	// Folder/file indicator
	if node.IsDir {
		sb.WriteString(GetFolderIndicator(node.Expanded))
	} else {
		sb.WriteString(GetFileIndicator())
	}

	// Guard state indicator
	stateStr := ft.styles.RenderGuardState(node.GuardState)
	sb.WriteString(stateStr)
	sb.WriteString(" ")

	// Name
	name := node.Name
	if node.IsDir {
		name += "/"
	}

	// Calculate available width for name
	prefixWidth := StringWidth(fn.TreePrefix) + 2 + 3 + 1 // prefix + indicator (2 chars) + guard (3 chars) + space
	availableWidth := ft.width - prefixWidth - 2          // Account for padding
	if availableWidth < 10 {
		availableWidth = 10
	}

	name = TruncateMiddle(name, availableWidth)

	// Apply styling based on node type and selection
	var nameStyle lipgloss.Style
	if node.IsSymlink {
		nameStyle = ft.styles.ItemSymlink
	} else if node.IsDir {
		nameStyle = ft.styles.ItemFolder
	} else {
		nameStyle = ft.styles.ItemFile
	}

	if selected && ft.focused {
		nameStyle = ft.styles.ItemSelected
	}

	sb.WriteString(nameStyle.Render(name))

	// Pad to fill width
	line := sb.String()
	lineWidth := StringWidth(line)
	if lineWidth < ft.width {
		line = PadRight(line, ft.width)
	}

	return line
}

// Navigation methods

func (ft *FileTree) moveCursorUp() {
	if ft.cursor > 0 {
		ft.cursor--
		ft.scroll.Update(ft.cursor, len(ft.flatNodes))
	}
}

func (ft *FileTree) moveCursorDown() {
	if ft.cursor < len(ft.flatNodes)-1 {
		ft.cursor++
		ft.scroll.Update(ft.cursor, len(ft.flatNodes))
	}
}

func (ft *FileTree) handleLeft() {
	if len(ft.flatNodes) == 0 {
		return
	}

	node := ft.flatNodes[ft.cursor].Node

	if node.IsDir && node.Expanded {
		// Collapse the folder
		node.Collapse()
		ft.refreshFlatNodes()
	} else if node.Parent != nil {
		// Go to parent
		for i, fn := range ft.flatNodes {
			if fn.Node == node.Parent {
				ft.cursor = i
				ft.scroll.Update(ft.cursor, len(ft.flatNodes))
				break
			}
		}
	}
}

func (ft *FileTree) handleRight() {
	if len(ft.flatNodes) == 0 {
		return
	}

	node := ft.flatNodes[ft.cursor].Node

	if node.IsDir && !node.IsSymlink {
		if !node.Expanded {
			// Expand the folder
			_ = node.Expand(ft.mgr)
			ft.refreshFlatNodes()
		} else if len(node.Children) > 0 {
			// Move to first child
			ft.cursor++
			ft.scroll.Update(ft.cursor, len(ft.flatNodes))
		}
	}
}

// toggleGuard toggles the guard state of the current node
func (ft *FileTree) toggleGuard() tea.Cmd {
	if len(ft.flatNodes) == 0 {
		return nil
	}

	node := ft.flatNodes[ft.cursor].Node

	// Symlinks cannot be toggled
	if node.IsSymlink {
		return nil
	}

	if node.IsDir {
		// Toggle immediate children
		return ft.toggleFolderGuard(node, false)
	}

	// Toggle file guard
	return ft.toggleFileGuard(node)
}

// toggleGuardRecursive toggles guard recursively for a folder
func (ft *FileTree) toggleGuardRecursive() tea.Cmd {
	if len(ft.flatNodes) == 0 {
		return nil
	}

	node := ft.flatNodes[ft.cursor].Node

	if !node.IsDir || node.IsSymlink {
		return nil
	}

	return ft.toggleFolderGuard(node, true)
}

// toggleFileGuard toggles the guard state of a file
func (ft *FileTree) toggleFileGuard(node *FileNode) tea.Cmd {
	if ft.mgr == nil {
		return nil
	}

	// Get current guard state before toggle (for the message)
	guard := false
	status, err := ft.mgr.GetFileStatus(node.Path)
	if err == nil && status.Registered {
		guard = status.Guard
	}

	// Use manager's ToggleFiles to toggle guard and apply filesystem permissions
	if err := ft.mgr.ToggleFiles([]string{node.Path}); err != nil {
		return func() tea.Msg { return ErrorMsg{Err: err} }
	}

	// Update node state
	node.GuardState = ComputeFileGuardState(ft.mgr, node.Path)

	return func() tea.Msg {
		return GuardToggledMsg{
			Path:          node.Path,
			IsCollection:  false,
			NewGuardState: !guard,
			AffectedFiles: 1,
		}
	}
}

// toggleFolderGuard toggles guard for files in a folder
func (ft *FileTree) toggleFolderGuard(node *FileNode, recursive bool) tea.Cmd {
	if ft.mgr == nil {
		return nil
	}

	result, err := ft.mgr.ToggleFilesInFolder(node.Path, recursive)
	if err != nil {
		return func() tea.Msg { return ErrorMsg{Err: err} }
	}
	if result == nil || result.AffectedFiles == 0 {
		return nil
	}

	// Refresh the tree
	ft.refresh()

	return func() tea.Msg {
		return GuardToggledMsg{
			Path:          node.Path,
			IsCollection:  false,
			NewGuardState: result.NewGuardState,
			AffectedFiles: result.AffectedFiles,
		}
	}
}

// refresh refreshes the tree from disk
func (ft *FileTree) refresh() {
	if ft.root == nil || ft.mgr == nil {
		return
	}

	// Reload children
	_ = ft.root.RefreshChildren(ft.mgr)
	UpdateGuardStates(ft.root, ft.mgr)
	ft.refreshFlatNodes()
}

// SetFocused sets the focus state
func (ft *FileTree) SetFocused(focused bool) {
	ft.focused = focused
}

// IsFocused returns whether the tree is focused
func (ft *FileTree) IsFocused() bool {
	return ft.focused
}

// GetSelectedNode returns the currently selected node
func (ft *FileTree) GetSelectedNode() *FileNode {
	if len(ft.flatNodes) == 0 || ft.cursor >= len(ft.flatNodes) {
		return nil
	}
	return ft.flatNodes[ft.cursor].Node
}

// SetSize sets the viewport size
func (ft *FileTree) SetSize(width, height int) {
	ft.width = width
	ft.height = height
	ft.scroll.SetViewportSize(height) // Panel already accounts for borders
}

// matchKey checks if a key message matches a key binding
func matchKey(msg tea.KeyMsg, binding key.Binding) bool {
	for _, k := range binding.Keys() {
		if msg.String() == k {
			return true
		}
	}
	return false
}
