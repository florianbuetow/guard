package registry

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"sync"

	"gopkg.in/yaml.v3"
)

// RegistryDefaults holds default values for guard settings
type RegistryDefaults struct {
	GuardMode  string // Octal string like "0640"
	GuardOwner string
	GuardGroup string
}

// LastToggle tracks the last toggled item for quick re-toggle
type LastToggle struct {
	Name string `yaml:"name"`
	Type string `yaml:"type"` // "file" or "collection"
}

// Config represents the registry configuration
type Config struct {
	GuardFileMode  string      `yaml:"guard_mode"`
	GuardOwner     string      `yaml:"guard_owner"`
	GuardGroup     string      `yaml:"guard_group"`
	LastToggle     *LastToggle `yaml:"last_toggle,omitempty"`
	UseGitignore   *bool       `yaml:"use_gitignore,omitempty"`
	UseGuardignore *bool       `yaml:"use_guardignore,omitempty"`
}

func (c *Config) GetUseGitignore() bool {
	if c.UseGitignore == nil {
		return true
	}
	return *c.UseGitignore
}

func (c *Config) GetUseGuardignore() bool {
	if c.UseGuardignore == nil {
		return true
	}
	return *c.UseGuardignore
}

func boolPtr(b bool) *bool {
	return &b
}

// FileEntry represents a registered file in the registry
type FileEntry struct {
	Path     string `yaml:"path"`
	FileMode string `yaml:"mode"`
	Owner    string `yaml:"owner"`
	Group    string `yaml:"group"`
	Guard    bool   `yaml:"guard"`
}

// Collection represents a group of files that can be toggled together
type Collection struct {
	Name          string   `yaml:"name"`
	Files         []string `yaml:"files"`
	Guard         bool     `yaml:"guard"`
	GuardFileMode string   `yaml:"guard_mode,omitempty"`
	GuardOwner    string   `yaml:"guard_owner,omitempty"`
	GuardGroup    string   `yaml:"guard_group,omitempty"`
}

// Registry manages the file tracking system
type Registry struct {
	mu           sync.RWMutex
	registryPath string
	entries      map[string]*FileEntry  // key is the file path
	collections  map[string]*Collection // key is the collection name
	folders      map[string]*Folder     // key is the folder name (@path/to/folder)
	config       Config
}

// RegistryData is used for YAML serialization
type RegistryData struct {
	Config      Config       `yaml:"config"`
	Files       []FileEntry  `yaml:"files"`
	Collections []Collection `yaml:"collections"`
	Folders     []Folder     `yaml:"folders"`
}

// NewRegistry creates a new empty registry instance with the given defaults
// The registry is not loaded from disk. Use LoadRegistry to load an existing registry file.
// defaults must not be nil - all default values must be explicitly provided
// If the registry file already exists and overwrite is false, returns an error
func NewRegistry(registryPath string, defaults *RegistryDefaults, overwrite bool) (*Registry, error) {
	// Check if file path empty
	if err := validateRegistryPath(registryPath); err != nil {
		return nil, err
	}

	// Check if file already exists
	if _, err := os.Stat(registryPath); err == nil {
		// File exists
		if !overwrite {
			return nil, fmt.Errorf("registry file already exists: %s (use overwrite=true to replace)", registryPath)
		}
	} else if !os.IsNotExist(err) {
		// Some other error occurred (permission denied, etc.)
		return nil, fmt.Errorf("failed to check registry file: %w", err)
	}

	// Validate defaults parameter
	if defaults == nil {
		return nil, fmt.Errorf("defaults parameter is required")
	}

	// Normalize and validate the guard mode
	// Convert mode string to os.FileMode, then back to normalized 4-digit string
	mode, err := octalStringToFileMode(defaults.GuardMode)
	if err != nil {
		return nil, fmt.Errorf("Invalid mode '%s'. Mode must be an octal number between 000 and 777", defaults.GuardMode)
	}
	normalizedMode := fileModeToOctalString(mode)

	// Create config with normalized mode
	tempConfig := Config{
		GuardFileMode:  normalizedMode,
		GuardOwner:     defaults.GuardOwner,
		GuardGroup:     defaults.GuardGroup,
		UseGitignore:   boolPtr(true),
		UseGuardignore: boolPtr(true),
	}
	if err := validateConfig(tempConfig); err != nil {
		return nil, fmt.Errorf("invalid default config: %w", err)
	}

	return &Registry{
		registryPath: registryPath,
		config:       tempConfig,
		entries:      make(map[string]*FileEntry),
		collections:  make(map[string]*Collection),
		folders:      make(map[string]*Folder),
	}, nil
}

