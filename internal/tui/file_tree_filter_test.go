package tui

import "testing"

func TestMarkDescendantsVisible_SkipsSymlinkCycles(t *testing.T) {
	root := &FileNode{Name: "root", IsDir: true}
	realDir := &FileNode{Name: "real", IsDir: true, Parent: root}
	symlinkDir := &FileNode{Name: "link", IsDir: true, IsSymlink: true, Parent: root}

	root.Children = []*FileNode{realDir, symlinkDir}
	// Simulate a symlink cycle back to root.
	symlinkDir.Children = []*FileNode{root}

	visible := map[*FileNode]bool{root: true}
	markDescendantsVisible(root, visible)

	if !visible[realDir] {
		t.Fatal("expected real directory to be marked visible")
	}
	if !visible[symlinkDir] {
		t.Fatal("expected symlink directory node to be marked visible")
	}
	if len(visible) != 3 {
		t.Fatalf("unexpected visible set size, got %d", len(visible))
	}
}

func TestMarkDescendantsVisible_BreaksGeneralCycles(t *testing.T) {
	a := &FileNode{Name: "a", IsDir: true}
	b := &FileNode{Name: "b", IsDir: true, Parent: a}
	c := &FileNode{Name: "c", IsDir: true, Parent: b}

	a.Children = []*FileNode{b}
	b.Children = []*FileNode{c}
	c.Children = []*FileNode{b} // cycle: b -> c -> b

	visible := map[*FileNode]bool{a: true}
	markDescendantsVisible(a, visible)

	if !visible[b] || !visible[c] {
		t.Fatal("expected cyclic descendants to be marked visible without infinite recursion")
	}
}
