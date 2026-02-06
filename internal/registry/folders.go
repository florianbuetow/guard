package registry

import "fmt"

// Folder represents a dynamic folder entry in the registry
// Unlike collections, folders do not store file lists - files are scanned dynamically from disk
type Folder struct {
	Name  string `yaml:"name"`  // @path/to/folder format (with @ prefix)
	Path  string `yaml:"path"`  // relative path to folder on disk
	Guard bool   `yaml:"guard"` // guard state
}

// RegisterFolder adds a new folder entry to the registry
// name should be in @path/to/folder format
// path is the relative path to the folder on disk
// Returns an error if a folder with the same name already exists
func (r *Registry) RegisterFolder(name, path string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.folders[name]; exists {
		return fmt.Errorf("folder already registered: %s", name)
	}

	folder := &Folder{
		Name:  name,
		Path:  path,
		Guard: false,
	}

	r.folders[name] = folder
	return nil
}

// UnregisterFolder removes a folder entry from the registry
// If ignoreMissing is true, returns nil when the folder doesn't exist
// If ignoreMissing is false, returns an error when the folder doesn't exist
func (r *Registry) UnregisterFolder(name string, ignoreMissing bool) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.folders[name]; !exists {
		if ignoreMissing {
			return nil
		}
		return fmt.Errorf("folder not found: %s", name)
	}

	delete(r.folders, name)
	return nil
}

// GetFolder returns a folder entry by name, or nil if not found
func (r *Registry) GetFolder(name string) *Folder {
	r.mu.RLock()
	defer r.mu.RUnlock()

	folder, exists := r.folders[name]
	if !exists {
		return nil
	}

	// Return a copy to prevent external modification
	folderCopy := *folder
	return &folderCopy
}

// GetFolderByPath returns a folder entry by its path, or nil if not found
func (r *Registry) GetFolderByPath(path string) *Folder {
	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, folder := range r.folders {
		if folder.Path == path {
			// Return a copy to prevent external modification
			folderCopy := *folder
			return &folderCopy
		}
	}
	return nil
}

// SetFolderGuard sets the guard state of a folder
func (r *Registry) SetFolderGuard(name string, guard bool) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	folder, exists := r.folders[name]
	if !exists {
		return fmt.Errorf("folder not found: %s", name)
	}

	folder.Guard = guard
	return nil
}

// GetFolderGuard returns the guard state of a folder
func (r *Registry) GetFolderGuard(name string) (bool, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	folder, exists := r.folders[name]
	if !exists {
		return false, fmt.Errorf("folder not found: %s", name)
	}

	return folder.Guard, nil
}

// ListFolders returns all folder entries
func (r *Registry) ListFolders() []Folder {
	r.mu.RLock()
	defer r.mu.RUnlock()

	folders := make([]Folder, 0, len(r.folders))
	for _, folder := range r.folders {
		folders = append(folders, *folder)
	}
	return folders
}

// GetRegisteredFolders returns a list of all folder names
func (r *Registry) GetRegisteredFolders() []string {
	r.mu.RLock()
	defer r.mu.RUnlock()

	names := make([]string, 0, len(r.folders))
	for name := range r.folders {
		names = append(names, name)
	}
	return names
}

// IsRegisteredFolder checks if a folder entry exists by name
func (r *Registry) IsRegisteredFolder(name string) bool {
	r.mu.RLock()
	defer r.mu.RUnlock()
	_, exists := r.folders[name]
	return exists
}

// IsRegisteredFolderByPath checks if a folder entry exists by path
func (r *Registry) IsRegisteredFolderByPath(path string) bool {
	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, folder := range r.folders {
		if folder.Path == path {
			return true
		}
	}
	return false
}

// CountFolders returns the number of registered folders
func (r *Registry) CountFolders() int {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return len(r.folders)
}
