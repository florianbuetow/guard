package manager

import (
	"errors"
	"fmt"
	"path/filepath"
	"strings"

	"github.com/florianbuetow/guard/internal/filesystem"
)

// EffectiveFolderGuardState represents the computed guard state of a folder.
// This matches the indicator states used in the TUI for collections.
type EffectiveFolderGuardState int

const (
	// FolderNotRegistered indicates the folder has no entry in the registry [ ]
	FolderNotRegistered EffectiveFolderGuardState = iota
	// FolderAllGuarded indicates folder guard=true AND all files guard=true [G]
	FolderAllGuarded
	// FolderInheritedGuard indicates folder guard=false BUT all files guard=true [g]
	FolderInheritedGuard
	// FolderMixedState indicates some files guarded, some not [~]
	FolderMixedState
	// FolderAllUnguarded indicates folder guard=false AND all files guard=false [-]
	FolderAllUnguarded
)

// String returns the indicator character for the effective guard state.
func (s EffectiveFolderGuardState) String() string {
	switch s {
	case FolderNotRegistered:
		return " "
	case FolderAllGuarded:
		return "G"
	case FolderInheritedGuard:
		return "g"
	case FolderMixedState:
		return "~"
	case FolderAllUnguarded:
		return "-"
	default:
		return "?"
	}
}

// folderNameFromPath converts a normalized folder path to a folder registry name with @ prefix.
// Removes the ./ prefix from the path for the name.
// e.g., "./src/components" -> "@src/components"
func folderNameFromPath(normalizedPath string) string {
	// Remove ./ prefix for the name
	name := strings.TrimPrefix(normalizedPath, "./")
	return "@" + name
}

// normalizeFolderPath ensures a folder path is in the correct format (starting with ./)
func normalizeFolderPath(path string) string {
	// Clean the path first
	cleanPath := strings.TrimPrefix(filepath.Clean(path), "./")
	// Return with ./ prefix
	return "./" + cleanPath
}

// GetEffectiveFolderGuardState computes the effective guard state of a folder.
// This follows the same logic as collections:
// - If folder not registered: FolderNotRegistered [ ]
// - If folder guard=true AND all files guard=true: FolderAllGuarded [G]
// - If folder guard=false BUT all files guard=true: FolderInheritedGuard [g]
// - If mixed file guard states: FolderMixedState [~]
// - If all files guard=false: FolderAllUnguarded [-]
func (m *Manager) GetEffectiveFolderGuardState(path string) (EffectiveFolderGuardState, error) {
	// Normalize path to ./relative format
	normalizedPath := normalizeFolderPath(path)
	folderName := folderNameFromPath(normalizedPath)

	// Check if folder is registered
	if !m.security.IsRegisteredFolder(folderName) {
		return FolderNotRegistered, nil
	}

	// Get folder guard state
	folderGuard, err := m.security.GetFolderGuard(folderName)
	if err != nil {
		return FolderNotRegistered, err
	}

	// Scan folder for files on disk
	files, err := m.fs.CollectImmediateFiles(path)
	if err != nil {
		return FolderNotRegistered, fmt.Errorf("failed to scan folder: %w", err)
	}

	// If no files in folder, return based on folder guard state
	if len(files) == 0 {
		if folderGuard {
			return FolderAllGuarded, nil
		}
		return FolderAllUnguarded, nil
	}

	// Count guarded vs unguarded files
	var guardedCount, unguardedCount int
	for _, filePath := range files {
		if m.security.IsRegisteredFile(filePath) {
			guard, err := m.security.GetRegisteredFileGuard(filePath)
			if err != nil {
				continue
			}
			if guard {
				guardedCount++
			} else {
				unguardedCount++
			}
		} else {
			// Unregistered file on disk - treat as unguarded for mixed state detection
			unguardedCount++
		}
	}

	totalFiles := guardedCount + unguardedCount

	// Determine effective state
	if guardedCount == totalFiles && unguardedCount == 0 {
		// All files are guarded
		if folderGuard {
			return FolderAllGuarded, nil
		}
		return FolderInheritedGuard, nil
	}

	if unguardedCount == totalFiles && guardedCount == 0 {
		// All files are unguarded
		return FolderAllUnguarded, nil
	}

	// Mixed state
	return FolderMixedState, nil
}

