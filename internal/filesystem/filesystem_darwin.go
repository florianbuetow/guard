//go:build darwin

package filesystem

import (
	"fmt"

	"golang.org/x/sys/unix"
)

// setImmutable sets SF_IMMUTABLE flag on macOS (schg)
func (fs *FileSystem) setImmutable(path string) error {
	// Get current flags to preserve them
	var stat unix.Stat_t
	if err := unix.Stat(path, &stat); err != nil {
		return fmt.Errorf("failed to get file flags for %s: %w", path, err)
	}

	// Set SF_IMMUTABLE flag while preserving existing flags
	newFlags := stat.Flags | unix.SF_IMMUTABLE
	if err := unix.Chflags(path, int(newFlags)); err != nil {
		return fmt.Errorf("failed to set system immutable flag for file %s: %w", path, err)
	}
	return nil
}

// clearImmutable clears SF_IMMUTABLE flag on macOS (chflags noschg)
func (fs *FileSystem) clearImmutable(path string) error {
	// Get current flags
	var stat unix.Stat_t
	if err := unix.Stat(path, &stat); err != nil {
		return fmt.Errorf("failed to get file flags for %s: %w", path, err)
	}

	// Clear SF_IMMUTABLE flag
	newFlags := stat.Flags &^ unix.SF_IMMUTABLE
	if err := unix.Chflags(path, int(newFlags)); err != nil {
		return fmt.Errorf("failed to clear system immutable flag for file %s: %w", path, err)
	}
	return nil
}

// isImmutable checks if SF_IMMUTABLE flag is set on macOS
func (fs *FileSystem) isImmutable(path string) (bool, error) {
	var stat unix.Stat_t
	if err := unix.Stat(path, &stat); err != nil {
		return false, fmt.Errorf("failed to get file flags for %s: %w", path, err)
	}

	return (stat.Flags & unix.SF_IMMUTABLE) != 0, nil
}