// LoadRegistry loads an existing registry from the specified YAML file
// Returns an error if the file does not exist or cannot be parsed
func LoadRegistry(registryPath string) (*Registry, error) {
	if err := validateRegistryPath(registryPath); err != nil {
		return nil, err
	}

	// Check if registry file exists
	if _, err := os.Stat(registryPath); os.IsNotExist(err) {
		return nil, fmt.Errorf("registry file does not exist: %s", registryPath)
	}

	// Read the file
	data, err := os.ReadFile(registryPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read registry file: %w", err)
	}

	// Parse YAML
	var registryData RegistryData
	if err := yaml.Unmarshal(data, &registryData); err != nil {
		return nil, fmt.Errorf("failed to parse registry YAML: %w", err)
	}

	// Create a temporary registry to use validateConfig
	if err := validateConfig(registryData.Config); err != nil {
		return nil, err
	}

	// Populate entries map
	entries := make(map[string]*FileEntry)
	for i := range registryData.Files {
		entries[registryData.Files[i].Path] = &registryData.Files[i]
	}

	// Populate collections map
	collections := make(map[string]*Collection)
	for i := range registryData.Collections {
		collections[registryData.Collections[i].Name] = &registryData.Collections[i]
	}

	// Populate folders map
	folders := make(map[string]*Folder)
	for i := range registryData.Folders {
		folders[registryData.Folders[i].Name] = &registryData.Folders[i]
	}

	return &Registry{
		registryPath: registryPath,
		config:       registryData.Config,
		entries:      entries,
		collections:  collections,
		folders:      folders,
	}, nil
}

// Load reads the registry from disk into memory
func (r *Registry) Load() error {
	r.mu.Lock()
	defer r.mu.Unlock()

	// Check if registry file exists
	if _, err := os.Stat(r.registryPath); os.IsNotExist(err) {
		// File doesn't exist, initialize empty registry
		r.entries = make(map[string]*FileEntry)
		r.collections = make(map[string]*Collection)
		r.folders = make(map[string]*Folder)
		return nil
	}

	// Read the file
	data, err := os.ReadFile(r.registryPath)
	if err != nil {
		return fmt.Errorf("failed to read registry file: %w", err)
	}

	// Parse YAML
	var registryData RegistryData
	if err := yaml.Unmarshal(data, &registryData); err != nil {
		return fmt.Errorf("failed to parse registry YAML: %w", err)
	}

	// Validate config fields
	if err := validateConfig(registryData.Config); err != nil {
		return err
	}

	// Load config - validation already ensures GuardFileMode is present
	r.config = registryData.Config

	// Populate entries map
	r.entries = make(map[string]*FileEntry)
	for i := range registryData.Files {
		r.entries[registryData.Files[i].Path] = &registryData.Files[i]
	}

	// Populate collections map
	r.collections = make(map[string]*Collection)
	for i := range registryData.Collections {
		r.collections[registryData.Collections[i].Name] = &registryData.Collections[i]
	}

	// Populate folders map
	r.folders = make(map[string]*Folder)
	for i := range registryData.Folders {
		r.folders[registryData.Folders[i].Name] = &registryData.Folders[i]
	}

	return nil
}