// ToggleFolders toggles the guard state for folders (dynamic folder-collections).
// For each folder:
// 1. If folder entry doesn't exist, create it
// 2. Scan the folder for immediate files (non-recursive)
// 3. Register any new files found
// 4. Toggle the folder guard state
// 5. Sync ALL files to the folder's new guard state
func (m *Manager) ToggleFolders(paths []string) error {
	if len(paths) == 0 {
		return fmt.Errorf("no folders specified")
	}

	// Deduplicate paths to prevent toggling same folder multiple times
	uniquePaths := deduplicatePaths(paths)

	// Process each folder
	for _, path := range uniquePaths {
		if err := m.toggleFolder(path); err != nil {
			return err
		}
	}

	if err := m.SaveRegistry(); err != nil {
		return fmt.Errorf("failed to save registry: %w", err)
	}

	return nil
}

// toggleFolder handles toggling a single folder.
func (m *Manager) toggleFolder(path string) error {
	// Validate the folder exists and is a directory
	isDir, err := m.fs.IsDir(path)
	if err != nil {
		return fmt.Errorf("folder not found: %s", path)
	}
	if !isDir {
		return fmt.Errorf("not a directory: %s", path)
	}

	// Normalize path to ./relative format
	normalizedPath := normalizeFolderPath(path)

	// Generate folder name with @ prefix
	folderName := folderNameFromPath(normalizedPath)

	// Check if folder entry exists; if not, create it
	if !m.security.IsRegisteredFolder(folderName) {
		if err := m.security.RegisterFolder(folderName, normalizedPath); err != nil {
			return fmt.Errorf("failed to register folder: %w", err)
		}
	}

	// Get current folder guard state to determine new state
	currentGuard, err := m.security.GetFolderGuard(folderName)
	if err != nil {
		return fmt.Errorf("failed to get folder guard state: %w", err)
	}
	newGuardState := !currentGuard

	// Scan folder for immediate files (non-recursive)
	files, err := m.fs.CollectImmediateFiles(path)
	if err != nil {
		return fmt.Errorf("failed to scan folder: %w", err)
	}

	// Warn if folder is empty
	if len(files) == 0 {
		m.AddWarning(NewWarning(WarningFolderEmpty, "", path))
	}

	// Get default guard config
	guardMode := m.security.GetDefaultFileMode()
	guardOwner := m.security.GetDefaultFileOwner()
	guardGroup := m.security.GetDefaultFileGroup()

	// Process each file in the folder
	for _, filePath := range files {
		// Get file info for registration
		mode, owner, group, err := m.fs.GetFileInfo(filePath)
		if err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to get file info for %s: %v", filePath, err))
			continue
		}

		// Register file if not already registered
		if !m.security.IsRegisteredFile(filePath) {
			if err := m.security.RegisterFile(filePath, mode, owner, group); err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to register %s: %v", filePath, err))
				continue
			}
		}

		// Get current file config (needed for restore permissions)
		storedOwner, storedGroup, storedMode, _, err := m.security.GetRegisteredFileConfig(filePath)
		if err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to get config for %s: %v", filePath, err))
			continue
		}

		// Apply guard state
		if newGuardState {
			// Enable guard: apply guard permissions, then set immutable
			if err := m.fs.ApplyPermissions(filePath, guardMode, guardOwner, guardGroup); err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to enable guard for %s: %v", filePath, err))
				continue
			}

			// Set immutable flag (auto-skips if not root)
			if err := m.fs.SetImmutable(filePath); err != nil {
				if errors.Is(err, filesystem.ErrRootRequired) {
					m.AddWarning(NewWarning(WarningGeneric, fmt.Sprintf("Setting immutable flag requires root privileges (sudo) for file %s - skipping", filePath)))
				} else {
					m.AddError(fmt.Sprintf("Error: Failed to set immutable flag for %s: %v", filePath, err))
				}
			}
		} else {
			// Disable guard: clear immutable first, then restore permissions
			if err := m.ensureNotImmutable(filePath); err != nil {
				if errors.Is(err, filesystem.ErrRootRequired) {
					m.AddWarning(NewWarning(WarningGeneric, fmt.Sprintf("Clearing immutable flag requires root privileges (sudo) for file %s - skipping", filePath)))
					continue
				} else {
					m.AddError(fmt.Sprintf("Error: Failed to clear immutable flag for %s: %v", filePath, err))
					continue
				}
			}

			if err := m.fs.RestorePermissions(filePath, storedMode, storedOwner, storedGroup); err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to disable guard for %s: %v", filePath, err))
				continue
			}
		}

		// Set new guard flag
		if err := m.security.SetRegisteredFileGuard(filePath, newGuardState); err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to set guard flag for %s: %v", filePath, err))
			continue
		}
	}

	// Update folder guard state
	if err := m.security.SetFolderGuard(folderName, newGuardState); err != nil {
		return fmt.Errorf("failed to set folder guard state: %w", err)
	}

	return nil
}

