package guardignore

import (
	"os"
	"path/filepath"
	"testing"
)

// setupTestTree creates the canonical directory structure in the given root.
// It creates all files and directories but NO ignore files — those are set per test.
func setupTestTree(t *testing.T, root string) {
	t.Helper()

	// Files in root
	files := []string{
		"README.md",
		"main.go",
		"debug.log",
		"temp.tmp",
		"important.log",
	}

	// Files in subdirectories
	dirFiles := map[string][]string{
		"src":        {"app.go", "app_test.go", "cache.dat"},
		"src/vendor": {"lib.go", "lib.min.js", "generated.pb.go"},
		"build":      {"output.bin", "report.html"},
		"docs":       {"guide.md", "draft.tmp"},
		"config":     {"settings.yaml", "secrets.env"},
	}

	for _, f := range files {
		writeFile(t, filepath.Join(root, f), "")
	}
	for dir, dirFileList := range dirFiles {
		for _, f := range dirFileList {
			writeFile(t, filepath.Join(root, dir, f), "")
		}
	}
}

// writeFile creates a file (and its parent dirs) with the given content.
func writeFile(t *testing.T, path, content string) {
	t.Helper()
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		t.Fatalf("MkdirAll %s: %v", dir, err)
	}
	if err := os.WriteFile(path, []byte(content), 0644); err != nil {
		t.Fatalf("WriteFile %s: %v", path, err)
	}
}

func assertIgnored(t *testing.T, m *IgnoreMatcher, relPath string, isDir bool, want bool) {
	t.Helper()
	got := m.IsIgnored(relPath, isDir)
	if got != want {
		t.Fatalf("IsIgnored(%q, isDir=%v) = %v, want %v", relPath, isDir, got, want)
	}
}

func canonicalFiles() []string {
	return []string{
		"README.md",
		"main.go",
		"debug.log",
		"temp.tmp",
		"important.log",
		"src/app.go",
		"src/app_test.go",
		"src/cache.dat",
		"src/vendor/lib.go",
		"src/vendor/lib.min.js",
		"src/vendor/generated.pb.go",
		"build/output.bin",
		"build/report.html",
		"docs/guide.md",
		"docs/draft.tmp",
		"config/settings.yaml",
		"config/secrets.env",
	}
}

func assertEveryFileNotIgnored(t *testing.T, m *IgnoreMatcher) {
	t.Helper()
	for _, f := range canonicalFiles() {
		assertIgnored(t, m, f, false, false)
	}
}

func TestIgnoreMatcher_NoIgnoreFiles_NothingIgnored(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)

	m := NewIgnoreMatcher(root, true, true)

	assertIgnored(t, m, "README.md", false, false)
	assertIgnored(t, m, "main.go", false, false)
	assertIgnored(t, m, "debug.log", false, false)
	assertIgnored(t, m, "src/app.go", false, false)
	assertIgnored(t, m, "src/vendor/lib.go", false, false)
	assertIgnored(t, m, "build/output.bin", false, false)
	assertIgnored(t, m, "docs/guide.md", false, false)
	assertIgnored(t, m, "config/secrets.env", false, false)
}

func TestIgnoreMatcher_RootGitignore_BasicGlobPatterns(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)
	writeFile(t, filepath.Join(root, ".gitignore"), "*.log\n*.tmp\nbuild/\n")

	m := NewIgnoreMatcher(root, true, true)

	assertIgnored(t, m, "debug.log", false, true)
	assertIgnored(t, m, "important.log", false, true)
	assertIgnored(t, m, "temp.tmp", false, true)
	assertIgnored(t, m, "docs/draft.tmp", false, true)
	assertIgnored(t, m, "build", true, true)
	assertIgnored(t, m, "build/output.bin", false, true)
	assertIgnored(t, m, "build/report.html", false, true)
	assertIgnored(t, m, "README.md", false, false)
	assertIgnored(t, m, "main.go", false, false)
	assertIgnored(t, m, "src/app.go", false, false)
	assertIgnored(t, m, "src/vendor/lib.go", false, false)
	assertIgnored(t, m, "config/settings.yaml", false, false)
}

