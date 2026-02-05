package architecture

import (
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestLayering_NoTuiFilesystemImports(t *testing.T) {
	repo := repoRoot(t)
	tuiDir := filepath.Join(repo, "internal", "tui")
	forbidden := []string{"/internal/filesystem"}
	assertNoForbiddenStrings(t, tuiDir, forbidden)
}

func TestLayering_NoCliRegistryAccess(t *testing.T) {
	repo := repoRoot(t)
	cmdDir := filepath.Join(repo, "cmd", "guard", "commands")
	forbidden := []string{"GetRegistry(", "/internal/registry", "/internal/security"}
	assertNoForbiddenStrings(t, cmdDir, forbidden)
}

func TestLayering_NoPrintingInManagerOrFilesystem(t *testing.T) {
	repo := repoRoot(t)
	forbidden := []string{"fmt.Print"}

	managerDir := filepath.Join(repo, "internal", "manager")
	assertNoForbiddenStrings(t, managerDir, forbidden)

	filesystemDir := filepath.Join(repo, "internal", "filesystem")
	assertNoForbiddenStrings(t, filesystemDir, forbidden)
}

func assertNoForbiddenStrings(t *testing.T, dir string, forbidden []string) {
	t.Helper()
	files, err := collectGoFiles(dir)
	if err != nil {
		t.Fatalf("collect go files: %v", err)
	}
	for _, path := range files {
		content, err := os.ReadFile(path)
		if err != nil {
			t.Fatalf("read file %s: %v", path, err)
		}
		text := string(content)
		for _, needle := range forbidden {
			if strings.Contains(text, needle) {
				rel, relErr := filepath.Rel(dir, path)
				if relErr != nil {
					rel = path
				}
				t.Errorf("%s contains forbidden string %q", rel, needle)
			}
		}
	}
}

func collectGoFiles(dir string) ([]string, error) {
	var files []string
	walkErr := filepath.WalkDir(dir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			if strings.HasPrefix(d.Name(), ".") {
				return filepath.SkipDir
			}
			return nil
		}
		if strings.HasSuffix(d.Name(), ".go") {
			files = append(files, path)
		}
		return nil
	})
	if walkErr != nil {
		return nil, walkErr
	}
	return files, nil
}

func repoRoot(t *testing.T) string {
	t.Helper()
	dir, err := os.Getwd()
	if err != nil {
		t.Fatalf("getwd: %v", err)
	}
	for {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			t.Fatalf("go.mod not found from %s", dir)
		}
		dir = parent
	}
}
