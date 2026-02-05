package manager

import (
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/florianbuetow/guard/internal/filesystem"
)

// reservedKeywords contains all collection names that are not allowed.
// These are reserved for command syntax parsing.
var reservedKeywords = map[string]bool{
	"to":         true,
	"from":       true,
	"add":        true,
	"remove":     true,
	"file":       true,
	"collection": true,
	"create":     true,
	"destroy":    true,
	"clear":      true,
	"update":     true,
	"uninstall":  true,
}

// validateCollectionNames checks for reserved keywords.
// Returns error if any collection name is a reserved keyword (Requirement 3.6).
func validateCollectionNames(names []string) error {
	for _, name := range names {
		if reservedKeywords[name] {
			return fmt.Errorf("collection name '%s' is a reserved keyword", name)
		}
	}
	return nil
}

// CollectionInfo represents a collection and optional file details for display.
type CollectionInfo struct {
	Name      string
	Guard     bool
	FileCount int
	Files     []FileStatus
}

// CollectionSummary aggregates guarded vs unguarded totals.
type CollectionSummary struct {
	Total     int
	Guarded   int
	Unguarded int
}

// AddCollections registers new collections in the registry.
// Per Requirement 3.2 and 3.3: Shows warning if collection already exists.
// Per CLI-INTERFACE-SPECS.md line 80: Idempotent - no duplicates created.
func (m *Manager) AddCollections(names []string) error {
	if len(names) == 0 {
		return fmt.Errorf("no collections specified")
	}

	// Check for reserved keywords
	if err := validateCollectionNames(names); err != nil {
		return err
	}

	for _, name := range names {
		if m.security.IsRegisteredCollection(name) {
			m.AddWarning(NewWarning(WarningCollectionAlreadyExists, "", name))
			continue
		}

		// Register collection with empty file list
		if err := m.security.RegisterCollection(name, []string{}); err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to register collection %s: %v", name, err))
			continue
		}
	}

	if err := m.SaveRegistry(); err != nil {
		return fmt.Errorf("failed to save registry: %w", err)
	}

	return nil
}

// RemoveCollections disables guard for all files in the collections and removes the collections.
// Per Requirement 3.4: Disables guard for all files and removes the collection.
// Per CLI-INTERFACE-SPECS.md lines 82-87: Collects all files, deduplicates, warns for missing,
// removes and disables guard (like guard remove file), then removes collections.
func (m *Manager) RemoveCollections(names []string) error {
	if len(names) == 0 {
		return fmt.Errorf("no collections specified")
	}

	// Check for reserved keywords
	if err := validateCollectionNames(names); err != nil {
		return err
	}

	// Collect all files from all collections (deduplicated)
	allFiles := make(map[string]bool)
	for _, name := range names {
		if !m.security.IsRegisteredCollection(name) {
			m.AddWarning(NewWarning(WarningCollectionNotFound, "", name))
			continue
		}

		files, err := m.security.GetRegisteredCollectionFiles(name)
		if err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to get files from collection %s: %v", name, err))
			continue
		}

		if len(files) == 0 {
			m.AddWarning(NewWarning(WarningCollectionEmpty, "", name))
		}

		for _, file := range files {
			allFiles[file] = true
		}
	}

	// Check which files exist
	filePaths := make([]string, 0, len(allFiles))
	for file := range allFiles {
		filePaths = append(filePaths, file)
	}
	existing, missing := m.fs.CheckFilesExist(filePaths)

	// Warn about missing files and suggest cleanup (convert to relative paths for display)
	if len(missing) > 0 {
		m.AddWarning(NewWarning(WarningFileMissing, "", m.toDisplayPaths(missing)...))
	}

	// Disable guard for all existing files (like guard remove file)
	for _, path := range existing {
		if !m.security.IsRegisteredFile(path) {
			continue
		}

		// Get file config
		owner, group, mode, guard, err := m.security.GetRegisteredFileConfig(path)
		if err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to get config for %s: %v", path, err))
			continue
		}

		// Only restore if guard is enabled
		if guard {
			// Clear immutable flag first (must be done before chmod)
			if err := m.ensureNotImmutable(path); err != nil {
				if errors.Is(err, filesystem.ErrRootRequired) {
					m.AddWarning(NewWarning(WarningGeneric, fmt.Sprintf("Clearing immutable flag requires root privileges (sudo) for file %s - skipping", path)))
					continue
				} else {
					m.AddError(fmt.Sprintf("Error: Failed to clear immutable flag for %s: %v", path, err))
					continue
				}
			}

			if err := m.fs.RestorePermissions(path, mode, owner, group); err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to restore permissions for %s: %v", path, err))
				continue
			}

			// Set guard flag to false
			if err := m.security.SetRegisteredFileGuard(path, false); err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to disable guard for %s: %v", path, err))
				continue
			}
		}
	}

	// Remove collections from registry
	for _, name := range names {
		if !m.security.IsRegisteredCollection(name) {
			continue
		}

		if err := m.security.UnregisterCollection(name, false); err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to remove collection %s: %v", name, err))
			continue
		}
	}

	if err := m.SaveRegistry(); err != nil {
		return fmt.Errorf("failed to save registry: %w", err)
	}

	return nil
}