// Save writes the registry from memory to disk
func (r *Registry) Save() error {
	r.mu.Lock()
	defer r.mu.Unlock()

	// Convert map to slice for YAML serialization
	var registryData RegistryData
	registryData.Config = r.config

	registryData.Files = make([]FileEntry, 0, len(r.entries))
	for _, entry := range r.entries {
		registryData.Files = append(registryData.Files, *entry)
	}

	// Convert collections map to slice
	registryData.Collections = make([]Collection, 0, len(r.collections))
	for _, collection := range r.collections {
		registryData.Collections = append(registryData.Collections, *collection)
	}

	// Convert folders map to slice
	registryData.Folders = make([]Folder, 0, len(r.folders))
	for _, folder := range r.folders {
		registryData.Folders = append(registryData.Folders, *folder)
	}

	// Marshal to YAML
	data, err := yaml.Marshal(&registryData)
	if err != nil {
		return fmt.Errorf("failed to marshal registry to YAML: %w", err)
	}

	// Write to file
	if err := os.WriteFile(r.registryPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write registry file: %w", err)
	}

	return nil
}

// validateConfig checks that all required config fields are present and valid
func validateConfig(config Config) error {
	// GuardFileMode is required
	if config.GuardFileMode == "" {
		return fmt.Errorf("guard_mode is required in config")
	}

	if _, err := octalStringToFileMode(config.GuardFileMode); err != nil {
		return fmt.Errorf("invalid guard_mode in config: %w", err)
	}

	// GuardOwner and GuardGroup are strings (can be empty)
	// No need to check if they are strings, as they are defined as strings in the Config struct.

	// Validate last_toggle if present
	if config.LastToggle != nil {
		// Check for both empty - should be nil instead
		if config.LastToggle.Name == "" && config.LastToggle.Type == "" {
			return fmt.Errorf("invalid last_toggle: should be nil instead of empty struct")
		}

		// Check for inconsistent state (one set, one empty)
		if (config.LastToggle.Name == "" && config.LastToggle.Type != "") ||
			(config.LastToggle.Name != "" && config.LastToggle.Type == "") {
			return fmt.Errorf("invalid last_toggle: name and type must both be set or both be empty")
		}

		// Validate type if set
		if config.LastToggle.Type != "" &&
			config.LastToggle.Type != "file" &&
			config.LastToggle.Type != "collection" {
			return fmt.Errorf("invalid last_toggle type: must be 'file' or 'collection', got '%s'", config.LastToggle.Type)
		}
	}

	return nil
}

// octalStringToFileMode parses an octal string (e.g. "0600") into an os.FileMode.
func octalStringToFileMode(value string) (os.FileMode, error) {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return 0, fmt.Errorf("file mode value is empty")
	}

	if len(trimmed) == 3 {
		trimmed = "0" + trimmed
	} else if len(trimmed) != 4 {
		return 0, fmt.Errorf("file mode must be 3 or 4 octal digits, got %q", value)
	}

	parsed, err := strconv.ParseUint(trimmed, 8, 32)
	if err != nil {
		return 0, fmt.Errorf("invalid octal file mode %q: %w", value, err)
	}

	return os.FileMode(parsed), nil
}

// fileModeToOctalString renders an os.FileMode as a zero-padded octal string.
func fileModeToOctalString(mode os.FileMode) string {
	return fmt.Sprintf("%04o", uint32(mode.Perm()))
}

// validateRegistryPath checks if the given path is empty or consists only of whitespace.
func validateRegistryPath(path string) error {
	trimmedPath := strings.TrimSpace(path)
	if trimmedPath == "" {
		return fmt.Errorf("registry path cannot be empty or whitespace only")
	}
	return nil
}

// RegisterFile adds a file to the registry with the given FileMode and ownership metadata
// Returns an error if the file is already registered
func (r *Registry) RegisterFile(path string, fileMode os.FileMode, owner string, group string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.entries[path]; exists {
		return fmt.Errorf("file already registered: %s", path)
	}

	entry := &FileEntry{
		Path:     path,
		FileMode: fileModeToOctalString(fileMode),
		Owner:    owner,
		Group:    group,
		Guard:    false,
	}

	r.entries[path] = entry
	return nil
}

