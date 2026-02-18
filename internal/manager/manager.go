package manager

import (
	"fmt"
	"path/filepath"

	"github.com/florianbuetow/guard/internal/filesystem"
	"github.com/florianbuetow/guard/internal/guardignore"
	"github.com/florianbuetow/guard/internal/security"
)

// Manager orchestrates operations between the Security (Registry) and Filesystem layers.
// It implements business logic, idempotency, warning aggregation, and multi-step operations.
type Manager struct {
	registryPath  string
	security      *security.Security
	fs            *filesystem.FileSystem
	ignoreMatcher *guardignore.IgnoreMatcher
	warnings      []Warning
	errors        []string
}

// NewManager creates a new Manager instance with the specified registry path.
// The registry is NOT loaded automatically - call LoadRegistry() explicitly.
func NewManager(registryPath string) *Manager {
	return &Manager{
		registryPath: registryPath,
		fs:           filesystem.NewFileSystem(),
		warnings:     make([]Warning, 0),
		errors:       make([]string, 0),
	}
}

// LoadRegistry loads the registry from disk.
// Returns an error if the .guardfile doesn't exist or is corrupted.
func (m *Manager) LoadRegistry() error {
	sec, err := security.LoadSecurity(m.registryPath)
	if err != nil {
		// Check if file doesn't exist (specific error message per Requirement 11.7)
		if !m.fs.FileExists(m.registryPath) {
			return fmt.Errorf(".guardfile not found in current directory. Run 'guard init <mode> <owner> <group>' to initialize")
		}
		// Otherwise it's corrupted (Requirement 11.8)
		return fmt.Errorf(".guardfile is corrupted: %w. Suggested recovery: restore from backup or run 'guard init' to reinitialize", err)
	}

	m.security = sec
	m.initIgnoreMatcher()
	return nil
}

// SaveRegistry saves the registry to disk.
// If the .guardfile has an immutable flag set, it will be cleared before writing.
func (m *Manager) SaveRegistry() error {
	if m.security == nil {
		return fmt.Errorf("registry not loaded")
	}
	if err := m.clearGuardfileImmutableFlag(); err != nil {
		return err
	}
	return m.security.Save()
}

// clearGuardfileImmutableFlag removes the immutable flag from .guardfile if set.
// This must be called before any write operation to .guardfile.
func (m *Manager) clearGuardfileImmutableFlag() error {
	if !m.fs.FileExists(m.registryPath) {
		return nil // File doesn't exist yet, nothing to clear
	}

	isImmutable, err := m.fs.IsImmutable(m.registryPath)
	if err != nil {
		// Can't check (unsupported OS, etc.) - proceed anyway, write will fail naturally
		return nil
	}

	if isImmutable {
		if err := m.fs.ClearImmutable(m.registryPath); err != nil {
			return fmt.Errorf("failed to clear immutable flag on .guardfile: %w", err)
		}
	}
	return nil
}

// InitializeRegistry creates a new registry with the specified defaults.
// If overwrite is false and the file exists, returns an error.
func (m *Manager) InitializeRegistry(mode, owner, group string, overwrite bool) error {
	defaults := &security.RegistryDefaults{
		GuardMode:  mode,
		GuardOwner: owner,
		GuardGroup: group,
	}

	// Clear immutable flag before creating/overwriting (in case existing file is immutable)
	if overwrite {
		if err := m.clearGuardfileImmutableFlag(); err != nil {
			return err
		}
	}

	sec, err := security.NewSecurity(m.registryPath, defaults, overwrite)
	if err != nil {
		return err
	}

	// Save immediately
	if err := sec.Save(); err != nil {
		return fmt.Errorf("failed to save new registry: %w", err)
	}

	guardignorePath := filepath.Join(filepath.Dir(m.registryPath), ".guardignore")
	if err := m.createGuardignoreTemplate(guardignorePath); err != nil {
		m.AddWarning(NewWarning(WarningGeneric, fmt.Sprintf("Could not create .guardignore template: %v", err)))
	}

	m.security = sec
	m.initIgnoreMatcher()
	return nil
}

func (m *Manager) createGuardignoreTemplate(path string) error {
	if m.fs.FileExists(path) {
		return nil
	}

	content := `# .guardignore works like .gitignore
# By default guard also uses your .gitignore files (see use_gitignore in .guardfile)
# add your custom ignore rules below
`

	return m.fs.WriteFile(path, []byte(content), 0644)
}

