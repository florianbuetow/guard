package manager

import "fmt"

// DirEntry represents a directory entry for TUI display.
type DirEntry struct {
	Name   string
	Path   string
	IsDir  bool
	IsLink bool
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
		if m.IsIgnored(entry.Path) && !m.IsRegisteredFile(entry.Path) {
			continue
		}

		result = append(result, DirEntry{
			Name:   entry.Name,
			Path:   entry.Path,
			IsDir:  entry.IsDir,
			IsLink: entry.IsLink,
		})
	}
	return result, nil
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
