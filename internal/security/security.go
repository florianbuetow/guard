package security

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/florianbuetow/guard/internal/registry"
)

// RegistryDefaults is re-exported from registry for convenience
type RegistryDefaults = registry.RegistryDefaults

// Security provides a security layer around Registry that validates file paths
// to prevent path traversal attacks, symlink exploitation, and tampering.
// All paths are validated to stay within the guardfile directory tree.
type Security struct {
	registry     *registry.Registry
	guardfileDir string // absolute path to guardfile directory
}

// NewSecurity creates a new security layer with a new registry.
// The guardfileDir is extracted from the registryPath.
func NewSecurity(registryPath string, defaults *registry.RegistryDefaults, overwrite bool) (*Security, error) {
	reg, err := registry.NewRegistry(registryPath, defaults, overwrite)
	if err != nil {
		return nil, err
	}

	absRegistryPath, err := filepath.Abs(registryPath)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve registry path: %w", err)
	}

	return &Security{
		registry:     reg,
		guardfileDir: filepath.Dir(absRegistryPath),
	}, nil
}

// LoadSecurity loads an existing registry and wraps it with security validation.
// Validates all paths in the guardfile to detect tampering on load.
func LoadSecurity(registryPath string) (*Security, error) {
	reg, err := registry.LoadRegistry(registryPath)
	if err != nil {
		return nil, err
	}

	absRegistryPath, err := filepath.Abs(registryPath)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve registry path: %w", err)
	}

	s := &Security{
		registry:     reg,
		guardfileDir: filepath.Dir(absRegistryPath),
	}

	// Validate all paths on load (tampering detection)
	if err := s.validateAllRegisteredPaths(); err != nil {
		return nil, fmt.Errorf("guardfile tampering detected: %w", err)
	}

	return s, nil
}

// validatePath checks if a path is allowed:
// 1. Convert to absolute path
// 2. Check if symlink (use os.Lstat, not os.Stat)
// 3. Clean path to resolve .. sequences
// 4. Ensure resolved path is within guardfile directory tree
func (s *Security) validatePath(path string) error {
	// 1. Convert to absolute
	absPath, err := filepath.Abs(path)
	if err != nil {
		return fmt.Errorf("path validation failed: invalid path: %w", err)
	}

	// 2. Check if symlink BEFORE resolving (reject all symlinks)
	info, err := os.Lstat(absPath) // Lstat doesn't follow symlinks
	if err != nil && !os.IsNotExist(err) && !os.IsPermission(err) {
		return fmt.Errorf("path validation failed: %w", err)
	}
	// If permission denied, we can't check if it's a symlink, but we allow
	// the path through since it could be a valid file we can't access.
	if info != nil && info.Mode()&os.ModeSymlink != 0 {
		return fmt.Errorf("path validation failed: symbolic links not allowed: %s", path)
	}

	// 3. Clean the path to resolve .. sequences
	cleanPath := filepath.Clean(absPath)

	// 4. Ensure guardfile directory is a prefix (path stays within tree)
	// Use filepath.Rel to check if path is under guardfileDir
	relPath, err := filepath.Rel(s.guardfileDir, cleanPath)
	if err != nil {
		return fmt.Errorf("path validation failed: %w", err)
	}
	// If relative path starts with "..", it's outside the tree
	if strings.HasPrefix(relPath, "..") {
		return fmt.Errorf("path validation failed: path outside guardfile directory: %s", path)
	}

	return nil
}

// ValidatePaths validates multiple paths, returns error on first violation.
// This is a public method that can be called before file operations.
func (s *Security) ValidatePaths(paths []string) error {
	for _, path := range paths {
		// Convert to absolute first
		absPath, err := filepath.Abs(path)
		if err != nil {
			return fmt.Errorf("failed to resolve path: %w", err)
		}
		// Validate the absolute path
		if err := s.validatePath(absPath); err != nil {
			return err
		}
	}
	return nil
}