// CheckFilesExist returns files that exist and files that are missing.
func (m *Manager) CheckFilesExist(paths []string) (existing []string, missing []string) {
	return m.fs.CheckFilesExist(paths)
}

// IsRegisteredFile returns true if the file is registered in the registry.
func (m *Manager) IsRegisteredFile(path string) bool {
	if m.security == nil {
		return false
	}
	return m.security.IsRegisteredFile(path)
}

// CountFilesInCollection returns the number of files in a collection.
func (m *Manager) CountFilesInCollection(collectionName string) (int, error) {
	if m.security == nil {
		return 0, fmt.Errorf("registry not loaded")
	}
	return m.security.CountFilesInCollection(collectionName)
}

// AddWarning adds a warning to the manager's warning list.
func (m *Manager) AddWarning(warning Warning) {
	m.warnings = append(m.warnings, warning)
}

// AddError adds an error message to the manager's error list.
func (m *Manager) AddError(msg string) {
	m.errors = append(m.errors, msg)
}

// GetWarnings returns all warnings collected during operations.
func (m *Manager) GetWarnings() []Warning {
	return m.warnings
}

// GetErrors returns all errors collected during operations.
func (m *Manager) GetErrors() []string {
	return m.errors
}

// ClearWarnings clears all collected warnings.
func (m *Manager) ClearWarnings() {
	m.warnings = make([]Warning, 0)
}

// toDisplayPaths converts absolute paths to relative paths for display.
func (m *Manager) toDisplayPaths(paths []string) []string {
	displayPaths := make([]string, len(paths))
	for i, path := range paths {
		displayPaths[i] = m.security.ToDisplayPath(path)
	}
	return displayPaths
}

// ClearErrors clears all collected errors.
func (m *Manager) ClearErrors() {
	m.errors = make([]string, 0)
}

// HasErrors returns true if any errors have been collected.
func (m *Manager) HasErrors() bool {
	return len(m.errors) > 0
}

// HasWarnings returns true if any warnings have been collected.
func (m *Manager) HasWarnings() bool {
	return len(m.warnings) > 0
}

// IsRegisteredCollection returns true if the collection is registered in the registry.
func (m *Manager) IsRegisteredCollection(name string) bool {
	if m.security == nil {
		return false
	}
	return m.security.IsRegisteredCollection(name)
}

// ResolveArgument determines whether an argument is a file, folder, or collection.
// Returns "file", "folder", "collection", or an error for not-found cases.
//
// Auto-detection priority:
// 1. Directory on disk → folder
// 2. File on disk → file
// 3. Registered collection name → collection
// 4. Registered folder name (with @ prefix) → folder
// 5. Registered file path → file
// 6. None of the above → error
func (m *Manager) ResolveArgument(arg string) (string, error) {
	if m.security == nil {
		return "", fmt.Errorf("registry not loaded")
	}

	// Priority 1: Directory on disk
	isDir, err := m.fs.IsDir(arg)
	if err == nil && isDir {
		return "folder", nil
	}

	// Priority 2: File on disk
	if m.fs.FileExists(arg) {
		return "file", nil
	}

	// Priority 3: Registered collection
	if m.security.IsRegisteredCollection(arg) {
		return "collection", nil
	}

	// Priority 4: Registered folder (check with @ prefix)
	folderName := "@" + arg
	if m.security.IsRegisteredFolder(folderName) {
		return "folder", nil
	}

	// Priority 5: Registered file path
	if m.security.IsRegisteredFile(arg) {
		return "file", nil
	}

	// Priority 6: Not found
	return "", fmt.Errorf("'%s' not found", arg)
}

// ResolveArguments categorizes a list of arguments into files, folders, and collections.
// Returns separate slices for files, folders, and collections.
// Returns an error if any argument is not found.
func (m *Manager) ResolveArguments(args []string) (files []string, folders []string, collections []string, err error) {
	if m.security == nil {
		return nil, nil, nil, fmt.Errorf("registry not loaded")
	}

	files = make([]string, 0)
	folders = make([]string, 0)
	collections = make([]string, 0)

	for _, arg := range args {
		kind, err := m.ResolveArgument(arg)
		if err != nil {
			return nil, nil, nil, err
		}

		switch kind {
		case "file":
			files = append(files, arg)
		case "folder":
			folders = append(folders, arg)
		case "collection":
			collections = append(collections, arg)
		}
	}

	return files, folders, collections, nil
}