// ClearCollections disables guard for all files in the collections and removes files from the collections.
// The collection itself remains in the registry (now empty).
// The files remain registered in guard (not unregistered from guard).
func (m *Manager) ClearCollections(names []string) error {
	if len(names) == 0 {
		return fmt.Errorf("no collections specified")
	}

	// Check for reserved keywords
	if err := validateCollectionNames(names); err != nil {
		return err
	}

	// Step 1: Disable guard on collections and their files
	if err := m.disableCollections(names); err != nil {
		return err
	}

	// Step 2: Remove all files from the collections (collection stays, files stay registered in guard)
	for _, name := range names {
		if !m.security.IsRegisteredCollection(name) {
			// Warning already added by DisableCollections
			continue
		}

		// Get all files in the collection
		files, err := m.security.GetRegisteredCollectionFiles(name)
		if err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to get files from collection %s: %v", name, err))
			continue
		}

		// Remove all files from the collection
		if len(files) > 0 {
			if err := m.security.RemoveRegisteredFilesFromRegisteredCollections([]string{name}, files); err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to clear files from collection %s: %v", name, err))
				continue
			}
		}
	}

	if err := m.SaveRegistry(); err != nil {
		return fmt.Errorf("failed to save registry: %w", err)
	}

	return nil
}

// ToggleCollections toggles the guard status of all files in the specified collections.
// Per Requirement 3.5: CRITICAL - Detects conflicts when multiple collections share files with different guard states.
// Conflict = multiple collections AND share files AND different guard states → Error, list files, NO state changes.
// Per CLI-INTERFACE-SPECS.md lines 89-95: Error on conflict, toggles guard for all existing files and collections.
func (m *Manager) ToggleCollections(names []string) error {
	if len(names) == 0 {
		return fmt.Errorf("no collections specified")
	}

	// Check for reserved keywords
	if err := validateCollectionNames(names); err != nil {
		return err
	}

	// Check all collections exist
	m.warnMissingCollections(names)

	// Conflict detection (Requirement 3.5)
	// Conflict occurs only when: (1) multiple collections, (2) share files, AND (3) different guard states
	if err := m.checkToggleCollectionConflicts(names); err != nil {
		return err
	}

	// Collect all files from all collections (deduplicated)
	allFiles := m.collectCollectionFiles(names)

	// Check which files exist
	filePaths := mapKeys(allFiles)
	existing, missing := m.fs.CheckFilesExist(filePaths)

	// Warn about missing files and suggest cleanup
	if len(missing) > 0 {
		m.AddWarning(NewWarning(WarningFileMissing, "", m.toDisplayPaths(missing)...))
	}

	// Determine the new collection guard state (all collections have the same state due to conflict validation)
	// We get the current state of the first valid collection and toggle it
	newCollectionGuardState, ok := m.nextCollectionGuardState(names)
	if ok {
		// Toggle guard for all existing files - sync ALL files to the collection's new guard state
		m.syncFilesToCollectionGuard(existing, newCollectionGuardState)
	}

	// Toggle guard for all collections
	m.toggleCollectionGuardFlags(names)

	if err := m.SaveRegistry(); err != nil {
		return fmt.Errorf("failed to save registry: %w", err)
	}

	return nil
}