// UnregisterFile removes a file from the registry
// If ignoreMissing is true, returns nil when the file doesn't exist
// If ignoreMissing is false, returns an error when the file doesn't exist
func (r *Registry) UnregisterFile(path string, ignoreMissing bool) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.entries[path]; !exists {
		if ignoreMissing {
			return nil
		}
		return fmt.Errorf("file not found in registry: %s", path)
	}

	// Remove the file from all collections before deleting it
	r.removeRegisteredFileFromAllRegisteredCollections(path)
	delete(r.entries, path)
	return nil
}

// IsRegisteredFile returns true if a path is registered in the registry
func (r *Registry) IsRegisteredFile(path string) bool {
	r.mu.RLock()
	defer r.mu.RUnlock()
	_, exists := r.entries[path]
	return exists
}

// GetRegisteredFiles returns a slice of all registered file paths
func (r *Registry) GetRegisteredFiles() []string {
	r.mu.RLock()
	defer r.mu.RUnlock()

	paths := make([]string, 0, len(r.entries))
	for path := range r.entries {
		paths = append(paths, path)
	}
	return paths
}

// GetRegisteredFileMode returns the stored file mode for a registered file
func (r *Registry) GetRegisteredFileMode(path string) (os.FileMode, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	entry, exists := r.entries[path]
	if !exists {
		return 0, fmt.Errorf("file not found in registry: %s", path)
	}

	mode, err := octalStringToFileMode(entry.FileMode)
	if err != nil {
		return 0, err
	}

	return mode, nil
}

// SetRegisteredFileMode updates the file mode for a registered file
// Returns an error if the file is not registered
func (r *Registry) SetRegisteredFileMode(path string, fileMode os.FileMode) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	entry, exists := r.entries[path]
	if !exists {
		return fmt.Errorf("file not found in registry: %s", path)
	}

	// Validate by converting to string and back
	modeStr := fileModeToOctalString(fileMode)
	if _, err := octalStringToFileMode(modeStr); err != nil {
		return fmt.Errorf("invalid file mode: %w", err)
	}

	entry.FileMode = modeStr
	return nil
}

// GetRegisteredFileGuard retrieves the guard flag for a registered file
func (r *Registry) GetRegisteredFileGuard(path string) (bool, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	entry, exists := r.entries[path]
	if !exists {
		return false, fmt.Errorf("file not found in registry: %s", path)
	}

	return entry.Guard, nil
}

// SetRegisteredFileGuard sets the guard flag for a registered file
func (r *Registry) SetRegisteredFileGuard(path string, guard bool) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	entry, exists := r.entries[path]
	if !exists {
		return fmt.Errorf("file not found in registry: %s", path)
	}

	entry.Guard = guard
	return nil
}

// GetRegisteredFileConfig retrieves all configuration for a registered file
// Returns owner, group, mode, and guard flag
func (r *Registry) GetRegisteredFileConfig(path string) (string, string, os.FileMode, bool, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	entry, exists := r.entries[path]
	if !exists {
		return "", "", 0, false, fmt.Errorf("file not found in registry: %s", path)
	}

	mode, err := octalStringToFileMode(entry.FileMode)
	if err != nil {
		return "", "", 0, false, err
	}

	return entry.Owner, entry.Group, mode, entry.Guard, nil
}

// SetRegisteredFileConfig sets all configuration for a registered file
// Returns an error if the file is not registered
func (r *Registry) SetRegisteredFileConfig(path string, fileMode os.FileMode, owner string, group string, guard bool) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	entry, exists := r.entries[path]
	if !exists {
		return fmt.Errorf("file not found in registry: %s", path)
	}

	// Validate by converting to string and back
	modeStr := fileModeToOctalString(fileMode)
	if _, err := octalStringToFileMode(modeStr); err != nil {
		return fmt.Errorf("invalid file mode: %w", err)
	}

	entry.FileMode = modeStr
	entry.Owner = owner
	entry.Group = group
	entry.Guard = guard
	return nil
}

