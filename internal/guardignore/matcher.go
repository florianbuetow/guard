package guardignore

import (
	"bufio"
	"os"
	"path/filepath"
	"strings"

	"github.com/go-git/go-git/v5/plumbing/format/gitignore"
)

type IgnoreMatcher struct {
	rootDir        string
	useGitignore   bool
	useGuardignore bool
	cache          map[string][]gitignore.Pattern
}

// NewIgnoreMatcher creates a new matcher rooted at rootDir.
// useGitignore: whether to read .gitignore files.
// useGuardignore: whether to read .guardignore files.
func NewIgnoreMatcher(rootDir string, useGitignore, useGuardignore bool) *IgnoreMatcher {
	return &IgnoreMatcher{
		rootDir:        rootDir,
		useGitignore:   useGitignore,
		useGuardignore: useGuardignore,
		cache:          make(map[string][]gitignore.Pattern),
	}
}

// IsIgnored returns true if relPath should be ignored.
// relPath is relative to the matcher's root directory.
// isDir indicates whether the path is a directory.
func (m *IgnoreMatcher) IsIgnored(relPath string, isDir bool) bool {
	if !m.useGitignore && !m.useGuardignore {
		return false
	}

	normalized := filepath.ToSlash(filepath.Clean(relPath))
	if normalized == "." {
		normalized = ""
	}

	dirs := directoriesForPath(normalized)
	allPatterns := make([]gitignore.Pattern, 0)
	for _, dir := range dirs {
		allPatterns = append(allPatterns, m.loadDir(dir)...)
	}

	matcher := gitignore.NewMatcher(allPatterns)
	pathComponents := splitComponents(normalized)
	return matcher.Match(pathComponents, isDir)
}

// ClearCache invalidates all cached patterns, forcing re-reads from disk.
func (m *IgnoreMatcher) ClearCache() {
	m.cache = make(map[string][]gitignore.Pattern)
}

func (m *IgnoreMatcher) loadDir(relDir string) []gitignore.Pattern {
	if patterns, ok := m.cache[relDir]; ok {
		return patterns
	}

	absDir := filepath.Join(m.rootDir, filepath.FromSlash(relDir))
	patterns := make([]gitignore.Pattern, 0)

	if m.useGitignore {
		patterns = append(patterns, m.parseIgnoreFile(filepath.Join(absDir, ".gitignore"), relDir)...)
	}
	if m.useGuardignore {
		patterns = append(patterns, m.parseIgnoreFile(filepath.Join(absDir, ".guardignore"), relDir)...)
	}

	m.cache[relDir] = patterns
	return patterns
}

func (m *IgnoreMatcher) parseIgnoreFile(ignoreFilePath, relDir string) []gitignore.Pattern {
	f, err := os.Open(ignoreFilePath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return nil
	}
	defer f.Close()

	domain := splitComponents(filepath.ToSlash(relDir))
	patterns := make([]gitignore.Pattern, 0)
	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		p := gitignore.ParsePattern(line, domain)
		if strings.HasPrefix(line, "!") && strings.HasSuffix(line, "/") {
			patterns = append(patterns, includeDirOnlyPattern{pattern: p})
			continue
		}
		patterns = append(patterns, p)
	}

	return patterns
}

type includeDirOnlyPattern struct {
	pattern gitignore.Pattern
}

func (p includeDirOnlyPattern) Match(path []string, isDir bool) gitignore.MatchResult {
	if !isDir {
		return gitignore.NoMatch
	}
	return p.pattern.Match(path, isDir)
}

func directoriesForPath(relPath string) []string {
	dirs := []string{""}
	if relPath == "" {
		return dirs
	}

	parent := filepath.ToSlash(filepath.Dir(relPath))
	if parent == "." || parent == "" {
		return dirs
	}

	parts := strings.Split(parent, "/")
	current := ""
	for _, part := range parts {
		if part == "" {
			continue
		}
		if current == "" {
			current = part
		} else {
			current = current + "/" + part
		}
		dirs = append(dirs, current)
	}

	return dirs
}

func splitComponents(path string) []string {
	if path == "" || path == "." {
		return []string{}
	}

	parts := strings.Split(path, "/")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		if p != "" && p != "." {
			out = append(out, p)
		}
	}
	return out
}