func (m *Manager) warnMissingCollections(names []string) {
	for _, name := range names {
		if !m.security.IsRegisteredCollection(name) {
			m.AddWarning(NewWarning(WarningCollectionNotFound, "", name))
		}
	}
}

func (m *Manager) checkToggleCollectionConflicts(names []string) error {
	if len(names) <= 1 {
		return nil
	}

	collectionGuardStates := m.collectCollectionGuardStates(names)
	fileToCollections := m.mapFilesToCollections(names)
	conflictingFiles := findConflictingFiles(fileToCollections, collectionGuardStates)
	if len(conflictingFiles) == 0 {
		return nil
	}

	return buildCollectionConflictError(conflictingFiles, fileToCollections, collectionGuardStates)
}

func (m *Manager) collectCollectionGuardStates(names []string) map[string]bool {
	states := make(map[string]bool)
	for _, name := range names {
		if !m.security.IsRegisteredCollection(name) {
			continue
		}
		guard, err := m.security.GetRegisteredCollectionGuard(name)
		if err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to get guard state for collection %s: %v", name, err))
			continue
		}
		states[name] = guard
	}
	return states
}

func (m *Manager) mapFilesToCollections(names []string) map[string][]string {
	fileToCollections := make(map[string][]string)
	for _, name := range names {
		if !m.security.IsRegisteredCollection(name) {
			continue
		}
		files, err := m.security.GetRegisteredCollectionFiles(name)
		if err != nil {
			continue
		}
		for _, file := range files {
			fileToCollections[file] = append(fileToCollections[file], name)
		}
	}
	return fileToCollections
}

func findConflictingFiles(fileToCollections map[string][]string, collectionGuardStates map[string]bool) []string {
	var conflictingFiles []string
	for file, collections := range fileToCollections {
		if len(collections) < 2 {
			continue
		}
		if collectionsHaveMixedStates(collections, collectionGuardStates) {
			conflictingFiles = append(conflictingFiles, file)
		}
	}
	return conflictingFiles
}

func collectionsHaveMixedStates(collections []string, collectionGuardStates map[string]bool) bool {
	var firstState *bool
	for _, coll := range collections {
		guard, exists := collectionGuardStates[coll]
		if !exists {
			continue
		}
		if firstState == nil {
			firstState = &guard
			continue
		}
		if guard != *firstState {
			return true
		}
	}
	return false
}

func buildCollectionConflictError(conflictingFiles []string, fileToCollections map[string][]string, collectionGuardStates map[string]bool) error {
	var errMsg strings.Builder
	errMsg.WriteString("cannot toggle collections that share files with different guard states\n")
	errMsg.WriteString("Conflicting files: ")
	errMsg.WriteString(strings.Join(conflictingFiles, ", "))
	errMsg.WriteString("\n")

	for _, filePath := range conflictingFiles {
		collections := fileToCollections[filePath]
		collParts := buildCollectionStateParts(collections, collectionGuardStates)
		if len(collParts) < 2 {
			continue
		}
		collList := formatCollectionList(collParts)
		errMsg.WriteString(fmt.Sprintf("Collections %s both contain %s\n", collList, filePath))
	}

	return errors.New(strings.TrimSuffix(errMsg.String(), "\n"))
}

func buildCollectionStateParts(collections []string, collectionGuardStates map[string]bool) []string {
	var collParts []string
	for _, collName := range collections {
		if guardState, exists := collectionGuardStates[collName]; exists {
			collParts = append(collParts, fmt.Sprintf("%s (guard: %v)", collName, guardState))
		}
	}
	return collParts
}

func formatCollectionList(collParts []string) string {
	if len(collParts) == 1 {
		return collParts[0]
	}
	lastIdx := len(collParts) - 1
	collList := strings.Join(collParts[:lastIdx], ", ")
	if len(collParts) > 2 {
		collList += ","
	}
	return collList + " and " + collParts[lastIdx]
}