// toRelativePath converts absolute path to relative (from guardfile dir)
// Path must already be validated before calling this
func (s *Security) toRelativePath(absPath string) (string, error) {
	cleanPath := filepath.Clean(absPath)
	relPath, err := filepath.Rel(s.guardfileDir, cleanPath)
	if err != nil {
		return "", fmt.Errorf("failed to convert to relative path: %w", err)
	}
	return relPath, nil
}

// toAbsolutePath converts relative path to absolute (for returning to caller)
// No validation needed - this is for output only
func (s *Security) toAbsolutePath(relPath string) string {
	return filepath.Join(s.guardfileDir, relPath)
}

// ToDisplayPath converts an absolute path to a relative path for display.
// This is used for user-facing output like warnings and status messages.
func (s *Security) ToDisplayPath(absPath string) string {
	relPath, err := s.toRelativePath(absPath)
	if err != nil {
		// If conversion fails, return the original path
		return absPath
	}
	return relPath
}

// ToRelativePath converts a path to a relative path from the guardfile directory.
// The path is resolved to absolute and validated before conversion.
func (s *Security) ToRelativePath(path string) (string, error) {
	absPath, err := filepath.Abs(path)
	if err != nil {
		return "", fmt.Errorf("failed to resolve path: %w", err)
	}
	if err := s.validatePath(absPath); err != nil {
		return "", err
	}
	return s.toRelativePath(absPath)
}

// GetGuardfileDir returns the absolute guardfile directory used by this security instance.
func (s *Security) GetGuardfileDir() string {
	return s.guardfileDir
}

// GetUseGitignore returns whether .gitignore rules are enabled.
func (s *Security) GetUseGitignore() bool {
	return s.registry.GetUseGitignore()
}

// GetUseGuardignore returns whether .guardignore rules are enabled.
func (s *Security) GetUseGuardignore() bool {
	return s.registry.GetUseGuardignore()
}

// SetUseGitignore sets whether .gitignore rules are enabled.
func (s *Security) SetUseGitignore(enabled bool) {
	s.registry.SetUseGitignore(enabled)
}

// SetUseGuardignore sets whether .guardignore rules are enabled.
func (s *Security) SetUseGuardignore(enabled bool) {
	s.registry.SetUseGuardignore(enabled)
}

// validateAllRegisteredPaths validates all file paths in the registry.
// Called after loading from disk to detect tampering.
func (s *Security) validateAllRegisteredPaths() error {
	// Get all registered files (these are stored as relative paths)
	relPaths := s.registry.GetRegisteredFiles()

	// Validate each path (convert to absolute first, then validate)
	for _, relPath := range relPaths {
		// Detect tampering: paths should be relative, not absolute
		if filepath.IsAbs(relPath) {
			return fmt.Errorf("invalid path in guardfile: %s: absolute paths not allowed", relPath)
		}

		// Detect tampering: relative paths should not start with ".."
		if strings.HasPrefix(relPath, "..") {
			return fmt.Errorf("invalid path in guardfile: %s: parent directory escapes not allowed", relPath)
		}

		// Convert relative path from guardfile to absolute
		absPath := s.toAbsolutePath(relPath)

		// Validate the absolute path
		if err := s.validatePath(absPath); err != nil {
			return fmt.Errorf("invalid path in guardfile: %s: %w", relPath, err)
		}
	}

	return nil
}

// Load loads the registry from disk.
func (s *Security) Load() error {
	if err := s.registry.Load(); err != nil {
		return err
	}
	// Validate all paths immediately after loading
	if err := s.validateAllRegisteredPaths(); err != nil {
		return fmt.Errorf("guardfile tampering detected: %w", err)
	}
	return nil
}

// Save saves the registry to disk.
func (s *Security) Save() error {
	return s.registry.Save()
}

