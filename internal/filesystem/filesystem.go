package filesystem

import (
	"fmt"
	"os"
	"os/user"
	"path/filepath"
	"slices"
	"strconv"
	"syscall"
)

// FileSystem provides file system operations for the guard tool.
// It handles file existence checks, permission changes, and owner/group management.
type FileSystem struct {
	// Stateless - no fields needed
}

// NewFileSystem creates a new FileSystem instance.
func NewFileSystem() *FileSystem {
	return &FileSystem{}
}

// HasRootPrivileges returns true if the effective UID is 0 (root or sudo-elevated).
// This is required for setting system-level immutable flags.
func (fs *FileSystem) HasRootPrivileges() bool {
	return os.Geteuid() == 0
}

// FileExists checks if a file exists at the given path.
func (fs *FileSystem) FileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

// GetFileInfo retrieves the current file mode, owner, and group for a file.
// Returns an error if the file doesn't exist or if owner/group lookup fails.
func (fs *FileSystem) GetFileInfo(path string) (mode os.FileMode, owner, group string, err error) {
	// Get file info
	fileInfo, err := os.Stat(path)
	if err != nil {
		return 0, "", "", fmt.Errorf("failed to stat file %s: %w", path, err)
	}

	// Get file mode (permission bits)
	mode = fileInfo.Mode().Perm()

	// Get owner and group from system info
	stat, ok := fileInfo.Sys().(*syscall.Stat_t)
	if !ok {
		return 0, "", "", fmt.Errorf("failed to get system info for file %s", path)
	}

	// Convert UID to username
	ownerUser, err := user.LookupId(strconv.FormatUint(uint64(stat.Uid), 10))
	if err != nil {
		// If lookup fails, use UID as string
		owner = strconv.FormatUint(uint64(stat.Uid), 10)
	} else {
		owner = ownerUser.Username
	}

	// Convert GID to group name
	groupInfo, err := user.LookupGroupId(strconv.FormatUint(uint64(stat.Gid), 10))
	if err != nil {
		// If lookup fails, use GID as string
		group = strconv.FormatUint(uint64(stat.Gid), 10)
	} else {
		group = groupInfo.Name
	}

	return mode, owner, group, nil
}

// ApplyPermissions applies the specified mode, owner, and group to a file.
// Operations are performed in a specific order for security:
//  1. Chmod (set permissions first)
//  2. Chown (set owner - may require root)
//  3. Chgrp (set group - may require root)
//
// Empty owner or group strings mean "don't change".
// Returns an error if any operation fails.
func (fs *FileSystem) ApplyPermissions(path string, mode os.FileMode, owner, group string) error {
	// Step 1: Set permissions first (security - prevents race conditions)
	if err := fs.Chmod(path, mode); err != nil {
		return err
	}

	// Step 2: Set owner (if specified)
	if owner != "" {
		if err := fs.Chown(path, owner); err != nil {
			return err
		}
	}

	// Step 3: Set group (if specified)
	if group != "" {
		if err := fs.Chgrp(path, group); err != nil {
			return err
		}
	}

	return nil
}

// RestorePermissions is an alias for ApplyPermissions.
// It restores a file's original permissions, owner, and group.
func (fs *FileSystem) RestorePermissions(path string, mode os.FileMode, owner, group string) error {
	return fs.ApplyPermissions(path, mode, owner, group)
}

// Chmod changes the file mode (permissions) for the specified file.
func (fs *FileSystem) Chmod(path string, mode os.FileMode) error {
	if err := os.Chmod(path, mode); err != nil {
		return fmt.Errorf("failed to set permissions %o for file %s: %w", mode, path, err)
	}
	return nil
}

// Chown changes the owner of the specified file.
// The owner parameter should be a username. It will be converted to UID.
func (fs *FileSystem) Chown(path string, owner string) error {
	// Look up the user to get UID
	ownerUser, err := user.Lookup(owner)
	if err != nil {
		return fmt.Errorf("failed to lookup user %s for file %s: %w", owner, path, err)
	}

	// Convert username to UID
	uid, err := strconv.Atoi(ownerUser.Uid)
	if err != nil {
		return fmt.Errorf("failed to convert UID for user %s: %w", owner, err)
	}

	// Change owner (-1 for gid means don't change group)
	if err := os.Chown(path, uid, -1); err != nil {
		return fmt.Errorf("failed to set owner %s for file %s: %w", owner, path, err)
	}

	return nil
}

// Chgrp changes the group of the specified file.
// The group parameter should be a group name. It will be converted to GID.
func (fs *FileSystem) Chgrp(path string, group string) error {
	// Look up the group to get GID
	groupInfo, err := user.LookupGroup(group)
	if err != nil {
		return fmt.Errorf("failed to lookup group %s for file %s: %w", group, path, err)
	}

	// Convert group name to GID
	gid, err := strconv.Atoi(groupInfo.Gid)
	if err != nil {
		return fmt.Errorf("failed to convert GID for group %s: %w", group, err)
	}

	// Change group (-1 for uid means don't change owner)
	if err := os.Chown(path, -1, gid); err != nil {
		return fmt.Errorf("failed to set group %s for file %s: %w", group, path, err)
	}

	return nil
}

// CheckFilesExist checks which files exist and which are missing.
// Returns two slices: existing files and missing files.
func (fs *FileSystem) CheckFilesExist(paths []string) (existing, missing []string) {
	for _, path := range paths {
		if fs.FileExists(path) {
			existing = append(existing, path)
		} else {
			missing = append(missing, path)
		}
	}
	return existing, missing
}

