package manager

import (
	"errors"
	"fmt"

	"github.com/florianbuetow/guard/internal/filesystem"
)

// ensureNotImmutable ensures a file can be safely chmod/chown by clearing the
// immutable flag when possible. If the file is immutable and requires root to
// clear, returns ErrRootRequired so callers can skip restoration.
func (m *Manager) ensureNotImmutable(path string) error {
	if err := m.fs.ClearImmutable(path); err != nil {
		if errors.Is(err, filesystem.ErrRootRequired) {
			immutable, immErr := m.fs.IsImmutable(path)
			if immErr != nil {
				return fmt.Errorf("failed to check immutable flag for %s: %w", path, immErr)
			}
			if immutable {
				return err
			}
			// Not immutable; safe to proceed without clearing.
			return nil
		}
		return err
	}
	return nil
}