// RegisterFile registers a file in the registry.
func (s *Security) RegisterFile(path string, fileMode os.FileMode, owner string, group string) error {
	// Convert to absolute first
	absPath, err := filepath.Abs(path)
	if err != nil {
		return fmt.Errorf("failed to resolve path: %w", err)
	}

	// Validate the absolute path
	if err := s.validatePath(absPath); err != nil {
		return err
	}

	// Convert absolute path to relative for storage
	relPath, err := s.toRelativePath(absPath)
	if err != nil {
		return err
	}

	return s.registry.RegisterFile(relPath, fileMode, owner, group)
}

// UnregisterFile removes a file from the registry.
func (s *Security) UnregisterFile(path string, ignoreMissing bool) error {
	// Convert to absolute first
	absPath, err := filepath.Abs(path)
	if err != nil {
		return fmt.Errorf("failed to resolve path: %w", err)
	}

	// Validate the absolute path
	if err := s.validatePath(absPath); err != nil {
		return err
	}

	// Convert absolute path to relative
	relPath, err := s.toRelativePath(absPath)
	if err != nil {
		return err
	}

	return s.registry.UnregisterFile(relPath, ignoreMissing)
}

// IsRegisteredFile returns true if the file is registered.
func (s *Security) IsRegisteredFile(path string) bool {
	// Convert to absolute first
	absPath, err := filepath.Abs(path)
	if err != nil {
		return false
	}

	// Validate the absolute path
	if err := s.validatePath(absPath); err != nil {
		return false
	}

	// Convert absolute path to relative
	relPath, err := s.toRelativePath(absPath)
	if err != nil {
		return false
	}

	return s.registry.IsRegisteredFile(relPath)
}

// GetRegisteredFiles returns all registered file paths.
func (s *Security) GetRegisteredFiles() []string {
	relPaths := s.registry.GetRegisteredFiles()
	absPaths := make([]string, len(relPaths))
	for i, relPath := range relPaths {
		// Convert from relative to absolute for output
		absPaths[i] = s.toAbsolutePath(relPath)
	}
	return absPaths
}

// GetRegisteredFileMode returns the file mode for a registered file.
func (s *Security) GetRegisteredFileMode(path string) (os.FileMode, error) {
	absPath, err := filepath.Abs(path)
	if err != nil {
		return 0, fmt.Errorf("failed to resolve path: %w", err)
	}
	if err := s.validatePath(absPath); err != nil {
		return 0, err
	}
	relPath, err := s.toRelativePath(absPath)
	if err != nil {
		return 0, err
	}
	return s.registry.GetRegisteredFileMode(relPath)
}

// SetRegisteredFileMode sets the file mode for a registered file.
func (s *Security) SetRegisteredFileMode(path string, fileMode os.FileMode) error {
	absPath, err := filepath.Abs(path)
	if err != nil {
		return fmt.Errorf("failed to resolve path: %w", err)
	}
	if err := s.validatePath(absPath); err != nil {
		return err
	}
	relPath, err := s.toRelativePath(absPath)
	if err != nil {
		return err
	}
	return s.registry.SetRegisteredFileMode(relPath, fileMode)
}

// GetRegisteredFileGuard returns the guard flag for a registered file.
func (s *Security) GetRegisteredFileGuard(path string) (bool, error) {
	absPath, err := filepath.Abs(path)
	if err != nil {
		return false, fmt.Errorf("failed to resolve path: %w", err)
	}
	if err := s.validatePath(absPath); err != nil {
		return false, err
	}
	relPath, err := s.toRelativePath(absPath)
	if err != nil {
		return false, err
	}
	return s.registry.GetRegisteredFileGuard(relPath)
}

// SetRegisteredFileGuard sets the guard flag for a registered file.
func (s *Security) SetRegisteredFileGuard(path string, guard bool) error {
	absPath, err := filepath.Abs(path)
	if err != nil {
		return fmt.Errorf("failed to resolve path: %w", err)
	}
	if err := s.validatePath(absPath); err != nil {
		return err
	}
	relPath, err := s.toRelativePath(absPath)
	if err != nil {
		return err
	}
	return s.registry.SetRegisteredFileGuard(relPath, guard)
}