func (m *Manager) collectCollectionFiles(names []string) map[string]bool {
	allFiles := make(map[string]bool)
	for _, name := range names {
		if !m.security.IsRegisteredCollection(name) {
			continue
		}
		files, err := m.security.GetRegisteredCollectionFiles(name)
		if err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to get files from collection %s: %v", name, err))
			continue
		}
		if len(files) == 0 {
			m.AddWarning(NewWarning(WarningCollectionEmpty, "", name))
		}
		for _, file := range files {
			allFiles[file] = true
		}
	}
	return allFiles
}

func (m *Manager) nextCollectionGuardState(names []string) (bool, bool) {
	for _, name := range names {
		if !m.security.IsRegisteredCollection(name) {
			continue
		}
		currentGuard, err := m.security.GetRegisteredCollectionGuard(name)
		if err != nil {
			continue
		}
		return !currentGuard, true
	}
	return false, false
}

func (m *Manager) syncFilesToCollectionGuard(existing []string, newCollectionGuardState bool) {
	for _, path := range existing {
		if !m.security.IsRegisteredFile(path) {
			continue
		}
		m.applyGuardStateToFile(path, newCollectionGuardState)
	}
}

func (m *Manager) applyGuardStateToFile(path string, newGuardState bool) {
	owner, group, mode, _, err := m.security.GetRegisteredFileConfig(path)
	if err != nil {
		m.AddError(fmt.Sprintf("Error: Failed to get config for %s: %v", path, err))
		return
	}

	if newGuardState {
		if !m.enableGuardForFile(path) {
			return
		}
	} else {
		if !m.disableGuardForFile(path, mode, owner, group) {
			return
		}
	}

	if err := m.security.SetRegisteredFileGuard(path, newGuardState); err != nil {
		m.AddError(fmt.Sprintf("Error: Failed to set guard flag for %s: %v", path, err))
	}
}

func (m *Manager) enableGuardForFile(path string) bool {
	guardMode := m.security.GetDefaultFileMode()
	guardOwner := m.security.GetDefaultFileOwner()
	guardGroup := m.security.GetDefaultFileGroup()

	if err := m.fs.ApplyPermissions(path, guardMode, guardOwner, guardGroup); err != nil {
		m.AddError(fmt.Sprintf("Error: Failed to enable guard for %s: %v", path, err))
		return false
	}

	if err := m.fs.SetImmutable(path); err != nil {
		if errors.Is(err, filesystem.ErrRootRequired) {
			m.AddWarning(NewWarning(WarningGeneric, fmt.Sprintf("Setting immutable flag requires root privileges (sudo) for file %s - skipping", path)))
		} else {
			m.AddError(fmt.Sprintf("Error: Failed to set immutable flag for %s: %v", path, err))
		}
	}

	return true
}

func (m *Manager) disableGuardForFile(path string, mode os.FileMode, owner, group string) bool {
	if err := m.ensureNotImmutable(path); err != nil {
		if errors.Is(err, filesystem.ErrRootRequired) {
			m.AddWarning(NewWarning(WarningGeneric, fmt.Sprintf("Clearing immutable flag requires root privileges (sudo) for file %s - skipping", path)))
			return false
		} else {
			m.AddError(fmt.Sprintf("Error: Failed to clear immutable flag for %s: %v", path, err))
			return false
		}
	}

	if err := m.fs.RestorePermissions(path, mode, owner, group); err != nil {
		m.AddError(fmt.Sprintf("Error: Failed to disable guard for %s: %v", path, err))
		return false
	}

	return true
}

func (m *Manager) toggleCollectionGuardFlags(names []string) {
	for _, name := range names {
		if !m.security.IsRegisteredCollection(name) {
			continue
		}

		guard, err := m.security.GetRegisteredCollectionGuard(name)
		if err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to get guard state for collection %s: %v", name, err))
			continue
		}

		if err := m.security.SetRegisteredCollectionGuard(name, !guard); err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to toggle guard for collection %s: %v", name, err))
		}
	}
}