// EnableFolders enables guard for all files in the specified folders.
func (m *Manager) EnableFolders(paths []string) error {
	if len(paths) == 0 {
		return fmt.Errorf("no folders specified")
	}

	// Deduplicate paths to prevent processing same folder multiple times
	uniquePaths := deduplicatePaths(paths)

	for _, path := range uniquePaths {
		if err := m.enableFolder(path); err != nil {
			return err
		}
	}

	if err := m.SaveRegistry(); err != nil {
		return fmt.Errorf("failed to save registry: %w", err)
	}

	return nil
}

// enableFolder handles enabling guard for a single folder.
func (m *Manager) enableFolder(path string) error {
	// Validate the folder exists and is a directory
	isDir, err := m.fs.IsDir(path)
	if err != nil {
		return fmt.Errorf("folder not found: %s", path)
	}
	if !isDir {
		return fmt.Errorf("not a directory: %s", path)
	}

	// Normalize path to ./relative format
	normalizedPath := normalizeFolderPath(path)

	folderName := folderNameFromPath(normalizedPath)

	// Create folder entry if needed
	if !m.security.IsRegisteredFolder(folderName) {
		if err := m.security.RegisterFolder(folderName, normalizedPath); err != nil {
			return fmt.Errorf("failed to register folder: %w", err)
		}
	}

	// Scan folder for immediate files
	files, err := m.fs.CollectImmediateFiles(path)
	if err != nil {
		return fmt.Errorf("failed to scan folder: %w", err)
	}

	// Warn if folder is empty
	if len(files) == 0 {
		m.AddWarning(NewWarning(WarningFolderEmpty, "", path))
	}

	// Get default guard config
	guardMode := m.security.GetDefaultFileMode()
	guardOwner := m.security.GetDefaultFileOwner()
	guardGroup := m.security.GetDefaultFileGroup()

	// Process each file
	for _, filePath := range files {
		mode, owner, group, err := m.fs.GetFileInfo(filePath)
		if err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to get file info for %s: %v", filePath, err))
			continue
		}

		// Register file if not already registered
		if !m.security.IsRegisteredFile(filePath) {
			if err := m.security.RegisterFile(filePath, mode, owner, group); err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to register %s: %v", filePath, err))
				continue
			}
		}

		// Enable guard: apply guard permissions
		if err := m.fs.ApplyPermissions(filePath, guardMode, guardOwner, guardGroup); err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to enable guard for %s: %v", filePath, err))
			continue
		}

		// Set immutable flag
		if err := m.fs.SetImmutable(filePath); err != nil {
			if errors.Is(err, filesystem.ErrRootRequired) {
				m.AddWarning(NewWarning(WarningGeneric, fmt.Sprintf("Setting immutable flag requires root privileges (sudo) for file %s - skipping", filePath)))
			} else {
				m.AddError(fmt.Sprintf("Error: Failed to set immutable flag for %s: %v", filePath, err))
			}
		}

		// Set guard flag
		if err := m.security.SetRegisteredFileGuard(filePath, true); err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to set guard flag for %s: %v", filePath, err))
			continue
		}
	}

	// Set folder guard state to true
	if err := m.security.SetFolderGuard(folderName, true); err != nil {
		return fmt.Errorf("failed to set folder guard state: %w", err)
	}

	return nil
}