// GetRegisteredFileConfig returns the configuration for a registered file.
func (s *Security) GetRegisteredFileConfig(path string) (string, string, os.FileMode, bool, error) {
	absPath, err := filepath.Abs(path)
	if err != nil {
		return "", "", 0, false, fmt.Errorf("failed to resolve path: %w", err)
	}
	if err := s.validatePath(absPath); err != nil {
		return "", "", 0, false, err
	}
	relPath, err := s.toRelativePath(absPath)
	if err != nil {
		return "", "", 0, false, err
	}
	return s.registry.GetRegisteredFileConfig(relPath)
}

// SetRegisteredFileConfig sets the configuration for a registered file.
func (s *Security) SetRegisteredFileConfig(path string, fileMode os.FileMode, owner string, group string, guard bool) error {
	absPath, err := filepath.Abs(path)
	if err != nil {
		return fmt.Errorf("failed to resolve path: %w", err)
	}
	if err := s.validatePath(absPath); err != nil {
		return err
	}
	relPath, err := s.toRelativePath(absPath)
	if err != nil {
		return err
	}
	return s.registry.SetRegisteredFileConfig(relPath, fileMode, owner, group, guard)
}

// GetRegisteredFileOwner returns the owner for a registered file.
func (s *Security) GetRegisteredFileOwner(path string) (string, error) {
	absPath, err := filepath.Abs(path)
	if err != nil {
		return "", fmt.Errorf("failed to resolve path: %w", err)
	}
	if err := s.validatePath(absPath); err != nil {
		return "", err
	}
	relPath, err := s.toRelativePath(absPath)
	if err != nil {
		return "", err
	}
	return s.registry.GetRegisteredFileOwner(relPath)
}

// SetRegisteredFileOwner sets the owner for a registered file.
func (s *Security) SetRegisteredFileOwner(path, owner string) (string, error) {
	absPath, err := filepath.Abs(path)
	if err != nil {
		return "", fmt.Errorf("failed to resolve path: %w", err)
	}
	if err := s.validatePath(absPath); err != nil {
		return "", err
	}
	relPath, err := s.toRelativePath(absPath)
	if err != nil {
		return "", err
	}
	return s.registry.SetRegisteredFileOwner(relPath, owner)
}

// GetRegisteredFileGroup returns the group for a registered file.
func (s *Security) GetRegisteredFileGroup(path string) (string, error) {
	absPath, err := filepath.Abs(path)
	if err != nil {
		return "", fmt.Errorf("failed to resolve path: %w", err)
	}
	if err := s.validatePath(absPath); err != nil {
		return "", err
	}
	relPath, err := s.toRelativePath(absPath)
	if err != nil {
		return "", err
	}
	return s.registry.GetRegisteredFileGroup(relPath)
}

// SetRegisteredFileGroup sets the group for a registered file.
func (s *Security) SetRegisteredFileGroup(path, group string) (string, error) {
	absPath, err := filepath.Abs(path)
	if err != nil {
		return "", fmt.Errorf("failed to resolve path: %w", err)
	}
	if err := s.validatePath(absPath); err != nil {
		return "", err
	}
	relPath, err := s.toRelativePath(absPath)
	if err != nil {
		return "", err
	}
	return s.registry.SetRegisteredFileGroup(relPath, group)
}

// RegisterCollection registers a collection in the registry.
func (s *Security) RegisterCollection(name string, files []string) error {
	// Validate and convert all file paths to relative
	relFiles := make([]string, len(files))
	for i, file := range files {
		// Convert to absolute first
		absPath, err := filepath.Abs(file)
		if err != nil {
			return fmt.Errorf("failed to resolve path: %w", err)
		}
		// Validate the absolute path
		if err := s.validatePath(absPath); err != nil {
			return err
		}
		// Convert absolute path to relative
		relPath, err := s.toRelativePath(absPath)
		if err != nil {
			return err
		}
		relFiles[i] = relPath
	}
	return s.registry.RegisterCollection(name, relFiles)
}