func mapKeys(values map[string]bool) []string {
	keys := make([]string, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	return keys
}

// EnableCollections enables guard for all files in the specified collections.
// Per Requirement 5.4: Enables guard for all files in the collections.
// Per CLI-INTERFACE-SPECS.md lines 97-102: Warns for empty/missing collections, enables files and collections.
func (m *Manager) EnableCollections(names []string) error {
	if len(names) == 0 {
		return fmt.Errorf("no collections specified")
	}

	// Check for reserved keywords
	if err := validateCollectionNames(names); err != nil {
		return err
	}

	// Collect all files from all collections (deduplicated)
	allFiles := make(map[string]bool)
	for _, name := range names {
		if !m.security.IsRegisteredCollection(name) {
			m.AddWarning(NewWarning(WarningCollectionNotFound, "", name))
			continue
		}

		files, err := m.security.GetRegisteredCollectionFiles(name)
		if err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to get files from collection %s: %v", name, err))
			continue
		}

		if len(files) == 0 {
			m.AddWarning(NewWarning(WarningCollectionEmpty, "", name))
		}

		for _, file := range files {
			allFiles[file] = true
		}
	}

	// Check which files exist
	filePaths := make([]string, 0, len(allFiles))
	for file := range allFiles {
		filePaths = append(filePaths, file)
	}
	existing, missing := m.fs.CheckFilesExist(filePaths)

	// Warn about missing files and suggest cleanup
	if len(missing) > 0 {
		m.AddWarning(NewWarning(WarningFileMissing, "", m.toDisplayPaths(missing)...))
	}

	// Enable guard for all existing files
	for _, path := range existing {
		if !m.security.IsRegisteredFile(path) {
			continue
		}

		// Get guard permissions
		guardMode := m.security.GetDefaultFileMode()
		guardOwner := m.security.GetDefaultFileOwner()
		guardGroup := m.security.GetDefaultFileGroup()

		// Apply guard permissions
		if err := m.fs.ApplyPermissions(path, guardMode, guardOwner, guardGroup); err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to enable guard for %s: %v", path, err))
			continue
		}

		// Set immutable flag (auto-skips if not root)
		if err := m.fs.SetImmutable(path); err != nil {
			if errors.Is(err, filesystem.ErrRootRequired) {
				m.AddWarning(NewWarning(WarningGeneric, fmt.Sprintf("Setting immutable flag requires root privileges (sudo) for file %s - skipping", path)))
			} else {
				m.AddError(fmt.Sprintf("Error: Failed to set immutable flag for %s: %v", path, err))
			}
		}

		// Set guard flag to true
		if err := m.security.SetRegisteredFileGuard(path, true); err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to set guard flag for %s: %v", path, err))
			continue
		}
	}

	// Enable guard for all collections
	for _, name := range names {
		if !m.security.IsRegisteredCollection(name) {
			continue
		}

		if err := m.security.SetRegisteredCollectionGuard(name, true); err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to enable guard for collection %s: %v", name, err))
			continue
		}
	}

	if err := m.SaveRegistry(); err != nil {
		return fmt.Errorf("failed to save registry: %w", err)
	}

	return nil
}

// DisableCollections disables guard for all files in the specified collections.
// Per CLI-INTERFACE-SPECS.md lines 104-109: Warns for empty/missing collections, disables files and collections.
func (m *Manager) DisableCollections(names []string) error {
	if err := m.disableCollections(names); err != nil {
		return err
	}

	if err := m.SaveRegistry(); err != nil {
		return fmt.Errorf("failed to save registry: %w", err)
	}

	return nil
}

