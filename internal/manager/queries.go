package manager

import (
	"fmt"
	"path/filepath"
)

// FileStatus represents registry state for a file.
type FileStatus struct {
	Path       string
	Registered bool
	Guard      bool
}

// CollectionStatus represents registry state for a collection.
type CollectionStatus struct {
	Name      string
	Exists    bool
	Guard     bool
	FileCount int
	Files     []string
}

// GetFileStatus returns the registry status for a file.
func (m *Manager) GetFileStatus(path string) (FileStatus, error) {
	if m.security == nil {
		return FileStatus{}, fmt.Errorf("registry not loaded")
	}

	status := FileStatus{Path: path}
	if absPath, err := filepath.Abs(path); err == nil {
		status.Path = m.security.ToDisplayPath(absPath)
	}

	if !m.security.IsRegisteredFile(path) {
		return status, nil
	}

	guard, err := m.security.GetRegisteredFileGuard(path)
	if err != nil {
		return status, err
	}

	status.Registered = true
	status.Guard = guard
	return status, nil
}

// GetCollectionStatus returns the registry status for a collection.
func (m *Manager) GetCollectionStatus(name string, includeFiles bool) (CollectionStatus, error) {
	if m.security == nil {
		return CollectionStatus{}, fmt.Errorf("registry not loaded")
	}

	status := CollectionStatus{Name: name}
	if !m.security.IsRegisteredCollection(name) {
		return status, nil
	}

	status.Exists = true
	guard, err := m.security.GetRegisteredCollectionGuard(name)
	if err != nil {
		return status, err
	}
	status.Guard = guard

	if includeFiles {
		files, err := m.security.GetRegisteredCollectionFiles(name)
		if err != nil {
			return status, err
		}
		status.Files = files
		status.FileCount = len(files)
		return status, nil
	}

	count, err := m.security.CountFilesInCollection(name)
	if err != nil {
		return status, err
	}
	status.FileCount = count
	return status, nil
}

// GetCollectionsContainingFile returns collection names that contain the file.
func (m *Manager) GetCollectionsContainingFile(path string) ([]string, error) {
	if m.security == nil {
		return nil, fmt.Errorf("registry not loaded")
	}

	absPath, err := filepath.Abs(path)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve path: %w", err)
	}

	var result []string
	for _, name := range m.security.GetRegisteredCollections() {
		files, err := m.security.GetRegisteredCollectionFiles(name)
		if err != nil {
			return nil, fmt.Errorf("failed to get files for collection %s: %w", name, err)
		}
		for _, filePath := range files {
			if filePath == absPath {
				result = append(result, name)
				break
			}
		}
	}
	return result, nil
}

// GetRegisteredCollections returns all registered collection names.
func (m *Manager) GetRegisteredCollections() ([]string, error) {
	if m.security == nil {
		return nil, fmt.Errorf("registry not loaded")
	}
	return m.security.GetRegisteredCollections(), nil
}