// UnregisterCollection removes a collection from the registry.
func (s *Security) UnregisterCollection(name string, ignoreMissing bool) error {
	return s.registry.UnregisterCollection(name, ignoreMissing)
}

// IsRegisteredCollection returns true if the collection is registered.
func (s *Security) IsRegisteredCollection(name string) bool {
	return s.registry.IsRegisteredCollection(name)
}

// GetRegisteredCollections returns all registered collection names.
func (s *Security) GetRegisteredCollections() []string {
	return s.registry.GetRegisteredCollections()
}

// GetRegisteredCollectionGuard returns the guard flag for a collection.
func (s *Security) GetRegisteredCollectionGuard(collectionName string) (bool, error) {
	return s.registry.GetRegisteredCollectionGuard(collectionName)
}

// SetRegisteredCollectionGuard sets the guard flag for a collection.
func (s *Security) SetRegisteredCollectionGuard(collectionName string, guard bool) error {
	return s.registry.SetRegisteredCollectionGuard(collectionName, guard)
}

// GetRegisteredCollectionFiles returns the files in a collection.
func (s *Security) GetRegisteredCollectionFiles(collectionName string) ([]string, error) {
	relPaths, err := s.registry.GetRegisteredCollectionFiles(collectionName)
	if err != nil {
		return nil, err
	}
	// Convert from relative to absolute for output
	absPaths := make([]string, len(relPaths))
	for i, relPath := range relPaths {
		absPaths[i] = s.toAbsolutePath(relPath)
	}
	return absPaths, nil
}

// CountFilesInCollection returns the number of files in a collection.
func (s *Security) CountFilesInCollection(collectionName string) (int, error) {
	return s.registry.CountFilesInCollection(collectionName)
}

// AddRegisteredFilesToRegisteredCollections adds files to collections.
func (s *Security) AddRegisteredFilesToRegisteredCollections(collectionNames []string, filePaths []string) error {
	// Validate and convert all file paths to relative
	relPaths := make([]string, len(filePaths))
	for i, path := range filePaths {
		// Convert to absolute first
		absPath, err := filepath.Abs(path)
		if err != nil {
			return fmt.Errorf("failed to resolve path: %w", err)
		}
		// Validate the absolute path
		if err := s.validatePath(absPath); err != nil {
			return err
		}
		// Convert absolute path to relative
		relPath, err := s.toRelativePath(absPath)
		if err != nil {
			return err
		}
		relPaths[i] = relPath
	}
	return s.registry.AddRegisteredFilesToRegisteredCollections(collectionNames, relPaths)
}

// RemoveRegisteredFilesFromRegisteredCollections removes files from collections.
func (s *Security) RemoveRegisteredFilesFromRegisteredCollections(collectionNames []string, filePaths []string) error {
	// Validate and convert all file paths to relative
	relPaths := make([]string, len(filePaths))
	for i, path := range filePaths {
		// Convert to absolute first
		absPath, err := filepath.Abs(path)
		if err != nil {
			return fmt.Errorf("failed to resolve path: %w", err)
		}
		// Validate the absolute path
		if err := s.validatePath(absPath); err != nil {
			return err
		}
		// Convert absolute path to relative
		relPath, err := s.toRelativePath(absPath)
		if err != nil {
			return err
		}
		relPaths[i] = relPath
	}
	return s.registry.RemoveRegisteredFilesFromRegisteredCollections(collectionNames, relPaths)
}