// GetRegisteredFileOwner returns the stored owner for a registered file
func (r *Registry) GetRegisteredFileOwner(path string) (string, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	entry, exists := r.entries[path]
	if !exists {
		return "", fmt.Errorf("file not found in registry: %s", path)
	}

	return entry.Owner, nil
}

// SetRegisteredFileOwner updates the stored owner for a registered file and returns the previous owner
func (r *Registry) SetRegisteredFileOwner(path, owner string) (string, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	entry, exists := r.entries[path]
	if !exists {
		return "", fmt.Errorf("file not found in registry: %s", path)
	}

	prev := entry.Owner
	entry.Owner = owner
	return prev, nil
}

// GetRegisteredFileGroup returns the stored group for a registered file
func (r *Registry) GetRegisteredFileGroup(path string) (string, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	entry, exists := r.entries[path]
	if !exists {
		return "", fmt.Errorf("file not found in registry: %s", path)
	}

	return entry.Group, nil
}

// SetRegisteredFileGroup updates the stored group for a registered file and returns the previous group
func (r *Registry) SetRegisteredFileGroup(path, group string) (string, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	entry, exists := r.entries[path]
	if !exists {
		return "", fmt.Errorf("file not found in registry: %s", path)
	}

	prev := entry.Group
	entry.Group = group
	return prev, nil
}

// RegisterCollection adds a new collection to the registry
// Returns an error if a collection with the same name already exists
// Guard flag is always initialized to false for new collections
func (r *Registry) RegisterCollection(name string, files []string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	// Check if collection already exists
	if _, exists := r.collections[name]; exists {
		return fmt.Errorf("collection already exists: %s", name)
	}

	// Create new collection
	collection := &Collection{
		Name:  name,
		Files: files,
		Guard: false,
	}

	r.collections[name] = collection
	return nil
}

// UnregisterCollection removes a collection from the registry
// If ignoreMissing is true, returns nil when the collection doesn't exist
// If ignoreMissing is false, returns an error when the collection doesn't exist
func (r *Registry) UnregisterCollection(name string, ignoreMissing bool) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	// Check if collection exists
	if _, exists := r.collections[name]; !exists {
		if ignoreMissing {
			return nil
		}
		return fmt.Errorf("collection not found: %s", name)
	}

	delete(r.collections, name)
	return nil
}

// IsRegisteredCollection returns true if a collection exists in the registry
func (r *Registry) IsRegisteredCollection(name string) bool {
	r.mu.RLock()
	defer r.mu.RUnlock()
	_, exists := r.collections[name]
	return exists
}

// GetRegisteredCollections returns a list of all collection names
func (r *Registry) GetRegisteredCollections() []string {
	r.mu.RLock()
	defer r.mu.RUnlock()

	names := make([]string, 0, len(r.collections))
	for name := range r.collections {
		names = append(names, name)
	}
	return names
}

// GetRegisteredCollectionGuard retrieves the guard flag for a registered collection
func (r *Registry) GetRegisteredCollectionGuard(collectionName string) (bool, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	col, exists := r.collections[collectionName]
	if !exists {
		return false, fmt.Errorf("collection not found: %s", collectionName)
	}

	return col.Guard, nil
}

// SetRegisteredCollectionGuard sets the guard flag for a registered collection
func (r *Registry) SetRegisteredCollectionGuard(collectionName string, guard bool) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	col, exists := r.collections[collectionName]
	if !exists {
		return fmt.Errorf("collection not found: %s", collectionName)
	}

	col.Guard = guard
	return nil
}

// GetRegisteredCollectionFiles returns a copy of the files in a collection
func (r *Registry) GetRegisteredCollectionFiles(collectionName string) ([]string, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	col, exists := r.collections[collectionName]
	if !exists {
		return nil, fmt.Errorf("collection not found: %s", collectionName)
	}

	// Return a copy to prevent external modification
	files := make([]string, len(col.Files))
	copy(files, col.Files)
	return files, nil
}

