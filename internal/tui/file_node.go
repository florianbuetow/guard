package tui

import (
	"fmt"
	"path/filepath"

	"github.com/florianbuetow/guard/internal/manager"
)

// FileNode represents a file or folder in the tree
type FileNode struct {
	Name       string
	Path       string
	IsDir      bool
	IsSymlink  bool
	Expanded   bool
	Depth      int
	GuardState GuardState
	Children   []*FileNode
	Parent     *FileNode

	// For rendering
	IsLastChild  bool
	AncestorLast []bool // Track if ancestors are last children
}

// NewFileNode creates a new file node
func NewFileNode(name, path string, isDir, isSymlink bool, depth int, parent *FileNode) *FileNode {
	var ancestorLast []bool
	if parent != nil {
		ancestorLast = make([]bool, len(parent.AncestorLast)+1)
		copy(ancestorLast, parent.AncestorLast)
	}

	return &FileNode{
		Name:         name,
		Path:         path,
		IsDir:        isDir,
		IsSymlink:    isSymlink,
		Depth:        depth,
		Parent:       parent,
		AncestorLast: ancestorLast,
	}
}

// BuildFileTree builds a tree of FileNodes from a root directory
func BuildFileTree(rootPath string, mgr *manager.Manager) (*FileNode, error) {
	if mgr == nil {
		return nil, fmt.Errorf("manager is nil")
	}

	// Get the base name of the root
	absPath, err := filepath.Abs(rootPath)
	if err != nil {
		return nil, err
	}

	baseName := filepath.Base(absPath)
	root := NewFileNode(baseName, absPath, true, false, 0, nil)
	root.Expanded = true // Root is always expanded

	// Populate children
	if err := populateChildren(root, mgr); err != nil {
		return nil, err
	}

	return root, nil
}

// populateChildren populates the children of a directory node
func populateChildren(node *FileNode, mgr *manager.Manager) error {
	if !node.IsDir {
		return nil
	}

	if mgr == nil {
		return fmt.Errorf("manager is nil")
	}

	entries, err := mgr.ReadDir(node.Path)
	if err != nil {
		return err
	}

	for i, entry := range entries {
		child := NewFileNode(entry.Name, entry.Path, entry.IsDir, entry.IsLink, node.Depth+1, node)
		child.IsLastChild = i == len(entries)-1

		// Update ancestor tracking
		if len(child.AncestorLast) > 0 {
			child.AncestorLast[len(child.AncestorLast)-1] = node.IsLastChild
		}
		child.AncestorLast = append(child.AncestorLast, child.IsLastChild)

		// Compute guard state for files
		if !entry.IsDir && !entry.IsLink {
			child.GuardState = ComputeFileGuardState(mgr, entry.Path)
		}

		node.Children = append(node.Children, child)
	}

	return nil
}

// RefreshChildren refreshes the children of a node while preserving expansion state
func (n *FileNode) RefreshChildren(mgr *manager.Manager) error {
	// Save expansion state of the ENTIRE subtree before refreshing
	expansionState := make(map[string]bool)
	collectExpansionState(n, expansionState)

	// Clear and repopulate children
	n.Children = nil
	if err := populateChildren(n, mgr); err != nil {
		return err
	}

	// Restore expansion state for all directories in the subtree
	restoreExpansionState(n, expansionState, mgr)

	return nil
}

// collectExpansionState recursively collects expansion state from the entire subtree
func collectExpansionState(node *FileNode, state map[string]bool) {
	for _, child := range node.Children {
		if child.IsDir && child.Expanded {
			state[child.Path] = true
			collectExpansionState(child, state)
		}
	}
}

// restoreExpansionState recursively restores expansion state and populates children.
// Errors from populateChildren leave the directory collapsed rather than silently empty.
func restoreExpansionState(node *FileNode, state map[string]bool, mgr *manager.Manager) {
	for _, child := range node.Children {
		if child.IsDir {
			if state[child.Path] {
				if err := populateChildren(child, mgr); err != nil {
					// Leave collapsed rather than showing an empty expanded dir
					child.Expanded = false
					continue
				}
				child.Expanded = true
				restoreExpansionState(child, state, mgr)
			}
		}
	}
}

// Expand expands the node if it's a directory
func (n *FileNode) Expand(mgr *manager.Manager) error {
	if !n.IsDir || n.IsSymlink {
		return nil
	}

	if !n.Expanded {
		n.Expanded = true
		// Load children if not already loaded
		if len(n.Children) == 0 {
			return populateChildren(n, mgr)
		}
	}

	return nil
}

// Collapse collapses the node
func (n *FileNode) Collapse() {
	n.Expanded = false
}

// Toggle toggles the expansion state
func (n *FileNode) Toggle(mgr *manager.Manager) error {
	if n.Expanded {
		n.Collapse()
		return nil
	}
	return n.Expand(mgr)
}

// FlattenedNode represents a node in the flattened list with rendering info
type FlattenedNode struct {
	Node       *FileNode
	TreePrefix string
	Index      int
}

// Flatten returns a flat list of visible nodes for rendering
func Flatten(root *FileNode) []FlattenedNode {
	if root == nil {
		return nil
	}

	var result []FlattenedNode
	flattenNode(root, &result, 0)
	return result
}

// flattenNode recursively flattens visible nodes
func flattenNode(node *FileNode, result *[]FlattenedNode, index int) int {
	// Build tree prefix
	prefix := BuildTreePrefix(node.Depth, node.AncestorLast)

	*result = append(*result, FlattenedNode{
		Node:       node,
		TreePrefix: prefix,
		Index:      index,
	})
	index++

	// If expanded, add children
	if node.IsDir && node.Expanded {
		for _, child := range node.Children {
			index = flattenNode(child, result, index)
		}
	}

	return index
}

// FindNodeByPath finds a node by its path
func FindNodeByPath(root *FileNode, path string) *FileNode {
	if root == nil {
		return nil
	}

	if root.Path == path {
		return root
	}

	for _, child := range root.Children {
		if found := FindNodeByPath(child, path); found != nil {
			return found
		}
	}

	return nil
}

// GetVisibleNodes returns only the visible nodes based on expansion state
func GetVisibleNodes(root *FileNode) []*FileNode {
	if root == nil {
		return nil
	}

	var result []*FileNode
	collectVisible(root, &result)
	return result
}

func collectVisible(node *FileNode, result *[]*FileNode) {
	*result = append(*result, node)

	if node.IsDir && node.Expanded {
		for _, child := range node.Children {
			collectVisible(child, result)
		}
	}
}

// UpdateGuardStates updates the guard states for all nodes
func UpdateGuardStates(root *FileNode, mgr *manager.Manager) {
	if root == nil {
		return
	}

	updateNodeGuardState(root, mgr)
}

func updateNodeGuardState(node *FileNode, mgr *manager.Manager) {
	if node.IsDir {
		// Compute folder guard state based on immediate children
		var files []string
		if len(node.Children) > 0 {
			// Folder is expanded - use loaded children
			for _, child := range node.Children {
				if !child.IsDir && !child.IsSymlink {
					files = append(files, child.Path)
				}
			}
		} else if mgr != nil {
			// Folder is collapsed - get files from disk
			diskFiles, err := mgr.CollectImmediateFiles(node.Path)
			if err == nil {
				files = diskFiles
			}
		}
		node.GuardState = ComputeEffectiveFolderGuardState(mgr, files, "")
	} else if !node.IsSymlink {
		node.GuardState = ComputeFileGuardState(mgr, node.Path)
	}

	// Recurse into children
	for _, child := range node.Children {
		updateNodeGuardState(child, mgr)
	}
}