func (m *Manager) disableCollections(names []string) error {
	if len(names) == 0 {
		return fmt.Errorf("no collections specified")
	}

	// Check for reserved keywords
	if err := validateCollectionNames(names); err != nil {
		return err
	}

	// Collect all files from all collections (deduplicated)
	allFiles := make(map[string]bool)
	for _, name := range names {
		if !m.security.IsRegisteredCollection(name) {
			m.AddWarning(NewWarning(WarningCollectionNotFound, "", name))
			continue
		}

		files, err := m.security.GetRegisteredCollectionFiles(name)
		if err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to get files from collection %s: %v", name, err))
			continue
		}

		if len(files) == 0 {
			m.AddWarning(NewWarning(WarningCollectionEmpty, "", name))
		}

		for _, file := range files {
			allFiles[file] = true
		}
	}

	// Check which files exist
	filePaths := make([]string, 0, len(allFiles))
	for file := range allFiles {
		filePaths = append(filePaths, file)
	}
	existing, missing := m.fs.CheckFilesExist(filePaths)

	// Warn about missing files and suggest cleanup
	if len(missing) > 0 {
		m.AddWarning(NewWarning(WarningFileMissing, "", m.toDisplayPaths(missing)...))
	}

	// Disable guard for all existing files
	for _, path := range existing {
		if !m.security.IsRegisteredFile(path) {
			continue
		}

		// Get file config
		owner, group, mode, guard, err := m.security.GetRegisteredFileConfig(path)
		if err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to get config for %s: %v", path, err))
			continue
		}

		// Only restore if guard is enabled
		if guard {
			// Clear immutable flag first (must be done before chmod)
			if err := m.ensureNotImmutable(path); err != nil {
				if errors.Is(err, filesystem.ErrRootRequired) {
					m.AddWarning(NewWarning(WarningGeneric, fmt.Sprintf("Clearing immutable flag requires root privileges (sudo) for file %s - skipping", path)))
					continue
				} else {
					m.AddError(fmt.Sprintf("Error: Failed to clear immutable flag for %s: %v", path, err))
					continue
				}
			}

			if err := m.fs.RestorePermissions(path, mode, owner, group); err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to restore permissions for %s: %v", path, err))
				continue
			}

			// Set guard flag to false
			if err := m.security.SetRegisteredFileGuard(path, false); err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to disable guard for %s: %v", path, err))
				continue
			}
		}
	}

	// Disable guard for all collections
	for _, name := range names {
		if !m.security.IsRegisteredCollection(name) {
			continue
		}

		if err := m.security.SetRegisteredCollectionGuard(name, false); err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to disable guard for collection %s: %v", name, err))
			continue
		}
	}

	return nil
}

// AddFilesToCollections adds files to collections.
// Per Requirement 4.2: ERRORS if files don't exist on disk (unlike AddFiles which warns).
// Per CLI-INTERFACE-SPECS.md lines 116-123: Creates collections if missing, adds files to each collection.
func (m *Manager) AddFilesToCollections(filePaths []string, collectionNames []string) error {
	if len(filePaths) == 0 {
		return fmt.Errorf("no files specified")
	}
	if len(collectionNames) == 0 {
		return fmt.Errorf("no collections specified")
	}

	// Check for reserved keywords
	if err := validateCollectionNames(collectionNames); err != nil {
		return err
	}

	// Check if all files exist on disk - ERROR if any missing (different from AddFiles)
	existing, missing := m.fs.CheckFilesExist(filePaths)
	if len(missing) > 0 {
		return fmt.Errorf("the following files do not exist on disk: %s", strings.Join(missing, ", "))
	}

	// Get guard mode for comparison
	guardMode := m.security.GetDefaultFileMode()

	// Register files if they don't exist in registry
	for _, path := range existing {
		if !m.security.IsRegisteredFile(path) {
			mode, owner, group, err := m.fs.GetFileInfo(path)
			if err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to get file info for %s: %v", path, err))
				continue
			}

			// Warn if file's current permissions match guard mode
			if mode == guardMode {
				m.AddWarning(NewWarning(WarningFileAlreadyGuarded, "", path))
			}

			if err := m.security.RegisterFile(path, mode, owner, group); err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to register file %s: %v", path, err))
				continue
			}
		} else {
			// File is already registered - check if it has guard enabled
			guard, err := m.security.GetRegisteredFileGuard(path)
			if err == nil && guard {
				m.AddWarning(NewWarning(WarningFileAlreadyGuarded, "", path))
			}
		}
	}

	// Create collections if they don't exist (with warnings)
	for _, name := range collectionNames {
		if !m.security.IsRegisteredCollection(name) {
			m.AddWarning(NewWarning(WarningCollectionCreated, "", name))
			if err := m.security.RegisterCollection(name, []string{}); err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to create collection %s: %v", name, err))
				continue
			}
		}
	}

	// Add all specified files to each collection
	if err := m.security.AddRegisteredFilesToRegisteredCollections(collectionNames, existing); err != nil {
		return fmt.Errorf("failed to add files to collections: %w", err)
	}

	if err := m.SaveRegistry(); err != nil {
		return fmt.Errorf("failed to save registry: %w", err)
	}

	return nil
}

