package manager

import (
	"os"
	"path/filepath"
	"testing"
)

func TestManager_HasRegisteredDescendants_UsesDirectoryBoundaries(t *testing.T) {
	rootDir := t.TempDir()
	guardfilePath := filepath.Join(rootDir, ".guardfile")

	barDir := filepath.Join(rootDir, "bar")
	barNestedDir := filepath.Join(barDir, "nested")
	barbazDir := filepath.Join(rootDir, "barbaz")

	if err := os.MkdirAll(barNestedDir, 0755); err != nil {
		t.Fatalf("mkdir bar/nested: %v", err)
	}
	if err := os.MkdirAll(barbazDir, 0755); err != nil {
		t.Fatalf("mkdir barbaz: %v", err)
	}

	barFile := filepath.Join(barNestedDir, "kept.txt")
	if err := os.WriteFile(barFile, []byte("tracked"), 0644); err != nil {
		t.Fatalf("write bar/nested/kept.txt: %v", err)
	}

	barbazFile := filepath.Join(barbazDir, "other.txt")
	if err := os.WriteFile(barbazFile, []byte("tracked"), 0644); err != nil {
		t.Fatalf("write barbaz/other.txt: %v", err)
	}

	mgr := NewManager(guardfilePath)
	if err := mgr.InitializeRegistry("0644", "", "", false); err != nil {
		t.Fatalf("InitializeRegistry: %v", err)
	}

	if err := mgr.AddFiles([]string{barbazFile}); err != nil {
		t.Fatalf("AddFiles barbaz/other.txt: %v", err)
	}

	if mgr.HasRegisteredDescendants(barDir) {
		t.Fatal("expected bar to have no registered descendants when only barbaz contains tracked files")
	}
	if !mgr.HasRegisteredDescendants(barbazDir) {
		t.Fatal("expected barbaz to have registered descendants")
	}

	if err := mgr.AddFiles([]string{barFile}); err != nil {
		t.Fatalf("AddFiles bar/nested/kept.txt: %v", err)
	}

	if !mgr.HasRegisteredDescendants(barDir) {
		t.Fatal("expected bar to have registered descendants after registering bar/nested/kept.txt")
	}
}

func TestManager_ReadDir_ShowsIgnoredDirectoryWithRegisteredDescendants(t *testing.T) {
	rootDir := t.TempDir()
	guardfilePath := filepath.Join(rootDir, ".guardfile")

	ignoredDir := filepath.Join(rootDir, "ignored")
	ignoredNested := filepath.Join(ignoredDir, "nested")
	if err := os.MkdirAll(ignoredNested, 0755); err != nil {
		t.Fatalf("mkdir ignored/nested: %v", err)
	}

	if err := os.WriteFile(filepath.Join(rootDir, ".guardignore"), []byte("ignored/\n"), 0644); err != nil {
		t.Fatalf("write .guardignore: %v", err)
	}

	trackedFile := filepath.Join(ignoredNested, "tracked.txt")
	if err := os.WriteFile(trackedFile, []byte("tracked"), 0644); err != nil {
		t.Fatalf("write ignored/nested/tracked.txt: %v", err)
	}

	mgr := NewManager(guardfilePath)
	if err := mgr.InitializeRegistry("0644", "", "", false); err != nil {
		t.Fatalf("InitializeRegistry: %v", err)
	}

	entries, err := mgr.ReadDir(rootDir)
	if err != nil {
		t.Fatalf("ReadDir before register: %v", err)
	}
	if containsEntryWithName(entries, "ignored") {
		t.Fatal("expected ignored directory to be hidden when it has no registered descendants")
	}

	if err := mgr.AddFiles([]string{trackedFile}); err != nil {
		t.Fatalf("AddFiles ignored/nested/tracked.txt: %v", err)
	}

	entries, err = mgr.ReadDir(rootDir)
	if err != nil {
		t.Fatalf("ReadDir after register: %v", err)
	}
	if !containsEntryWithName(entries, "ignored") {
		t.Fatal("expected ignored directory to be shown when it contains registered descendants")
	}
}

func containsEntryWithName(entries []DirEntry, name string) bool {
	for _, entry := range entries {
		if entry.Name == name {
			return true
		}
	}
	return false
}
