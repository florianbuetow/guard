package manager

import (
	"errors"
	"fmt"

	"github.com/florianbuetow/guard/internal/filesystem"
)

// ToggleFolderResult contains the results of toggling files in a folder.
type ToggleFolderResult struct {
	Path          string
	NewGuardState bool
	AffectedFiles int
}

// ToggleFilesInFolder toggles guard state for all files in a folder.
// If recursive is true, includes files in subdirectories.
// The new guard state is determined by majority of current guard states.
func (m *Manager) ToggleFilesInFolder(path string, recursive bool) (*ToggleFolderResult, error) {
	if m.security == nil {
		return nil, fmt.Errorf("registry not loaded")
	}

	var files []string
	var err error
	if recursive {
		files, err = m.fs.CollectFilesRecursive(path)
	} else {
		files, err = m.fs.CollectImmediateFiles(path)
	}
	if err != nil {
		return nil, err
	}
	if len(files) == 0 {
		return &ToggleFolderResult{Path: path, NewGuardState: false, AffectedFiles: 0}, nil
	}

	guardedCount := 0
	for _, filePath := range files {
		status, err := m.GetFileStatus(filePath)
		if err == nil && status.Registered && status.Guard {
			guardedCount++
		}
	}

	newGuard := guardedCount <= len(files)/2
	affected := 0

	for _, filePath := range files {
		if !m.security.IsRegisteredFile(filePath) {
			mode, owner, group, err := m.fs.GetFileInfo(filePath)
			if err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to get file info for %s: %v", filePath, err))
				continue
			}

			if err := m.security.RegisterFile(filePath, mode, owner, group); err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to register %s: %v", filePath, err))
				continue
			}
		}

		if newGuard {
			guardMode := m.security.GetDefaultFileMode()
			guardOwner := m.security.GetDefaultFileOwner()
			guardGroup := m.security.GetDefaultFileGroup()

			if err := m.fs.ApplyPermissions(filePath, guardMode, guardOwner, guardGroup); err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to apply guard permissions to %s: %v", filePath, err))
				continue
			}

			if err := m.fs.SetImmutable(filePath); err != nil {
				if errors.Is(err, filesystem.ErrRootRequired) {
					m.AddWarning(NewWarning(WarningGeneric, fmt.Sprintf("Setting immutable flag requires root privileges (sudo) for file %s - skipping", filePath)))
				} else {
					m.AddError(fmt.Sprintf("Error: Failed to set immutable flag for %s: %v", filePath, err))
				}
			}
		} else {
			owner, group, mode, _, err := m.security.GetRegisteredFileConfig(filePath)
			if err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to get original config for %s: %v", filePath, err))
				continue
			}

			if err := m.fs.ClearImmutable(filePath); err != nil {
				if errors.Is(err, filesystem.ErrRootRequired) {
					m.AddWarning(NewWarning(WarningGeneric, fmt.Sprintf("Clearing immutable flag requires root privileges (sudo) for file %s - skipping", filePath)))
				} else {
					m.AddError(fmt.Sprintf("Error: Failed to clear immutable flag for %s: %v", filePath, err))
					continue
				}
			}

			if err := m.fs.RestorePermissions(filePath, mode, owner, group); err != nil {
				m.AddError(fmt.Sprintf("Error: Failed to restore permissions for %s: %v", filePath, err))
				continue
			}
		}

		if err := m.security.SetRegisteredFileGuard(filePath, newGuard); err != nil {
			m.AddError(fmt.Sprintf("Error: Failed to set guard flag for %s: %v", filePath, err))
			continue
		}

		affected++
	}

	if err := m.SaveRegistry(); err != nil {
		return nil, fmt.Errorf("failed to save registry: %w", err)
	}

	return &ToggleFolderResult{Path: path, NewGuardState: newGuard, AffectedFiles: affected}, nil
}