// CountFilesInCollection returns the number of files in a collection
func (r *Registry) CountFilesInCollection(collectionName string) (int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	col, exists := r.collections[collectionName]
	if !exists {
		return 0, fmt.Errorf("collection not found: %s", collectionName)
	}

	return len(col.Files), nil
}

// AddRegisteredFilesToRegisteredCollections adds multiple registered file paths to multiple collections
// Returns an error if any collection doesn't exist or if any file is not registered
func (r *Registry) AddRegisteredFilesToRegisteredCollections(collectionNames []string, filePaths []string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	// Verify all collections exist first
	for _, collectionName := range collectionNames {
		if _, exists := r.collections[collectionName]; !exists {
			return fmt.Errorf("collection not found: %s", collectionName)
		}
	}

	// Verify all files are registered
	for _, filePath := range filePaths {
		if _, exists := r.entries[filePath]; !exists {
			return fmt.Errorf("file not registered: %s", filePath)
		}
	}

	// Add all files to all collections
	for _, collectionName := range collectionNames {
		collection := r.collections[collectionName]
		for _, filePath := range filePaths {
			// Check if file already exists in the collection
			found := false
			for _, f := range collection.Files {
				if f == filePath {
					found = true
					break
				}
			}
			if !found {
				collection.Files = append(collection.Files, filePath)
			}
		}
		// Write the modified collection back to the map
		r.collections[collectionName] = collection
	}

	return nil
}

// RemoveRegisteredFilesFromRegisteredCollections removes multiple registered file paths from multiple collections
// Only removes files that are registered; silently skips unregistered files and non-existent collections
func (r *Registry) RemoveRegisteredFilesFromRegisteredCollections(collectionNames []string, filePaths []string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	// Filter to only registered files and build removal set
	filesToRemove := make(map[string]struct{})
	for _, filePath := range filePaths {
		if _, exists := r.entries[filePath]; exists {
			filesToRemove[filePath] = struct{}{}
		}
	}

	// Remove all registered files from all registered collections
	for _, collectionName := range collectionNames {
		collection, exists := r.collections[collectionName]
		if !exists {
			continue
		}

		// Single-pass filter to remove files
		filtered := collection.Files[:0]
		for _, file := range collection.Files {
			if _, shouldRemove := filesToRemove[file]; !shouldRemove {
				filtered = append(filtered, file)
			}
		}
		collection.Files = filtered
	}

	return nil
}

// RemoveRegisteredFileFromAllRegisteredCollections removes a file from all collections
// Does not unregister the file itself, only removes it from collections
func (r *Registry) RemoveRegisteredFileFromAllRegisteredCollections(path string) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.removeRegisteredFileFromAllRegisteredCollections(path)
}

// removeRegisteredFileFromAllRegisteredCollections removes a file from all collections
// Must be called with r.mu lock held
func (r *Registry) removeRegisteredFileFromAllRegisteredCollections(path string) {
	for _, collection := range r.collections {
		filtered := collection.Files[:0]
		for _, file := range collection.Files {
			if file != path {
				filtered = append(filtered, file)
			}
		}
		collection.Files = filtered
	}
}

// GetDefaultFileMode returns the guard file mode from configuration
// GuardFileMode is guaranteed to be valid due to validateConfig being called on load
func (r *Registry) GetDefaultFileMode() os.FileMode {
	r.mu.RLock()
	defer r.mu.RUnlock()
	mode, _ := octalStringToFileMode(r.config.GuardFileMode)
	return mode
}

// SetDefaultFileMode sets the guard file mode in configuration
// Validates the mode before setting it
func (r *Registry) SetDefaultFileMode(mode os.FileMode) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	// Validate by converting to string and back
	modeStr := fileModeToOctalString(mode)
	if _, err := octalStringToFileMode(modeStr); err != nil {
		return fmt.Errorf("invalid file mode: %w", err)
	}

	r.config.GuardFileMode = modeStr
	return nil
}