func TestIgnoreMatcher_RootGuardignoreOnly(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)
	writeFile(t, filepath.Join(root, ".guardignore"), "*.env\n*.dat\n")

	m := NewIgnoreMatcher(root, true, true)

	assertIgnored(t, m, "config/secrets.env", false, true)
	assertIgnored(t, m, "src/cache.dat", false, true)
	assertIgnored(t, m, "debug.log", false, false)
	assertIgnored(t, m, "main.go", false, false)
	assertIgnored(t, m, "src/app.go", false, false)
}

func TestIgnoreMatcher_RootGitignoreAndGuardignore_StackedSameDirectory(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)
	writeFile(t, filepath.Join(root, ".gitignore"), "*.log\n")
	writeFile(t, filepath.Join(root, ".guardignore"), "!important.log\n*.tmp\n")

	m := NewIgnoreMatcher(root, true, true)

	assertIgnored(t, m, "debug.log", false, true)
	assertIgnored(t, m, "important.log", false, false)
	assertIgnored(t, m, "temp.tmp", false, true)
	assertIgnored(t, m, "docs/draft.tmp", false, true)
	assertIgnored(t, m, "main.go", false, false)
	assertIgnored(t, m, "src/app.go", false, false)
}

func TestIgnoreMatcher_SubdirectoryGuardignoreNegatesRootGitignore(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)
	writeFile(t, filepath.Join(root, ".gitignore"), "*.dat\n*.min.js\n")
	writeFile(t, filepath.Join(root, "src/vendor/.guardignore"), "!lib.min.js\n")

	m := NewIgnoreMatcher(root, true, true)

	assertIgnored(t, m, "src/cache.dat", false, true)
	assertIgnored(t, m, "src/vendor/lib.min.js", false, false)
	assertIgnored(t, m, "main.go", false, false)
	assertIgnored(t, m, "src/app.go", false, false)
	assertIgnored(t, m, "src/vendor/lib.go", false, false)
}

func TestIgnoreMatcher_SubdirectoryGitignoreAddsRules(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)
	writeFile(t, filepath.Join(root, ".gitignore"), "*.log\n")
	writeFile(t, filepath.Join(root, "src/.gitignore"), "*_test.go\n")

	m := NewIgnoreMatcher(root, true, true)

	assertIgnored(t, m, "debug.log", false, true)
	assertIgnored(t, m, "src/app_test.go", false, true)
	assertIgnored(t, m, "src/app.go", false, false)
	assertIgnored(t, m, "src/vendor/lib.go", false, false)
	assertIgnored(t, m, "main.go", false, false)
}

func TestIgnoreMatcher_DeepNesting_ThreeLevels(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)
	writeFile(t, filepath.Join(root, ".gitignore"), "*.tmp\n")
	writeFile(t, filepath.Join(root, ".guardignore"), "*.env\n")
	writeFile(t, filepath.Join(root, "src/.gitignore"), "*_test.go\n")
	writeFile(t, filepath.Join(root, "src/vendor/.guardignore"), "generated.pb.go\n")

	m := NewIgnoreMatcher(root, true, true)

	assertIgnored(t, m, "temp.tmp", false, true)
	assertIgnored(t, m, "docs/draft.tmp", false, true)
	assertIgnored(t, m, "config/secrets.env", false, true)
	assertIgnored(t, m, "src/app_test.go", false, true)
	assertIgnored(t, m, "src/vendor/generated.pb.go", false, true)
	assertIgnored(t, m, "src/vendor/lib.go", false, false)
	assertIgnored(t, m, "src/vendor/lib.min.js", false, false)
	assertIgnored(t, m, "main.go", false, false)
	assertIgnored(t, m, "src/app.go", false, false)
}

