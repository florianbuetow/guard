//go:build linux || darwin

package filesystem

import (
	"os"
	"testing"

	"golang.org/x/sys/unix"
)

// TestImmutableFlagsOnUnix tests the actual ioctl functionality for immutable flags on Unix systems.
// This test only runs on Linux and macOS and requires root privileges on Linux.
// It tests on a filesystem that supports inode flags.
func TestImmutableFlagsOnUnix(t *testing.T) {
	fs := NewFileSystem()

	// Skip if not running as root (required for immutable flags on Linux)
	if !fs.HasRootPrivileges() {
		t.Skip("Test requires root privileges to set/clear immutable flags")
	}

	// Create test file on a filesystem that supports inode flags
	// Try to use /home instead of /tmp since /tmp is often tmpfs
	testFile := "/home/paul/test_guard_immutable_unit_test.txt"
	// Clean up any existing file first
	os.Remove(testFile)

	// Create test file
	if err := os.WriteFile(testFile, []byte("original content"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}
	defer os.Remove(testFile)

	// Check if filesystem supports immutable flags by testing the ioctl
	f, err := os.OpenFile(testFile, os.O_RDONLY, 0)
	if err != nil {
		t.Fatalf("Failed to open test file: %v", err)
	}
	defer f.Close()

	// Try to get flags - this will fail on unsupported filesystems
	_, err = unix.IoctlGetUint32(int(f.Fd()), 0x80086601) // FS_IOC_GETFLAGS on Linux
	if err != nil {
		// On macOS, try the macOS equivalent or skip if not supported
		t.Skipf("Filesystem does not support immutable flags ioctl (%v), likely tmpfs or unsupported filesystem", err)
	}

	t.Log("Testing immutable flag operations on supported filesystem")

	// Test initial state - should not be immutable
	isImmutable, err := fs.IsImmutable(testFile)
	if err != nil {
		t.Fatalf("IsImmutable failed: %v", err)
	}
	if isImmutable {
		t.Error("File should not be immutable initially")
	}

	// Test setting immutable flag
	if err := fs.SetImmutable(testFile); err != nil {
		t.Fatalf("SetImmutable failed: %v", err)
	}

	// Verify immutable flag is set
	isImmutable, err = fs.IsImmutable(testFile)
	if err != nil {
		t.Fatalf("IsImmutable failed after setting: %v", err)
	}
	if !isImmutable {
		t.Error("File should be immutable after SetImmutable")
	}

	// Test that file cannot be modified while immutable
	err = os.WriteFile(testFile, []byte("modified content"), 0644)
	if err == nil {
		t.Error("File modification should fail when immutable")
	} else {
		t.Logf("Expected: File modification failed as expected: %v", err)
	}

	// Test clearing immutable flag
	if err := fs.ClearImmutable(testFile); err != nil {
		t.Fatalf("ClearImmutable failed: %v", err)
	}

	// Verify immutable flag is cleared
	isImmutable, err = fs.IsImmutable(testFile)
	if err != nil {
		t.Fatalf("IsImmutable failed after clearing: %v", err)
	}
	if isImmutable {
		t.Error("File should not be immutable after ClearImmutable")
	}

	// Test that file can be modified after clearing immutable
	err = os.WriteFile(testFile, []byte("modified content"), 0644)
	if err != nil {
		t.Fatalf("File modification should succeed after clearing immutable: %v", err)
	}

	content, err := os.ReadFile(testFile)
	if err != nil {
		t.Fatalf("Failed to read file: %v", err)
	}
	if string(content) != "modified content" {
		t.Error("File content was not modified as expected")
	}

	t.Log("All immutable flag operations completed successfully")
}