// GetDefaultFileOwner returns the configured guard owner (empty means unset)
func (r *Registry) GetDefaultFileOwner() string {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.config.GuardOwner
}

// SetDefaultFileOwner sets the configured guard owner
func (r *Registry) SetDefaultFileOwner(owner string) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.config.GuardOwner = strings.TrimSpace(owner)
}

// GetDefaultFileGroup returns the configured guard group (empty means unset)
func (r *Registry) GetDefaultFileGroup() string {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.config.GuardGroup
}

// SetDefaultFileGroup sets the configured guard group
func (r *Registry) SetDefaultFileGroup(group string) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.config.GuardGroup = strings.TrimSpace(group)
}

// GetUseGitignore returns whether .gitignore rules are enabled.
func (r *Registry) GetUseGitignore() bool {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.config.GetUseGitignore()
}

// GetUseGuardignore returns whether .guardignore rules are enabled.
func (r *Registry) GetUseGuardignore() bool {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.config.GetUseGuardignore()
}

// GetLastToggle returns the last toggled item (name, type) or empty strings if none
func (r *Registry) GetLastToggle() (name string, toggleType string) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	if r.config.LastToggle == nil {
		return "", ""
	}

	return r.config.LastToggle.Name, r.config.LastToggle.Type
}

// SetLastToggle updates the last toggled item
func (r *Registry) SetLastToggle(name string, toggleType string) {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.config.LastToggle = &LastToggle{
		Name: name,
		Type: toggleType,
	}
}

// ClearLastToggle removes the last toggle tracking
func (r *Registry) ClearLastToggle() {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.config.LastToggle = nil
}

// GetRegisteredCollectionRawFileMode returns the guard file mode stored directly on the collection
// Returns empty string if not set on the collection (no fallback to defaults)
func (r *Registry) GetRegisteredCollectionRawFileMode(collectionName string) (string, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	col, exists := r.collections[collectionName]
	if !exists {
		return "", fmt.Errorf("collection not found: %s", collectionName)
	}

	return col.GuardFileMode, nil
}

// GetRegisteredCollectionEffectiveFileMode returns the guard file mode for a collection
// If not set on the collection, falls back to the configured default
func (r *Registry) GetRegisteredCollectionEffectiveFileMode(collectionName string) (os.FileMode, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	col, exists := r.collections[collectionName]
	if !exists {
		return 0, fmt.Errorf("collection not found: %s", collectionName)
	}

	// If collection has a specific mode set, use it
	if col.GuardFileMode != "" {
		mode, err := octalStringToFileMode(col.GuardFileMode)
		if err != nil {
			return 0, fmt.Errorf("invalid guard_mode for collection %s: %w", collectionName, err)
		}
		return mode, nil
	}

	// Fall back to configured default
	mode, err := octalStringToFileMode(r.config.GuardFileMode)
	if err != nil {
		return 0, err
	}

	return mode, nil
}

// SetRegisteredCollectionFileMode sets the guard file mode for a collection
// Validates the mode before setting it
func (r *Registry) SetRegisteredCollectionFileMode(collectionName string, fileMode os.FileMode) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	col, exists := r.collections[collectionName]
	if !exists {
		return fmt.Errorf("collection not found: %s", collectionName)
	}

	// Validate by converting to string and back
	modeStr := fileModeToOctalString(fileMode)
	if _, err := octalStringToFileMode(modeStr); err != nil {
		return fmt.Errorf("invalid file mode: %w", err)
	}

	col.GuardFileMode = modeStr
	return nil
}

// GetRegisteredCollectionRawOwner returns the guard owner stored directly on the collection
// Returns empty string if not set on the collection (no fallback to defaults)
func (r *Registry) GetRegisteredCollectionRawOwner(collectionName string) (string, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	col, exists := r.collections[collectionName]
	if !exists {
		return "", fmt.Errorf("collection not found: %s", collectionName)
	}

	return col.GuardOwner, nil
}