func TestIgnoreMatcher_GitignoreDisabled_OnlyGuardignoreActive(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)
	writeFile(t, filepath.Join(root, ".gitignore"), "*.log\nbuild/\n")
	writeFile(t, filepath.Join(root, ".guardignore"), "*.tmp\n")

	m := NewIgnoreMatcher(root, false, true)

	assertIgnored(t, m, "debug.log", false, false)
	assertIgnored(t, m, "build", true, false)
	assertIgnored(t, m, "temp.tmp", false, true)
	assertIgnored(t, m, "docs/draft.tmp", false, true)
	assertIgnored(t, m, "main.go", false, false)
}

func TestIgnoreMatcher_GuardignoreDisabled_OnlyGitignoreActive(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)
	writeFile(t, filepath.Join(root, ".gitignore"), "*.log\n")
	writeFile(t, filepath.Join(root, ".guardignore"), "*.tmp\n")

	m := NewIgnoreMatcher(root, true, false)

	assertIgnored(t, m, "debug.log", false, true)
	assertIgnored(t, m, "temp.tmp", false, false)
	assertIgnored(t, m, "main.go", false, false)
}

func TestIgnoreMatcher_BothDisabled_NothingIgnored(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)
	writeFile(t, filepath.Join(root, ".gitignore"), "*.log\n")
	writeFile(t, filepath.Join(root, ".guardignore"), "*.tmp\n")

	m := NewIgnoreMatcher(root, false, false)

	assertIgnored(t, m, "debug.log", false, false)
	assertIgnored(t, m, "temp.tmp", false, false)
	assertIgnored(t, m, "main.go", false, false)
	assertEveryFileNotIgnored(t, m)
}

func TestIgnoreMatcher_GuardignoreNegatesGitignoreInSameDirectory(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)
	writeFile(t, filepath.Join(root, ".gitignore"), "*.log\n*.env\nconfig/\n")
	writeFile(t, filepath.Join(root, ".guardignore"), "!config/\n!config/settings.yaml\n")

	m := NewIgnoreMatcher(root, true, true)

	assertIgnored(t, m, "debug.log", false, true)
	assertIgnored(t, m, "config", true, false)
	assertIgnored(t, m, "config/settings.yaml", false, false)
	assertIgnored(t, m, "config/secrets.env", false, true)
}

func TestIgnoreMatcher_ChildGuardignoreNegatesParentGuardignore(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)
	writeFile(t, filepath.Join(root, ".guardignore"), "*.dat\n")
	writeFile(t, filepath.Join(root, "src/.guardignore"), "!cache.dat\n")

	m := NewIgnoreMatcher(root, false, true)

	assertIgnored(t, m, "src/cache.dat", false, false)
	assertIgnored(t, m, "main.go", false, false)
}

func TestIgnoreMatcher_CommentAndBlankLinesIgnored(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)
	writeFile(t, filepath.Join(root, ".gitignore"), "# This is a comment\n\n*.log\n\n# Another comment\n\n# *.go  <-- this should NOT match .go files\n")

	m := NewIgnoreMatcher(root, true, true)

	assertIgnored(t, m, "debug.log", false, true)
	assertIgnored(t, m, "main.go", false, false)
	assertIgnored(t, m, "src/app.go", false, false)
}

func TestIgnoreMatcher_DoubleStarPatterns(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)
	writeFile(t, filepath.Join(root, ".gitignore"), "**/vendor/\n**/generated.pb.go\n")

	m := NewIgnoreMatcher(root, true, true)

	assertIgnored(t, m, "src/vendor", true, true)
	assertIgnored(t, m, "src/vendor/lib.go", false, true)
	assertIgnored(t, m, "src/vendor/lib.min.js", false, true)
	assertIgnored(t, m, "src/vendor/generated.pb.go", false, true)
	assertIgnored(t, m, "main.go", false, false)
	assertIgnored(t, m, "src/app.go", false, false)
}

func TestIgnoreMatcher_DirectoryPatternVsFilePattern(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)
	writeFile(t, filepath.Join(root, ".gitignore"), "build/\ndocs\n")

	m := NewIgnoreMatcher(root, true, true)

	assertIgnored(t, m, "build", true, true)
	assertIgnored(t, m, "build/output.bin", false, true)
	assertIgnored(t, m, "docs", true, true)
	assertIgnored(t, m, "docs/guide.md", false, true)
}

