package manager

import (
	"os"
	"path/filepath"
	"testing"
)

func TestManager_IsIgnored_NotLoaded(t *testing.T) {
	mgr := NewManager("/nonexistent/.guardfile")
	if mgr.IsIgnored("somefile.log") {
		t.Fatal("IsIgnored should return false when registry not loaded")
	}
}

func TestManager_ReadDir_FiltersIgnoredUnlessRegistered(t *testing.T) {
	rootDir := t.TempDir()
	guardfilePath := filepath.Join(rootDir, ".guardfile")

	if err := os.WriteFile(filepath.Join(rootDir, ".guardignore"), []byte("*.log\n"), 0644); err != nil {
		t.Fatalf("write .guardignore: %v", err)
	}
	if err := os.WriteFile(filepath.Join(rootDir, "visible.txt"), []byte("ok"), 0644); err != nil {
		t.Fatalf("write visible.txt: %v", err)
	}
	ignoredPath := filepath.Join(rootDir, "hidden.log")
	if err := os.WriteFile(ignoredPath, []byte("hidden"), 0644); err != nil {
		t.Fatalf("write hidden.log: %v", err)
	}

	mgr := NewManager(guardfilePath)
	if err := mgr.InitializeRegistry("0644", "", "", false); err != nil {
		t.Fatalf("InitializeRegistry: %v", err)
	}

	entries, err := mgr.ReadDir(rootDir)
	if err != nil {
		t.Fatalf("ReadDir before register: %v", err)
	}
	if containsEntry(entries, "hidden.log") {
		t.Fatal("expected hidden.log to be filtered out when ignored and unregistered")
	}
	if !containsEntry(entries, "visible.txt") {
		t.Fatal("expected visible.txt to be shown")
	}

	if err := mgr.AddFiles([]string{ignoredPath}); err != nil {
		t.Fatalf("AddFiles hidden.log: %v", err)
	}

	entries, err = mgr.ReadDir(rootDir)
	if err != nil {
		t.Fatalf("ReadDir after register: %v", err)
	}
	if !containsEntry(entries, "hidden.log") {
		t.Fatal("expected hidden.log to be shown when registered")
	}
}

func containsEntry(entries []DirEntry, name string) bool {
	for _, entry := range entries {
		if entry.Name == name {
			return true
		}
	}
	return false
}
