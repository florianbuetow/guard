//go:build linux

package filesystem

import (
	"fmt"
	"os"

	"golang.org/x/sys/unix"
)

// Linux filesystem ioctl constants
// These are part of the stable Linux kernel ABI and are defined in linux/fs.h
const (
	// FS_IOC_GETFLAGS - Get file flags
	fsIocGetFlags = 0x80086601
	// FS_IOC_SETFLAGS - Set file flags
	fsIocSetFlags = 0x40086602
	// FS_IMMUTABLE_FL - Immutable file flag
	fsImmutableFlag = 0x00000010
)

// setImmutable sets FS_IMMUTABLE_FL flag on Linux (+i)
func (fs *FileSystem) setImmutable(path string) error {
	f, err := os.OpenFile(path, os.O_RDONLY, 0)
	if err != nil {
		return fmt.Errorf("failed to open file %s for immutable flag: %w", path, err)
	}
	defer f.Close()

	// Get current flags
	flags, err := unix.IoctlGetUint32(int(f.Fd()), fsIocGetFlags)
	if err != nil {
		return fmt.Errorf("failed to get file flags for %s: %w", path, err)
	}

	// Set FS_IMMUTABLE_FL flag
	flags |= uint32(fsImmutableFlag)
	if err := unix.IoctlSetPointerInt(int(f.Fd()), fsIocSetFlags, int(flags)); err != nil {
		return fmt.Errorf("failed to set immutable flag for file %s: %w", path, err)
	}

	return nil
}

// clearImmutable clears FS_IMMUTABLE_FL flag on Linux (chattr -i)
func (fs *FileSystem) clearImmutable(path string) error {
	f, err := os.OpenFile(path, os.O_RDONLY, 0)
	if err != nil {
		return fmt.Errorf("failed to open file %s for immutable flag: %w", path, err)
	}
	defer f.Close()

	// Get current flags
	flags, err := unix.IoctlGetUint32(int(f.Fd()), fsIocGetFlags)
	if err != nil {
		return fmt.Errorf("failed to get file flags for %s: %w", path, err)
	}

	// Clear FS_IMMUTABLE_FL flag
	flags &^= uint32(fsImmutableFlag)
	if err := unix.IoctlSetPointerInt(int(f.Fd()), fsIocSetFlags, int(flags)); err != nil {
		return fmt.Errorf("failed to clear immutable flag for file %s: %w", path, err)
	}

	return nil
}

// isImmutable checks if FS_IMMUTABLE_FL flag is set on Linux
func (fs *FileSystem) isImmutable(path string) (bool, error) {
	f, err := os.OpenFile(path, os.O_RDONLY, 0)
	if err != nil {
		return false, fmt.Errorf("failed to open file %s for immutable flag check: %w", path, err)
	}
	defer f.Close()

	// Get current flags
	flags, err := unix.IoctlGetUint32(int(f.Fd()), fsIocGetFlags)
	if err != nil {
		return false, fmt.Errorf("failed to get file flags for %s: %w", path, err)
	}

	return (flags & uint32(fsImmutableFlag)) != 0, nil
}