func TestIgnoreMatcher_CachePersistence_SamePatternsAcrossCalls(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)
	writeFile(t, filepath.Join(root, ".gitignore"), "*.log\n")

	m := NewIgnoreMatcher(root, true, true)

	assertIgnored(t, m, "debug.log", false, true)
	assertIgnored(t, m, "important.log", false, true)
	assertIgnored(t, m, "main.go", false, false)
}

func TestIgnoreMatcher_CacheInvalidation_ClearCacheCausesReread(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)
	gitignorePath := filepath.Join(root, ".gitignore")
	writeFile(t, gitignorePath, "*.log\n")

	m := NewIgnoreMatcher(root, true, true)

	assertIgnored(t, m, "debug.log", false, true)
	m.ClearCache()
	writeFile(t, gitignorePath, "*.tmp\n")
	assertIgnored(t, m, "debug.log", false, false)
	assertIgnored(t, m, "temp.tmp", false, true)
}

func TestIgnoreMatcher_SymlinkedGuardignore(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)

	gitignorePath := filepath.Join(root, ".gitignore")
	guardignorePath := filepath.Join(root, ".guardignore")
	writeFile(t, gitignorePath, "*.log\n")
	if err := os.Symlink(".gitignore", guardignorePath); err != nil {
		t.Fatalf("Symlink %s -> .gitignore: %v", guardignorePath, err)
	}

	m := NewIgnoreMatcher(root, true, true)

	assertIgnored(t, m, "debug.log", false, true)
	assertIgnored(t, m, "main.go", false, false)
}

func TestIgnoreMatcher_MixedIgnoreFilesDifferentLevels(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)

	writeFile(t, filepath.Join(root, ".gitignore"), "*.log\n*.tmp\n")
	writeFile(t, filepath.Join(root, ".guardignore"), "!important.log\n*.env\n")
	writeFile(t, filepath.Join(root, "src/.gitignore"), "*_test.go\n")
	writeFile(t, filepath.Join(root, "src/vendor/.guardignore"), "!generated.pb.go\n")

	m := NewIgnoreMatcher(root, true, true)

	assertIgnored(t, m, "README.md", false, false)
	assertIgnored(t, m, "main.go", false, false)
	assertIgnored(t, m, "debug.log", false, true)
	assertIgnored(t, m, "temp.tmp", false, true)
	assertIgnored(t, m, "important.log", false, false)
	assertIgnored(t, m, "src/app.go", false, false)
	assertIgnored(t, m, "src/app_test.go", false, true)
	assertIgnored(t, m, "src/cache.dat", false, false)
	assertIgnored(t, m, "src/vendor/lib.go", false, false)
	assertIgnored(t, m, "src/vendor/lib.min.js", false, false)
	assertIgnored(t, m, "src/vendor/generated.pb.go", false, false)
	assertIgnored(t, m, "build/output.bin", false, false)
	assertIgnored(t, m, "build/report.html", false, false)
	assertIgnored(t, m, "docs/guide.md", false, false)
	assertIgnored(t, m, "docs/draft.tmp", false, true)
	assertIgnored(t, m, "config/settings.yaml", false, false)
	assertIgnored(t, m, "config/secrets.env", false, true)
}

func TestIgnoreMatcher_EmptyIgnoreFiles(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)
	writeFile(t, filepath.Join(root, ".gitignore"), "")
	writeFile(t, filepath.Join(root, ".guardignore"), "")

	m := NewIgnoreMatcher(root, true, true)

	assertEveryFileNotIgnored(t, m)
}

func TestIgnoreMatcher_GuardignoreOnlyComments(t *testing.T) {
	root := t.TempDir()
	setupTestTree(t, root)
	writeFile(t, filepath.Join(root, ".guardignore"), "# .guardignore works like .gitignore\n# By default guard also uses your .gitignore files (see use_gitignore in .guardfile)\n# Or add your custom ignore rules below\n")

	m := NewIgnoreMatcher(root, true, true)

	assertEveryFileNotIgnored(t, m)
}