// RemoveRegisteredFileFromAllRegisteredCollections removes a file from all collections.
func (s *Security) RemoveRegisteredFileFromAllRegisteredCollections(path string) {
	// Convert to absolute first
	absPath, err := filepath.Abs(path)
	if err != nil {
		return // Silent failure since this is a void function
	}
	// Validate and convert path
	if err := s.validatePath(absPath); err != nil {
		return // Silent failure
	}
	relPath, err := s.toRelativePath(absPath)
	if err != nil {
		return // Silent failure
	}
	s.registry.RemoveRegisteredFileFromAllRegisteredCollections(relPath)
}

// GetDefaultFileMode returns the default guard file mode.
func (s *Security) GetDefaultFileMode() os.FileMode {
	return s.registry.GetDefaultFileMode()
}

// SetDefaultFileMode sets the default guard file mode.
func (s *Security) SetDefaultFileMode(mode os.FileMode) error {
	return s.registry.SetDefaultFileMode(mode)
}

// GetDefaultFileOwner returns the default guard owner.
func (s *Security) GetDefaultFileOwner() string {
	return s.registry.GetDefaultFileOwner()
}

// SetDefaultFileOwner sets the default guard owner.
func (s *Security) SetDefaultFileOwner(owner string) {
	s.registry.SetDefaultFileOwner(owner)
}

// GetDefaultFileGroup returns the default guard group.
func (s *Security) GetDefaultFileGroup() string {
	return s.registry.GetDefaultFileGroup()
}

// SetDefaultFileGroup sets the default guard group.
func (s *Security) SetDefaultFileGroup(group string) {
	s.registry.SetDefaultFileGroup(group)
}

// GetLastToggle returns the last toggled item.
func (s *Security) GetLastToggle() (name string, toggleType string) {
	return s.registry.GetLastToggle()
}

// SetLastToggle sets the last toggled item.
func (s *Security) SetLastToggle(name string, toggleType string) {
	s.registry.SetLastToggle(name, toggleType)
}

// ClearLastToggle clears the last toggle tracking.
func (s *Security) ClearLastToggle() {
	s.registry.ClearLastToggle()
}

// GetRegisteredCollectionRawFileMode returns the raw file mode for a collection.
func (s *Security) GetRegisteredCollectionRawFileMode(collectionName string) (string, error) {
	return s.registry.GetRegisteredCollectionRawFileMode(collectionName)
}

// GetRegisteredCollectionEffectiveFileMode returns the effective file mode for a collection.
func (s *Security) GetRegisteredCollectionEffectiveFileMode(collectionName string) (os.FileMode, error) {
	return s.registry.GetRegisteredCollectionEffectiveFileMode(collectionName)
}

// SetRegisteredCollectionFileMode sets the file mode for a collection.
func (s *Security) SetRegisteredCollectionFileMode(collectionName string, fileMode os.FileMode) error {
	return s.registry.SetRegisteredCollectionFileMode(collectionName, fileMode)
}

// GetRegisteredCollectionRawOwner returns the raw owner for a collection.
func (s *Security) GetRegisteredCollectionRawOwner(collectionName string) (string, error) {
	return s.registry.GetRegisteredCollectionRawOwner(collectionName)
}

// GetRegisteredCollectionEffectiveOwner returns the effective owner for a collection.
func (s *Security) GetRegisteredCollectionEffectiveOwner(collectionName string) (string, error) {
	return s.registry.GetRegisteredCollectionEffectiveOwner(collectionName)
}

// SetRegisteredCollectionOwner sets the owner for a collection.
func (s *Security) SetRegisteredCollectionOwner(collectionName string, owner string) error {
	return s.registry.SetRegisteredCollectionOwner(collectionName, owner)
}

// GetRegisteredCollectionRawGroup returns the raw group for a collection.
func (s *Security) GetRegisteredCollectionRawGroup(collectionName string) (string, error) {
	return s.registry.GetRegisteredCollectionRawGroup(collectionName)
}

// GetRegisteredCollectionEffectiveGroup returns the effective group for a collection.
func (s *Security) GetRegisteredCollectionEffectiveGroup(collectionName string) (string, error) {
	return s.registry.GetRegisteredCollectionEffectiveGroup(collectionName)
}

