package manager

import (
	"os"
	"path/filepath"
	"strings"
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

func TestManager_CollectToggleableFilesInFolder_UsesIgnoreAwareView(t *testing.T) {
	rootDir := t.TempDir()
	guardfilePath := filepath.Join(rootDir, ".guardfile")
	treeDir := filepath.Join(rootDir, "tree")
	nestedDir := filepath.Join(treeDir, "nested")

	if err := os.MkdirAll(nestedDir, 0755); err != nil {
		t.Fatalf("mkdir tree/nested: %v", err)
	}

	writeTestFile(t, filepath.Join(rootDir, ".gitignore"), "*.log\n")
	writeTestFile(t, filepath.Join(rootDir, ".guardignore"), "*.tmp\n")
	writeTestFile(t, filepath.Join(treeDir, "root.txt"), "root")
	writeTestFile(t, filepath.Join(treeDir, "root.log"), "gitignored")
	writeTestFile(t, filepath.Join(treeDir, "root.tmp"), "guardignored")
	writeTestFile(t, filepath.Join(nestedDir, "nested.txt"), "nested")
	writeTestFile(t, filepath.Join(nestedDir, "nested.log"), "gitignored")
	writeTestFile(t, filepath.Join(nestedDir, "nested.tmp"), "guardignored")

	mgr := NewManager(guardfilePath)
	if err := mgr.InitializeRegistry("0644", "", "", false); err != nil {
		t.Fatalf("InitializeRegistry: %v", err)
	}

	immediate, err := mgr.CollectToggleableFilesInFolder(treeDir, false)
	if err != nil {
		t.Fatalf("CollectToggleableFilesInFolder immediate: %v", err)
	}
	assertSamePaths(t, immediate, []string{
		filepath.Join(treeDir, "root.txt"),
	})

	recursive, err := mgr.CollectToggleableFilesInFolder(treeDir, true)
	if err != nil {
		t.Fatalf("CollectToggleableFilesInFolder recursive: %v", err)
	}
	assertSamePaths(t, recursive, []string{
		filepath.Join(nestedDir, "nested.txt"),
		filepath.Join(treeDir, "root.txt"),
	})
}

func TestManager_CollectToggleableFilesInFolder_IncludesRegisteredIgnoredDescendants(t *testing.T) {
	rootDir := t.TempDir()
	guardfilePath := filepath.Join(rootDir, ".guardfile")
	treeDir := filepath.Join(rootDir, "tree")
	ignoredNestedDir := filepath.Join(treeDir, "ignored", "nested")

	if err := os.MkdirAll(ignoredNestedDir, 0755); err != nil {
		t.Fatalf("mkdir ignored/nested: %v", err)
	}

	writeTestFile(t, filepath.Join(rootDir, ".guardignore"), "ignored/\n*.tmp\n")
	visibleFile := filepath.Join(treeDir, "visible.txt")
	registeredIgnoredFile := filepath.Join(ignoredNestedDir, "registered.tmp")
	unregisteredIgnoredFile := filepath.Join(ignoredNestedDir, "unregistered.tmp")
	writeTestFile(t, visibleFile, "visible")
	writeTestFile(t, registeredIgnoredFile, "registered ignored")
	writeTestFile(t, unregisteredIgnoredFile, "unregistered ignored")

	mgr := NewManager(guardfilePath)
	if err := mgr.InitializeRegistry("0644", "", "", false); err != nil {
		t.Fatalf("InitializeRegistry: %v", err)
	}
	if err := mgr.AddFiles([]string{registeredIgnoredFile}); err != nil {
		t.Fatalf("AddFiles registered ignored file: %v", err)
	}

	files, err := mgr.CollectToggleableFilesInFolder(treeDir, true)
	if err != nil {
		t.Fatalf("CollectToggleableFilesInFolder recursive: %v", err)
	}
	assertSamePaths(t, files, []string{
		filepath.Join(treeDir, "visible.txt"),
		registeredIgnoredFile,
	})
}

func TestManager_CollectToggleableFilesInFolder_RespectsIgnoreConfigFlags(t *testing.T) {
	tests := []struct {
		name           string
		useGitignore   string
		useGuardignore string
		expectedNames  []string
	}{
		{
			name:           "both ignore sources active",
			useGitignore:   "true",
			useGuardignore: "true",
			expectedNames:  []string{"nested.txt", "root.txt"},
		},
		{
			name:           "gitignore inactive guardignore active",
			useGitignore:   "false",
			useGuardignore: "true",
			expectedNames:  []string{"nested.log", "nested.txt", "root.log", "root.txt"},
		},
		{
			name:           "gitignore active guardignore inactive",
			useGitignore:   "true",
			useGuardignore: "false",
			expectedNames:  []string{"nested.tmp", "nested.txt", "root.tmp", "root.txt"},
		},
		{
			name:           "both ignore sources inactive",
			useGitignore:   "false",
			useGuardignore: "false",
			expectedNames:  []string{"nested.log", "nested.tmp", "nested.txt", "root.log", "root.tmp", "root.txt"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rootDir := t.TempDir()
			guardfilePath := filepath.Join(rootDir, ".guardfile")
			treeDir := filepath.Join(rootDir, "tree")
			nestedDir := filepath.Join(treeDir, "nested")

			if err := os.MkdirAll(nestedDir, 0755); err != nil {
				t.Fatalf("mkdir tree/nested: %v", err)
			}

			writeTestFile(t, filepath.Join(rootDir, ".gitignore"), "*.log\n")
			writeTestFile(t, filepath.Join(rootDir, ".guardignore"), "*.tmp\n")
			for _, name := range []string{"root.txt", "root.log", "root.tmp"} {
				writeTestFile(t, filepath.Join(treeDir, name), name)
			}
			for _, name := range []string{"nested.txt", "nested.log", "nested.tmp"} {
				writeTestFile(t, filepath.Join(nestedDir, name), name)
			}

			mgr := NewManager(guardfilePath)
			if err := mgr.InitializeRegistry("0644", "", "", false); err != nil {
				t.Fatalf("InitializeRegistry: %v", err)
			}
			if _, err := mgr.SetConfigUseGitignore(tt.useGitignore); err != nil {
				t.Fatalf("SetConfigUseGitignore: %v", err)
			}
			if _, err := mgr.SetConfigUseGuardignore(tt.useGuardignore); err != nil {
				t.Fatalf("SetConfigUseGuardignore: %v", err)
			}

			files, err := mgr.CollectToggleableFilesInFolder(treeDir, true)
			if err != nil {
				t.Fatalf("CollectToggleableFilesInFolder recursive: %v", err)
			}

			expected := make([]string, 0, len(tt.expectedNames))
			for _, name := range tt.expectedNames {
				if strings.HasPrefix(name, "nested.") {
					expected = append(expected, filepath.Join(nestedDir, name))
				} else {
					expected = append(expected, filepath.Join(treeDir, name))
				}
			}
			assertSamePaths(t, files, expected)
		})
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

func writeTestFile(t *testing.T, path string, contents string) {
	t.Helper()
	if err := os.WriteFile(path, []byte(contents), 0644); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
}

func assertSamePaths(t *testing.T, actual []string, expected []string) {
	t.Helper()

	if len(actual) != len(expected) {
		t.Fatalf("expected %d paths, got %d\nexpected: %v\nactual:   %v", len(expected), len(actual), expected, actual)
	}

	expectedSet := make(map[string]bool, len(expected))
	for _, path := range expected {
		expectedSet[filepath.Clean(path)] = true
	}

	for _, path := range actual {
		cleanPath := filepath.Clean(path)
		if !expectedSet[cleanPath] {
			t.Fatalf("unexpected path %s in %v; expected %v", path, actual, expected)
		}
	}
}
