package manager

import "path/filepath"

import "github.com/florianbuetow/guard/internal/guardignore"

// initIgnoreMatcher initializes the ignore matcher using current config.
func (m *Manager) initIgnoreMatcher() {
	if m.security == nil {
		return
	}

	rootDir := m.security.GetGuardfileDir()
	if rootDir == "" {
		absRegistryPath, err := filepath.Abs(m.registryPath)
		if err != nil {
			return
		}
		rootDir = filepath.Dir(absRegistryPath)
	}

	m.ignoreMatcher = guardignore.NewIgnoreMatcher(
		rootDir,
		m.security.GetUseGitignore(),
		m.security.GetUseGuardignore(),
	)
}

// IsIgnored returns true when a path matches active ignore rules.
// Returns false when registry is not loaded or matcher is unavailable.
func (m *Manager) IsIgnored(path string) bool {
	if m.ignoreMatcher == nil || m.security == nil || m.fs == nil {
		return false
	}

	relPath, err := m.security.ToRelativePath(path)
	if err != nil {
		return false
	}

	isDir, err := m.fs.IsDir(path)
	if err != nil {
		isDir = false
	}

	return m.ignoreMatcher.IsIgnored(relPath, isDir)
}

// ClearIgnoreCache invalidates cached ignore patterns.
func (m *Manager) ClearIgnoreCache() {
	if m.ignoreMatcher == nil {
		return
	}
	m.ignoreMatcher.ClearCache()
}