// RemoveFilesFromCollections removes files from collections.
// Per CLI-INTERFACE-SPECS.md lines 127-131: Warns if collections don't exist or files not in registry.
func (m *Manager) RemoveFilesFromCollections(filePaths []string, collectionNames []string) error {
	if len(filePaths) == 0 {
		return fmt.Errorf("no files specified")
	}
	if len(collectionNames) == 0 {
		return fmt.Errorf("no collections specified")
	}

	// Check for reserved keywords
	if err := validateCollectionNames(collectionNames); err != nil {
		return err
	}

	// Warn if collections don't exist
	for _, name := range collectionNames {
		if !m.security.IsRegisteredCollection(name) {
			m.AddWarning(NewWarning(WarningCollectionNotFound, "", name))
		}
	}

	// Warn if files are not in registry
	for _, path := range filePaths {
		if !m.security.IsRegisteredFile(path) {
			m.AddWarning(NewWarning(WarningFileNotInRegistry, "", path))
		}
	}

	// Remove files from collections
	if err := m.security.RemoveRegisteredFilesFromRegisteredCollections(collectionNames, filePaths); err != nil {
		return fmt.Errorf("failed to remove files from collections: %w", err)
	}

	if err := m.SaveRegistry(); err != nil {
		return fmt.Errorf("failed to save registry: %w", err)
	}

	return nil
}

// AddCollectionsToCollections copies files from source collections to target collections.
// Per Requirement 3b.1-3b.3: Warns for missing sources, filters non-existent files, creates targets.
// Per CLI-INTERFACE-SPECS.md lines 140-144: Collects files from sources, filters missing, adds to targets.
func (m *Manager) AddCollectionsToCollections(sourceNames []string, targetNames []string) error {
	if len(sourceNames) == 0 {
		return fmt.Errorf("no source collections specified")
	}
	if len(targetNames) == 0 {
		return fmt.Errorf("no target collections specified")
	}

	// Check for reserved keywords
	if err := validateCollectionNames(sourceNames); err != nil {
		return err
	}
	if err := validateCollectionNames(targetNames); err != nil {
		return err
	}

	// Collect all files from source collections
	allFiles := make(map[string]bool)
	for _, name := range sourceNames {
		if !m.security.IsRegisteredCollection(name) {
			m.AddWarning(NewWarning(WarningCollectionNotFound, "", name))
			continue
		}

		files, err := m.security.GetRegisteredCollectionFiles(name)
		if err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to get files from collection %s: %v", name, err))
			continue
		}

		for _, file := range files {
			allFiles[file] = true
		}
	}

	// Filter out files that don't exist on disk
	filePaths := make([]string, 0, len(allFiles))
	for file := range allFiles {
		filePaths = append(filePaths, file)
	}
	existing, missing := m.fs.CheckFilesExist(filePaths)

	// Warn about missing files and suggest cleanup
	if len(missing) > 0 {
		m.AddWarning(NewWarning(WarningFileMissing, "", m.toDisplayPaths(missing)...))
	}

	// If no existing files remain, nothing to add
	if len(existing) == 0 {
		return nil
	}

	// Create target collections if they don't exist (with warnings)
	for _, name := range targetNames {
		if !m.security.IsRegisteredCollection(name) {
			m.AddWarning(NewWarning(WarningCollectionCreated, "", name))
			if err := m.security.RegisterCollection(name, []string{}); err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to create collection %s: %v", name, err))
				continue
			}
		}
	}

	// Add existing files to each target collection
	if err := m.security.AddRegisteredFilesToRegisteredCollections(targetNames, existing); err != nil {
		return fmt.Errorf("failed to add files to target collections: %w", err)
	}

	if err := m.SaveRegistry(); err != nil {
		return fmt.Errorf("failed to save registry: %w", err)
	}

	return nil
}

