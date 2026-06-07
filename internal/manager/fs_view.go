package manager

import (
	"fmt"
	"path/filepath"
	"strings"
)

// DirEntry represents a directory entry for TUI display.
type DirEntry struct {
	Name      string
	Path      string
	IsDir     bool
	IsLink    bool
	IsIgnored bool
}

// ReadDir reads a directory and returns entries for display.
func (m *Manager) ReadDir(path string) ([]DirEntry, error) {
	if m.fs == nil {
		return nil, fmt.Errorf("filesystem not available")
	}

	entries, err := m.fs.ReadDir(path)
	if err != nil {
		return nil, err
	}

	result := make([]DirEntry, 0, len(entries))
	for _, entry := range entries {
		if entry.Name == ".guardignore" && !m.IsRegisteredFile(entry.Path) {
			continue
		}

		ignored := m.IsIgnored(entry.Path)
		if ignored && !m.IsRegisteredFile(entry.Path) {
			if !entry.IsDir || !m.HasRegisteredDescendants(entry.Path) {
				continue
			}
		}

		result = append(result, DirEntry{
			Name:      entry.Name,
			Path:      entry.Path,
			IsDir:     entry.IsDir,
			IsLink:    entry.IsLink,
			IsIgnored: ignored,
		})
	}
	return result, nil
}

// HasRegisteredDescendants returns true if dirPath contains registered files.
func (m *Manager) HasRegisteredDescendants(dirPath string) bool {
	if m.security == nil {
		return false
	}

	absDirPath, err := filepath.Abs(dirPath)
	if err != nil {
		return false
	}

	dirPrefix := filepath.Clean(absDirPath)
	if !strings.HasSuffix(dirPrefix, string(filepath.Separator)) {
		dirPrefix += string(filepath.Separator)
	}

	for _, registeredPath := range m.security.GetRegisteredFiles() {
		if strings.HasPrefix(filepath.Clean(registeredPath), dirPrefix) {
			return true
		}
	}

	return false
}

// CollectImmediateFiles returns immediate files in a directory.
func (m *Manager) CollectImmediateFiles(path string) ([]string, error) {
	if m.fs == nil {
		return nil, fmt.Errorf("filesystem not available")
	}
	return m.fs.CollectImmediateFiles(path)
}

// CollectFilesRecursive returns all files in a directory tree.
func (m *Manager) CollectFilesRecursive(path string) ([]string, error) {
	if m.fs == nil {
		return nil, fmt.Errorf("filesystem not available")
	}
	return m.fs.CollectFilesRecursive(path)
}

// CollectToggleableFilesInFolder returns regular, non-symlink files eligible for
// TUI folder toggles. It uses ReadDir so active ignore config is applied in the
// same way as the visible file tree.
func (m *Manager) CollectToggleableFilesInFolder(path string, recursive bool) ([]string, error) {
	entries, err := m.ReadDir(path)
	if err != nil {
		return nil, err
	}

	var files []string
	for _, entry := range entries {
		if entry.IsLink {
			continue
		}
		if entry.IsDir {
			if recursive {
				childFiles, err := m.CollectToggleableFilesInFolder(entry.Path, true)
				if err != nil {
					return nil, err
				}
				files = append(files, childFiles...)
			}
			continue
		}

		files = append(files, entry.Path)
	}

	return files, nil
}