// SetRegisteredCollectionGroup sets the group for a collection.
func (s *Security) SetRegisteredCollectionGroup(collectionName string, group string) error {
	return s.registry.SetRegisteredCollectionGroup(collectionName, group)
}

// GetRegisteredCollectionRawConfig returns the raw configuration for a collection.
func (s *Security) GetRegisteredCollectionRawConfig(collectionName string) (string, string, string, bool, error) {
	return s.registry.GetRegisteredCollectionRawConfig(collectionName)
}

// GetRegisteredCollectionEffectiveConfig returns the effective configuration for a collection.
func (s *Security) GetRegisteredCollectionEffectiveConfig(collectionName string) (string, string, os.FileMode, bool, error) {
	return s.registry.GetRegisteredCollectionEffectiveConfig(collectionName)
}

// ============================================================================
// Folder Methods (Dynamic Folder-Collections)
// ============================================================================

// RegisterFolder registers a folder entry in the registry.
// The name should be in @path/to/folder format, path is the relative path to the folder.
func (s *Security) RegisterFolder(name, path string) error {
	// Validate the folder path
	absPath, err := filepath.Abs(path)
	if err != nil {
		return fmt.Errorf("failed to resolve path: %w", err)
	}
	if err := s.validatePath(absPath); err != nil {
		return err
	}
	// Convert to relative for storage
	relPath, err := s.toRelativePath(absPath)
	if err != nil {
		return err
	}
	// Folder paths should be stored with ./ prefix per spec
	if !strings.HasPrefix(relPath, "./") && !strings.HasPrefix(relPath, "../") {
		relPath = "./" + relPath
	}
	return s.registry.RegisterFolder(name, relPath)
}

// UnregisterFolder removes a folder entry from the registry.
func (s *Security) UnregisterFolder(name string, ignoreMissing bool) error {
	return s.registry.UnregisterFolder(name, ignoreMissing)
}

// GetFolder returns a folder entry by name, or nil if not found.
func (s *Security) GetFolder(name string) *registry.Folder {
	return s.registry.GetFolder(name)
}

// GetFolderByPath returns a folder entry by its path, or nil if not found.
func (s *Security) GetFolderByPath(path string) *registry.Folder {
	// Convert to relative path for lookup
	absPath, err := filepath.Abs(path)
	if err != nil {
		return nil
	}
	relPath, err := s.toRelativePath(absPath)
	if err != nil {
		return nil
	}
	return s.registry.GetFolderByPath(relPath)
}

// SetFolderGuard sets the guard state of a folder.
func (s *Security) SetFolderGuard(name string, guard bool) error {
	return s.registry.SetFolderGuard(name, guard)
}

// GetFolderGuard returns the guard state of a folder.
func (s *Security) GetFolderGuard(name string) (bool, error) {
	return s.registry.GetFolderGuard(name)
}

// ListFolders returns all folder entries.
func (s *Security) ListFolders() []registry.Folder {
	return s.registry.ListFolders()
}

// GetRegisteredFolders returns a list of all folder names.
func (s *Security) GetRegisteredFolders() []string {
	return s.registry.GetRegisteredFolders()
}

// IsRegisteredFolder checks if a folder entry exists by name.
func (s *Security) IsRegisteredFolder(name string) bool {
	return s.registry.IsRegisteredFolder(name)
}

// IsRegisteredFolderByPath checks if a folder entry exists by path.
func (s *Security) IsRegisteredFolderByPath(path string) bool {
	// Convert to relative path for lookup
	absPath, err := filepath.Abs(path)
	if err != nil {
		return false
	}
	relPath, err := s.toRelativePath(absPath)
	if err != nil {
		return false
	}
	return s.registry.IsRegisteredFolderByPath(relPath)
}

// CountFolders returns the number of registered folders.
func (s *Security) CountFolders() int {
	return s.registry.CountFolders()
}