// RemoveCollectionsFromCollections removes files from source collections from target collections.
// Per Requirement 3b.4-3b.5: Warns for missing collections, removes file memberships.
// Per CLI-INTERFACE-SPECS.md lines 146-149: No error if files don't exist in targets.
func (m *Manager) RemoveCollectionsFromCollections(sourceNames []string, targetNames []string) error {
	if len(sourceNames) == 0 {
		return fmt.Errorf("no source collections specified")
	}
	if len(targetNames) == 0 {
		return fmt.Errorf("no target collections specified")
	}

	// Check for reserved keywords
	if err := validateCollectionNames(sourceNames); err != nil {
		return err
	}
	if err := validateCollectionNames(targetNames); err != nil {
		return err
	}

	// Warn if source collections don't exist
	for _, name := range sourceNames {
		if !m.security.IsRegisteredCollection(name) {
			m.AddWarning(NewWarning(WarningCollectionNotFound, "", name))
		}
	}

	// Warn if target collections don't exist
	for _, name := range targetNames {
		if !m.security.IsRegisteredCollection(name) {
			m.AddWarning(NewWarning(WarningCollectionNotFound, "", name))
		}
	}

	// Collect all files from source collections
	allFiles := make(map[string]bool)
	for _, name := range sourceNames {
		if !m.security.IsRegisteredCollection(name) {
			continue
		}

		files, err := m.security.GetRegisteredCollectionFiles(name)
		if err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to get files from collection %s: %v", name, err))
			continue
		}

		for _, file := range files {
			allFiles[file] = true
		}
	}

	// Convert to slice
	filePaths := make([]string, 0, len(allFiles))
	for file := range allFiles {
		filePaths = append(filePaths, file)
	}

	// Remove files from target collections
	if err := m.security.RemoveRegisteredFilesFromRegisteredCollections(targetNames, filePaths); err != nil {
		return fmt.Errorf("failed to remove files from target collections: %w", err)
	}

	if err := m.SaveRegistry(); err != nil {
		return fmt.Errorf("failed to save registry: %w", err)
	}

	return nil
}

// ListCollections returns collection status with optional file details.
// Per Requirement 6.3-6.4: Shows all collections if none specified, warnings for missing.
func (m *Manager) ListCollections(names []string, includeFiles bool) ([]CollectionInfo, *CollectionSummary, error) {
	if m.security == nil {
		return nil, nil, fmt.Errorf("registry not loaded")
	}

	var collectionsToShow []string
	if len(names) == 0 {
		collectionsToShow = m.security.GetRegisteredCollections()
	} else {
		collectionsToShow = names
	}

	var infos []CollectionInfo
	guardedCount := 0

	for _, name := range collectionsToShow {
		if !m.security.IsRegisteredCollection(name) {
			m.AddWarning(NewWarning(WarningCollectionNotFound, "", name))
			continue
		}

		guard, err := m.security.GetRegisteredCollectionGuard(name)
		if err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to get guard status for collection %s: %v", name, err))
			continue
		}

		if guard {
			guardedCount++
		}

		files, err := m.security.GetRegisteredCollectionFiles(name)
		if err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to get files for collection %s: %v", name, err))
			continue
		}

		info := CollectionInfo{
			Name:      name,
			Guard:     guard,
			FileCount: len(files),
		}

		if includeFiles {
			for _, file := range files {
				fileGuard, err := m.security.GetRegisteredFileGuard(file)
				if err != nil {
					continue
				}
				info.Files = append(info.Files, FileStatus{
					Path:       m.security.ToDisplayPath(file),
					Registered: true,
					Guard:      fileGuard,
				})
			}
		}

		infos = append(infos, info)
	}

	var summary *CollectionSummary
	if len(names) == 0 && len(infos) > 0 {
		summary = &CollectionSummary{
			Total:     len(infos),
			Guarded:   guardedCount,
			Unguarded: len(infos) - guardedCount,
		}
	}

	return infos, summary, nil
}