// DirEntry represents a directory entry with metadata for sorting
type DirEntry struct {
	Name     string
	Path     string
	IsDir    bool
	IsLink   bool
	FileInfo os.FileInfo
}

// ReadDir reads a directory and returns entries sorted with folders first, then alphabetically.
// Dotfiles (hidden files starting with .) are included as per TUI spec line 193.
func (fs *FileSystem) ReadDir(path string) ([]DirEntry, error) {
	entries, err := os.ReadDir(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read directory %s: %w", path, err)
	}

	var result []DirEntry
	for _, entry := range entries {
		fullPath := filepath.Join(path, entry.Name())

		// Use Lstat to detect symlinks
		info, err := os.Lstat(fullPath)
		if err != nil {
			// Skip entries we can't stat
			continue
		}

		isLink := info.Mode()&os.ModeSymlink != 0
		isDir := entry.IsDir()

		// If it's a symlink, check what it points to
		if isLink {
			targetInfo, err := os.Stat(fullPath)
			if err == nil {
				isDir = targetInfo.IsDir()
			}
		}

		result = append(result, DirEntry{
			Name:     entry.Name(),
			Path:     fullPath,
			IsDir:    isDir,
			IsLink:   isLink,
			FileInfo: info,
		})
	}

	// Sort: directories first, then alphabetically by name
	slices.SortFunc(result, func(a, b DirEntry) int {
		// Directories come first
		if a.IsDir && !b.IsDir {
			return -1
		}
		if !a.IsDir && b.IsDir {
			return 1
		}
		// Then sort alphabetically (case-insensitive)
		aLower := a.Name
		bLower := b.Name
		if aLower < bLower {
			return -1
		}
		if aLower > bLower {
			return 1
		}
		return 0
	})

	return result, nil
}

// Lstat returns file info without following symlinks.
func (fs *FileSystem) Lstat(path string) (os.FileInfo, error) {
	info, err := os.Lstat(path)
	if err != nil {
		return nil, fmt.Errorf("failed to lstat %s: %w", path, err)
	}
	return info, nil
}

// IsSymlink checks if a path is a symbolic link.
func (fs *FileSystem) IsSymlink(path string) (bool, error) {
	info, err := os.Lstat(path)
	if err != nil {
		return false, fmt.Errorf("failed to check symlink %s: %w", path, err)
	}
	return info.Mode()&os.ModeSymlink != 0, nil
}

// IsDir checks if a path is a directory.
func (fs *FileSystem) IsDir(path string) (bool, error) {
	info, err := os.Stat(path)
	if err != nil {
		return false, fmt.Errorf("failed to check directory %s: %w", path, err)
	}
	return info.IsDir(), nil
}

// CollectImmediateFiles returns a list of regular files (not directories) directly in the folder.
// Does not recurse into subdirectories. Excludes symlinks. Dotfiles are included.
func (fs *FileSystem) CollectImmediateFiles(folder string) ([]string, error) {
	entries, err := fs.ReadDir(folder)
	if err != nil {
		return nil, err
	}

	var files []string
	for _, entry := range entries {
		if !entry.IsDir && !entry.IsLink {
			files = append(files, entry.Path)
		}
	}
	return files, nil
}

// CollectFilesRecursive returns a list of all regular files in the folder and its subdirectories.
// Excludes symlinks. Dotfiles (hidden files) are included as per TUI spec line 193.
func (fs *FileSystem) CollectFilesRecursive(folder string) ([]string, error) {
	var files []string

	err := filepath.WalkDir(folder, func(path string, d os.DirEntry, err error) error {
		if err != nil {
			return err
		}

		// Skip symlinks
		info, err := os.Lstat(path)
		if err != nil {
			return nil // Skip entries we can't stat
		}
		if info.Mode()&os.ModeSymlink != 0 {
			return nil
		}

		// Only include regular files
		if !d.IsDir() {
			files = append(files, path)
		}

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to walk directory %s: %w", folder, err)
	}

	return files, nil
}

// ============================================================================
// Immutable Flag Operations
// ============================================================================

// SetImmutable sets the system-level immutable flag on a file.
// macOS: Sets SF_IMMUTABLE (schg) - requires sudo to unset
// Linux: Sets FS_IMMUTABLE_FL (+i) - requires sudo to unset
// Prints a warning and returns nil if not running with root privileges.
func (fs *FileSystem) SetImmutable(path string) error {
	if !fs.HasRootPrivileges() {
		fmt.Printf("Warning: Setting immutable flag requires root privileges (sudo) for file %s - skipping\n", path)
		return nil
	}

	return fs.setImmutable(path)
}

// ClearImmutable removes the system-level immutable flag from a file.
// macOS: Clears SF_IMMUTABLE (chflags noschg) - requires sudo
// Linux: Clears FS_IMMUTABLE_FL (chattr -i) - requires sudo
// Prints a warning and returns nil if not running with root privileges.
func (fs *FileSystem) ClearImmutable(path string) error {
	if !fs.HasRootPrivileges() {
		fmt.Printf("Warning: Clearing immutable flag requires root privileges (sudo) for file %s - skipping\n", path)
		return nil
	}

	return fs.clearImmutable(path)
}

// IsImmutable checks if a file has the system-level immutable flag set.
// macOS: Checks for SF_IMMUTABLE (schg)
// Linux: Checks for FS_IMMUTABLE_FL (+i)
func (fs *FileSystem) IsImmutable(path string) (bool, error) {
	return fs.isImmutable(path)
}