// DisableFolders disables guard for all files in the specified folders.
func (m *Manager) DisableFolders(paths []string) error {
	if len(paths) == 0 {
		return fmt.Errorf("no folders specified")
	}

	// Deduplicate paths to prevent processing same folder multiple times
	uniquePaths := deduplicatePaths(paths)

	for _, path := range uniquePaths {
		if err := m.disableFolder(path); err != nil {
			return err
		}
	}

	if err := m.SaveRegistry(); err != nil {
		return fmt.Errorf("failed to save registry: %w", err)
	}

	return nil
}

// disableFolder handles disabling guard for a single folder.
func (m *Manager) disableFolder(path string) error {
	// Validate the folder exists and is a directory
	isDir, err := m.fs.IsDir(path)
	if err != nil {
		return fmt.Errorf("folder not found: %s", path)
	}
	if !isDir {
		return fmt.Errorf("not a directory: %s", path)
	}

	// Normalize path to ./relative format
	normalizedPath := normalizeFolderPath(path)

	folderName := folderNameFromPath(normalizedPath)

	// Create folder entry if needed
	if !m.security.IsRegisteredFolder(folderName) {
		if err := m.security.RegisterFolder(folderName, normalizedPath); err != nil {
			return fmt.Errorf("failed to register folder: %w", err)
		}
	}

	// Scan folder for immediate files
	files, err := m.fs.CollectImmediateFiles(path)
	if err != nil {
		return fmt.Errorf("failed to scan folder: %w", err)
	}

	// Warn if folder is empty
	if len(files) == 0 {
		m.AddWarning(NewWarning(WarningFolderEmpty, "", path))
	}

	// Process each file
	for _, filePath := range files {
		mode, owner, group, err := m.fs.GetFileInfo(filePath)
		if err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to get file info for %s: %v", filePath, err))
			continue
		}

		// Register file if not already registered
		if !m.security.IsRegisteredFile(filePath) {
			if err := m.security.RegisterFile(filePath, mode, owner, group); err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to register %s: %v", filePath, err))
				continue
			}
		}

		// Get current file config for restoring permissions
		storedOwner, storedGroup, storedMode, _, err := m.security.GetRegisteredFileConfig(filePath)
		if err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to get config for %s: %v", filePath, err))
			continue
		}

		// Disable guard: clear immutable, then restore permissions
		if err := m.ensureNotImmutable(filePath); err != nil {
			if errors.Is(err, filesystem.ErrRootRequired) {
				m.AddWarning(NewWarning(WarningGeneric, fmt.Sprintf("Clearing immutable flag requires root privileges (sudo) for file %s - skipping", filePath)))
				continue
			} else {
				m.AddError(fmt.Sprintf("Error: Failed to clear immutable flag for %s: %v", filePath, err))
				continue
			}
		}

		if err := m.fs.RestorePermissions(filePath, storedMode, storedOwner, storedGroup); err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to disable guard for %s: %v", filePath, err))
			continue
		}

		// Set guard flag to false
		if err := m.security.SetRegisteredFileGuard(filePath, false); err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to set guard flag for %s: %v", filePath, err))
			continue
		}
	}

	// Set folder guard state to false
	if err := m.security.SetFolderGuard(folderName, false); err != nil {
		return fmt.Errorf("failed to set folder guard state: %w", err)
	}

	return nil
}

// deduplicatePaths returns a slice with duplicate paths removed.
// Paths are normalized before comparison to handle variations like "./folder" vs "folder".
func deduplicatePaths(paths []string) []string {
	seen := make(map[string]bool)
	result := make([]string, 0, len(paths))

	for _, path := range paths {
		normalized := normalizeFolderPath(path)
		if !seen[normalized] {
			seen[normalized] = true
			result = append(result, path)
		}
	}

	return result
}