// GetRegisteredCollectionEffectiveOwner returns the guard owner for a collection
// If not set on the collection, falls back to the configured default
func (r *Registry) GetRegisteredCollectionEffectiveOwner(collectionName string) (string, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	col, exists := r.collections[collectionName]
	if !exists {
		return "", fmt.Errorf("collection not found: %s", collectionName)
	}

	// If collection has a specific owner set, use it
	if col.GuardOwner != "" {
		return col.GuardOwner, nil
	}

	// Fall back to configured default
	return r.config.GuardOwner, nil
}

// SetRegisteredCollectionOwner sets the guard owner for a collection
func (r *Registry) SetRegisteredCollectionOwner(collectionName string, owner string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	col, exists := r.collections[collectionName]
	if !exists {
		return fmt.Errorf("collection not found: %s", collectionName)
	}

	col.GuardOwner = strings.TrimSpace(owner)
	return nil
}

// GetRegisteredCollectionRawGroup returns the guard group stored directly on the collection
// Returns empty string if not set on the collection (no fallback to defaults)
func (r *Registry) GetRegisteredCollectionRawGroup(collectionName string) (string, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	col, exists := r.collections[collectionName]
	if !exists {
		return "", fmt.Errorf("collection not found: %s", collectionName)
	}

	return col.GuardGroup, nil
}

// GetRegisteredCollectionEffectiveGroup returns the guard group for a collection
// If not set on the collection, falls back to the configured default
func (r *Registry) GetRegisteredCollectionEffectiveGroup(collectionName string) (string, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	col, exists := r.collections[collectionName]
	if !exists {
		return "", fmt.Errorf("collection not found: %s", collectionName)
	}

	// If collection has a specific group set, use it
	if col.GuardGroup != "" {
		return col.GuardGroup, nil
	}

	// Fall back to configured default
	return r.config.GuardGroup, nil
}

// SetRegisteredCollectionGroup sets the guard group for a collection
func (r *Registry) SetRegisteredCollectionGroup(collectionName string, group string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	col, exists := r.collections[collectionName]
	if !exists {
		return fmt.Errorf("collection not found: %s", collectionName)
	}

	col.GuardGroup = strings.TrimSpace(group)
	return nil
}

// GetRegisteredCollectionRawConfig retrieves the raw configuration stored on a collection
// Returns owner, group, mode (as octal string), and guard flag without any fallback to defaults
// Empty strings indicate values not set on the collection
func (r *Registry) GetRegisteredCollectionRawConfig(collectionName string) (string, string, string, bool, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	col, exists := r.collections[collectionName]
	if !exists {
		return "", "", "", false, fmt.Errorf("collection not found: %s", collectionName)
	}

	return col.GuardOwner, col.GuardGroup, col.GuardFileMode, col.Guard, nil
}

// GetRegisteredCollectionEffectiveConfig retrieves all effective configuration for a registered collection
// Returns owner, group, mode, and guard flag with fallbacks to config defaults
func (r *Registry) GetRegisteredCollectionEffectiveConfig(collectionName string) (string, string, os.FileMode, bool, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	col, exists := r.collections[collectionName]
	if !exists {
		return "", "", 0, false, fmt.Errorf("collection not found: %s", collectionName)
	}

	// Get owner with fallback
	owner := col.GuardOwner
	if owner == "" {
		owner = r.config.GuardOwner
	}

	// Get group with fallback
	group := col.GuardGroup
	if group == "" {
		group = r.config.GuardGroup
	}

	// Get mode with fallback
	var mode os.FileMode
	var err error
	if col.GuardFileMode != "" {
		mode, err = octalStringToFileMode(col.GuardFileMode)
		if err != nil {
			return "", "", 0, false, fmt.Errorf("invalid guard_mode for collection %s: %w", collectionName, err)
		}
	} else {
		mode, err = octalStringToFileMode(r.config.GuardFileMode)
		if err != nil {
			return "", "", 0, false, err
		}
	}

	return owner, group, mode, col.Guard, nil
}
