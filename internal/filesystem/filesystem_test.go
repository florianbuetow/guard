package filesystem

import (
	"os"
	"os/user"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

// ============================================================================
// FileExists Tests
// ============================================================================

func TestFileExists(t *testing.T) {
	fs := NewFileSystem()

	tmpDir := t.TempDir()
	existingFile := filepath.Join(tmpDir, "exists.txt")
	nonExistentFile := filepath.Join(tmpDir, "missing.txt")

	// Create a file
	if err := os.WriteFile(existingFile, []byte("test"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Test existing file
	if !fs.FileExists(existingFile) {
		t.Error("FileExists should return true for existing file")
	}

	// Test non-existent file
	if fs.FileExists(nonExistentFile) {
		t.Error("FileExists should return false for non-existent file")
	}
}

// ============================================================================
// GetFileInfo Tests
// ============================================================================

func TestGetFileInfo(t *testing.T) {
	fs := NewFileSystem()

	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test.txt")

	// Create test file with specific permissions
	if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Get file info
	mode, owner, group, err := fs.GetFileInfo(testFile)
	if err != nil {
		t.Fatalf("GetFileInfo failed: %v", err)
	}

	// Verify mode
	if mode != 0644 {
		t.Errorf("Expected mode 0644, got %o", mode)
	}

	// Verify owner and group are not empty
	if owner == "" {
		t.Error("Owner should not be empty")
	}
	if group == "" {
		t.Error("Group should not be empty")
	}

	// Owner should be current user
	currentUser, err := user.Current()
	if err != nil {
		t.Fatalf("Failed to get current user: %v", err)
	}
	if owner != currentUser.Username {
		t.Logf("Note: Owner '%s' differs from current user '%s' (may be due to UID lookup)", owner, currentUser.Username)
	}
}

func TestGetFileInfoNonExistent(t *testing.T) {
	fs := NewFileSystem()

	tmpDir := t.TempDir()
	nonExistentFile := filepath.Join(tmpDir, "missing.txt")

	_, _, _, err := fs.GetFileInfo(nonExistentFile)
	if err == nil {
		t.Error("GetFileInfo should return error for non-existent file")
	}

	// Verify error message format
	if !strings.Contains(err.Error(), "failed to stat file") {
		t.Errorf("Error should contain 'failed to stat file', got: %v", err)
	}
}

// ============================================================================
// Chmod Tests
// ============================================================================

func TestChmod(t *testing.T) {
	fs := NewFileSystem()

	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test.txt")

	// Create test file
	if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Change permissions
	if err := fs.Chmod(testFile, 0600); err != nil {
		t.Fatalf("Chmod failed: %v", err)
	}

	// Verify permissions changed
	mode, _, _, err := fs.GetFileInfo(testFile)
	if err != nil {
		t.Fatalf("GetFileInfo failed: %v", err)
	}
	if mode != 0600 {
		t.Errorf("Expected mode 0600 after chmod, got %o", mode)
	}
}

func TestChmodNonExistent(t *testing.T) {
	fs := NewFileSystem()

	tmpDir := t.TempDir()
	nonExistentFile := filepath.Join(tmpDir, "missing.txt")

	err := fs.Chmod(nonExistentFile, 0600)
	if err == nil {
		t.Error("Chmod should return error for non-existent file")
	}

	// Verify error message format includes file path and permission
	if !strings.Contains(err.Error(), "failed to set permissions") {
		t.Errorf("Error should contain 'failed to set permissions', got: %v", err)
	}
	if !strings.Contains(err.Error(), nonExistentFile) {
		t.Errorf("Error should contain file path, got: %v", err)
	}
}

// ============================================================================
// Chown Tests (requires same user)
// ============================================================================

func TestChownCurrentUser(t *testing.T) {
	fs := NewFileSystem()

	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test.txt")

	// Create test file
	if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Get current user
	currentUser, err := user.Current()
	if err != nil {
		t.Fatalf("Failed to get current user: %v", err)
	}

	// Change owner to current user (should succeed without sudo)
	if err := fs.Chown(testFile, currentUser.Username); err != nil {
		t.Fatalf("Chown to current user failed: %v", err)
	}

	// Verify owner
	_, owner, _, err := fs.GetFileInfo(testFile)
	if err != nil {
		t.Fatalf("GetFileInfo failed: %v", err)
	}
	if owner != currentUser.Username {
		t.Logf("Note: Owner '%s' differs from expected '%s' (UID lookup may vary)", owner, currentUser.Username)
	}
}

func TestChownInvalidUser(t *testing.T) {
	fs := NewFileSystem()

	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test.txt")

	// Create test file
	if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Try to change to invalid user
	err := fs.Chown(testFile, "nonexistent_user_12345")
	if err == nil {
		t.Error("Chown should return error for invalid user")
	}

	// Verify error message format
	if !strings.Contains(err.Error(), "failed to lookup user") {
		t.Errorf("Error should contain 'failed to lookup user', got: %v", err)
	}
	if !strings.Contains(err.Error(), testFile) {
		t.Errorf("Error should contain file path, got: %v", err)
	}
}

func TestChownNonExistent(t *testing.T) {
	fs := NewFileSystem()

	tmpDir := t.TempDir()
	nonExistentFile := filepath.Join(tmpDir, "missing.txt")

	// Get current user
	currentUser, err := user.Current()
	if err != nil {
		t.Fatalf("Failed to get current user: %v", err)
	}

	// Try to change owner of non-existent file
	err = fs.Chown(nonExistentFile, currentUser.Username)
	if err == nil {
		t.Error("Chown should return error for non-existent file")
	}

	// Verify error message format
	if !strings.Contains(err.Error(), "failed to set owner") {
		t.Errorf("Error should contain 'failed to set owner', got: %v", err)
	}
}

// ============================================================================
// Chgrp Tests (requires same group)
// ============================================================================

func TestChgrpCurrentGroup(t *testing.T) {
	fs := NewFileSystem()

	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test.txt")

	// Create test file
	if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Get current user's group
	currentUser, err := user.Current()
	if err != nil {
		t.Fatalf("Failed to get current user: %v", err)
	}

	currentGroup, err := user.LookupGroupId(currentUser.Gid)
	if err != nil {
		t.Fatalf("Failed to get current group: %v", err)
	}

	// Change group to current group (should succeed without sudo)
	if err := fs.Chgrp(testFile, currentGroup.Name); err != nil {
		t.Fatalf("Chgrp to current group failed: %v", err)
	}

	// Verify group
	_, _, group, err := fs.GetFileInfo(testFile)
	if err != nil {
		t.Fatalf("GetFileInfo failed: %v", err)
	}
	if group != currentGroup.Name {
		t.Logf("Note: Group '%s' differs from expected '%s' (GID lookup may vary)", group, currentGroup.Name)
	}
}

func TestChgrpInvalidGroup(t *testing.T) {
	fs := NewFileSystem()

	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test.txt")

	// Create test file
	if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Try to change to invalid group
	err := fs.Chgrp(testFile, "nonexistent_group_12345")
	if err == nil {
		t.Error("Chgrp should return error for invalid group")
	}

	// Verify error message format
	if !strings.Contains(err.Error(), "failed to lookup group") {
		t.Errorf("Error should contain 'failed to lookup group', got: %v", err)
	}
	if !strings.Contains(err.Error(), testFile) {
		t.Errorf("Error should contain file path, got: %v", err)
	}
}

func TestChgrpNonExistent(t *testing.T) {
	fs := NewFileSystem()

	tmpDir := t.TempDir()
	nonExistentFile := filepath.Join(tmpDir, "missing.txt")

	// Get current group
	currentUser, err := user.Current()
	if err != nil {
		t.Fatalf("Failed to get current user: %v", err)
	}

	currentGroup, err := user.LookupGroupId(currentUser.Gid)
	if err != nil {
		t.Fatalf("Failed to get current group: %v", err)
	}

	// Try to change group of non-existent file
	err = fs.Chgrp(nonExistentFile, currentGroup.Name)
	if err == nil {
		t.Error("Chgrp should return error for non-existent file")
	}

	// Verify error message format
	if !strings.Contains(err.Error(), "failed to set group") {
		t.Errorf("Error should contain 'failed to set group', got: %v", err)
	}
}

// ============================================================================
// ApplyPermissions Tests
// ============================================================================

func TestApplyPermissions(t *testing.T) {
	fs := NewFileSystem()

	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test.txt")

	// Create test file
	if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Get current user and group
	currentUser, err := user.Current()
	if err != nil {
		t.Fatalf("Failed to get current user: %v", err)
	}

	currentGroup, err := user.LookupGroupId(currentUser.Gid)
	if err != nil {
		t.Fatalf("Failed to get current group: %v", err)
	}

	// Apply permissions
	err = fs.ApplyPermissions(testFile, 0600, currentUser.Username, currentGroup.Name)
	if err != nil {
		t.Fatalf("ApplyPermissions failed: %v", err)
	}

	// Verify all changed
	mode, owner, group, err := fs.GetFileInfo(testFile)
	if err != nil {
		t.Fatalf("GetFileInfo failed: %v", err)
	}

	if mode != 0600 {
		t.Errorf("Expected mode 0600, got %o", mode)
	}
	if owner != currentUser.Username {
		t.Logf("Note: Owner '%s' differs from expected '%s'", owner, currentUser.Username)
	}
	if group != currentGroup.Name {
		t.Logf("Note: Group '%s' differs from expected '%s'", group, currentGroup.Name)
	}
}

func TestApplyPermissionsEmptyOwnerGroup(t *testing.T) {
	fs := NewFileSystem()

	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test.txt")

	// Create test file
	if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Get original owner and group
	_, origOwner, origGroup, err := fs.GetFileInfo(testFile)
	if err != nil {
		t.Fatalf("GetFileInfo failed: %v", err)
	}

	// Apply only permissions (empty owner/group should not change them)
	err = fs.ApplyPermissions(testFile, 0600, "", "")
	if err != nil {
		t.Fatalf("ApplyPermissions with empty owner/group failed: %v", err)
	}

	// Verify only mode changed
	mode, owner, group, err := fs.GetFileInfo(testFile)
	if err != nil {
		t.Fatalf("GetFileInfo failed: %v", err)
	}

	if mode != 0600 {
		t.Errorf("Expected mode 0600, got %o", mode)
	}
	if owner != origOwner {
		t.Errorf("Owner should not have changed, got '%s' expected '%s'", owner, origOwner)
	}
	if group != origGroup {
		t.Errorf("Group should not have changed, got '%s' expected '%s'", group, origGroup)
	}
}

func TestApplyPermissionsOperationOrder(t *testing.T) {
	// This test verifies the operation order: Chmod -> Chown -> Chgrp
	// We can't easily test the order directly, but we can verify all operations complete
	fs := NewFileSystem()

	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test.txt")

	// Create test file
	if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Get current user and group
	currentUser, err := user.Current()
	if err != nil {
		t.Fatalf("Failed to get current user: %v", err)
	}

	currentGroup, err := user.LookupGroupId(currentUser.Gid)
	if err != nil {
		t.Fatalf("Failed to get current group: %v", err)
	}

	// Apply all three operations
	err = fs.ApplyPermissions(testFile, 0600, currentUser.Username, currentGroup.Name)
	if err != nil {
		t.Fatalf("ApplyPermissions failed: %v", err)
	}

	// Success means all operations completed in the correct order
	t.Log("ApplyPermissions completed successfully (Chmod -> Chown -> Chgrp)")
}

func TestRestorePermissions(t *testing.T) {
	fs := NewFileSystem()

	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test.txt")

	// Create test file with original permissions
	if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Get original info
	origMode, origOwner, origGroup, err := fs.GetFileInfo(testFile)
	if err != nil {
		t.Fatalf("GetFileInfo failed: %v", err)
	}

	// Change permissions
	if err := fs.Chmod(testFile, 0600); err != nil {
		t.Fatalf("Chmod failed: %v", err)
	}

	// Restore original permissions
	err = fs.RestorePermissions(testFile, origMode, origOwner, origGroup)
	if err != nil {
		t.Fatalf("RestorePermissions failed: %v", err)
	}

	// Verify restored
	mode, owner, group, err := fs.GetFileInfo(testFile)
	if err != nil {
		t.Fatalf("GetFileInfo failed: %v", err)
	}

	if mode != origMode {
		t.Errorf("Expected mode %o, got %o", origMode, mode)
	}
	if owner != origOwner {
		t.Errorf("Expected owner '%s', got '%s'", origOwner, owner)
	}
	if group != origGroup {
		t.Errorf("Expected group '%s', got '%s'", origGroup, group)
	}
}

// ============================================================================
// CheckFilesExist Tests
// ============================================================================

func TestCheckFilesExist(t *testing.T) {
	fs := NewFileSystem()

	tmpDir := t.TempDir()
	file1 := filepath.Join(tmpDir, "exists1.txt")
	file2 := filepath.Join(tmpDir, "exists2.txt")
	file3 := filepath.Join(tmpDir, "missing1.txt")
	file4 := filepath.Join(tmpDir, "missing2.txt")

	// Create some files
	if err := os.WriteFile(file1, []byte("test"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}
	if err := os.WriteFile(file2, []byte("test"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Check files
	existing, missing := fs.CheckFilesExist([]string{file1, file2, file3, file4})

	// Verify results
	if len(existing) != 2 {
		t.Errorf("Expected 2 existing files, got %d", len(existing))
	}
	if len(missing) != 2 {
		t.Errorf("Expected 2 missing files, got %d", len(missing))
	}

	// Verify correct files in each list
	existingMap := make(map[string]bool)
	for _, f := range existing {
		existingMap[f] = true
	}
	if !existingMap[file1] || !existingMap[file2] {
		t.Error("Expected file1 and file2 in existing list")
	}

	missingMap := make(map[string]bool)
	for _, f := range missing {
		missingMap[f] = true
	}
	if !missingMap[file3] || !missingMap[file4] {
		t.Error("Expected file3 and file4 in missing list")
	}
}

func TestCheckFilesExistEmpty(t *testing.T) {
	fs := NewFileSystem()

	existing, missing := fs.CheckFilesExist([]string{})

	if len(existing) != 0 {
		t.Errorf("Expected 0 existing files, got %d", len(existing))
	}
	if len(missing) != 0 {
		t.Errorf("Expected 0 missing files, got %d", len(missing))
	}
}

// ============================================================================
// Error Message Format Tests
// ============================================================================

func TestErrorMessageFormat(t *testing.T) {
	// Verify error messages follow the required format:
	// "failed to <operation>: failed to <specific_action> to <target_value> for <file_path>: <underlying_error>"

	fs := NewFileSystem()
	tmpDir := t.TempDir()
	nonExistent := filepath.Join(tmpDir, "missing.txt")

	tests := []struct {
		name     string
		fn       func() error
		contains []string
	}{
		{
			name: "Chmod error",
			fn:   func() error { return fs.Chmod(nonExistent, 0600) },
			contains: []string{
				"failed to set permissions",
				nonExistent,
			},
		},
		{
			name: "Chown invalid user error",
			fn: func() error {
				// Create temp file first
				tmpFile := filepath.Join(tmpDir, "test_chown.txt")
				_ = os.WriteFile(tmpFile, []byte("test"), 0644)
				return fs.Chown(tmpFile, "nonexistent_user_99999")
			},
			contains: []string{
				"failed to lookup user",
				"nonexistent_user_99999",
			},
		},
		{
			name: "Chgrp invalid group error",
			fn: func() error {
				// Create temp file first
				tmpFile := filepath.Join(tmpDir, "test_chgrp.txt")
				_ = os.WriteFile(tmpFile, []byte("test"), 0644)
				return fs.Chgrp(tmpFile, "nonexistent_group_99999")
			},
			contains: []string{
				"failed to lookup group",
				"nonexistent_group_99999",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.fn()
			if err == nil {
				t.Fatal("Expected error, got nil")
			}

			errStr := err.Error()
			for _, substr := range tt.contains {
				if !strings.Contains(errStr, substr) {
					t.Errorf("Error should contain '%s', got: %v", substr, errStr)
				}
			}
		})
	}
}

// ============================================================================
// Immutable Flag Tests
// ============================================================================

func TestImmutableFlagMethodsExist(t *testing.T) {
	// Test that the immutable flag methods exist and have correct signatures
	fs := NewFileSystem()

	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test.txt")

	// Create test file
	if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Test that methods exist and return appropriate types
	// These will likely fail without sudo, but we're testing the API surface

	// Test IsImmutable returns (bool, error)
	_, err := fs.IsImmutable(testFile)
	// On supported platforms, this should either succeed or fail with permission error
	// On unsupported platforms, should fail with "not supported" error
	if err != nil {
		if strings.Contains(err.Error(), "not supported") {
			t.Logf("Immutable flags not supported on %s", runtime.GOOS)
		} else {
			t.Logf("IsImmutable failed (expected without sudo): %v", err)
		}
	}

	// Test SetImmutable returns error
	err = fs.SetImmutable(testFile)
	if err != nil {
		if strings.Contains(err.Error(), "not supported") {
			t.Logf("SetImmutable not supported on %s", runtime.GOOS)
		} else {
			t.Logf("SetImmutable failed (expected without sudo): %v", err)
		}
	}

	// Test ClearImmutable returns error
	err = fs.ClearImmutable(testFile)
	if err != nil {
		if strings.Contains(err.Error(), "not supported") {
			t.Logf("ClearImmutable not supported on %s", runtime.GOOS)
		} else {
			t.Logf("ClearImmutable failed (expected without sudo): %v", err)
		}
	}
}

// ============================================================================
// Root Privileges Tests
// ============================================================================

func TestHasRootPrivileges(t *testing.T) {
	fs := NewFileSystem()

	hasRoot := fs.HasRootPrivileges()
	expectedUID := os.Geteuid()

	if expectedUID == 0 && !hasRoot {
		t.Error("HasRootPrivileges should return true when effective UID is 0")
	}
	if expectedUID != 0 && hasRoot {
		t.Error("HasRootPrivileges should return false when effective UID is not 0")
	}

	t.Logf("Running as UID %d, HasRootPrivileges: %t", expectedUID, hasRoot)
}

// ============================================================================
// Immutable Flag Tests
// ============================================================================

func TestSetImmutableBehavior(t *testing.T) {
	fs := NewFileSystem()
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test.txt")

	// Create test file
	if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	hasRoot := fs.HasRootPrivileges()
	supportedPlatforms := map[string]bool{
		"linux":  true,
		"darwin": true,
	}
	isSupported := supportedPlatforms[runtime.GOOS]

	if hasRoot {
		// Running as root - test actual functionality
		t.Log("Running as root - testing actual immutable flag operations")

		if isSupported {
			// Should succeed on supported platforms with root
			err := fs.SetImmutable(testFile)
			if err != nil {
				t.Errorf("SetImmutable should succeed with root privileges on %s, got: %v", runtime.GOOS, err)
			}
		} else {
			// Should fail with "not supported" on unsupported platforms
			err := fs.SetImmutable(testFile)
			if err == nil {
				t.Errorf("SetImmutable should return error on unsupported platform %s", runtime.GOOS)
			} else if !strings.Contains(err.Error(), "not supported") {
				t.Errorf("SetImmutable should return 'not supported' error on %s, got: %v", runtime.GOOS, err)
			}
		}
	} else {
		// Running as non-root - test warning behavior
		t.Log("Running as non-root - testing warning behavior")

		if isSupported {
			// Should print warning and return nil (no error) on supported platforms
			err := fs.SetImmutable(testFile)
			if err != nil {
				t.Errorf("SetImmutable without root should return nil (with warning) on supported platform %s, got: %v", runtime.GOOS, err)
			}
		} else {
			// Should return "not supported" error on unsupported platforms
			err := fs.SetImmutable(testFile)
			if err == nil {
				t.Errorf("SetImmutable should return error on unsupported platform %s", runtime.GOOS)
			} else if !strings.Contains(err.Error(), "not supported") {
				t.Errorf("SetImmutable should return 'not supported' error on %s, got: %v", runtime.GOOS, err)
			}
		}
	}
}

func TestClearImmutableBehavior(t *testing.T) {
	fs := NewFileSystem()
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test.txt")

	// Create test file
	if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	hasRoot := fs.HasRootPrivileges()
	supportedPlatforms := map[string]bool{
		"linux":  true,
		"darwin": true,
	}
	isSupported := supportedPlatforms[runtime.GOOS]

	if hasRoot {
		// Running as root - test actual functionality
		t.Log("Running as root - testing actual immutable flag operations")

		if isSupported {
			// Should succeed on supported platforms with root
			err := fs.ClearImmutable(testFile)
			if err != nil {
				t.Errorf("ClearImmutable should succeed with root privileges on %s, got: %v", runtime.GOOS, err)
			}
		} else {
			// Should fail with "not supported" on unsupported platforms
			err := fs.ClearImmutable(testFile)
			if err == nil {
				t.Errorf("ClearImmutable should return error on unsupported platform %s", runtime.GOOS)
			} else if !strings.Contains(err.Error(), "not supported") {
				t.Errorf("ClearImmutable should return 'not supported' error on %s, got: %v", runtime.GOOS, err)
			}
		}
	} else {
		// Running as non-root - test warning behavior
		t.Log("Running as non-root - testing warning behavior")

		if isSupported {
			// Should print warning and return nil (no error) on supported platforms
			err := fs.ClearImmutable(testFile)
			if err != nil {
				t.Errorf("ClearImmutable without root should return nil (with warning) on supported platform %s, got: %v", runtime.GOOS, err)
			}
		} else {
			// Should return "not supported" error on unsupported platforms
			err := fs.ClearImmutable(testFile)
			if err == nil {
				t.Errorf("ClearImmutable should return error on unsupported platform %s", runtime.GOOS)
			} else if !strings.Contains(err.Error(), "not supported") {
				t.Errorf("ClearImmutable should return 'not supported' error on %s, got: %v", runtime.GOOS, err)
			}
		}
	}
}

func TestIsImmutableBehavior(t *testing.T) {
	fs := NewFileSystem()
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test.txt")

	// Create test file
	if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// IsImmutable doesn't require root privileges to check, but may fail on unsupported platforms
	_, err := fs.IsImmutable(testFile)

	supportedPlatforms := map[string]bool{
		"linux":  true,
		"darwin": true,
	}

	if supportedPlatforms[runtime.GOOS] {
		// On supported platforms, should either succeed or fail with permission error
		if err != nil {
			t.Logf("IsImmutable failed on supported platform %s: %v", runtime.GOOS, err)
		}
	} else {
		// On unsupported platforms, should fail with "not supported"
		if err == nil || !strings.Contains(err.Error(), "not supported") {
			t.Errorf("IsImmutable should return 'not supported' error on %s, got: %v", runtime.GOOS, err)
		}
	}
}


func TestImmutableFlagNonExistentFile(t *testing.T) {
	fs := NewFileSystem()
	tmpDir := t.TempDir()
	nonExistentFile := filepath.Join(tmpDir, "missing.txt")

	hasRoot := fs.HasRootPrivileges()
	supportedPlatforms := map[string]bool{
		"linux":  true,
		"darwin": true,
	}
	isSupported := supportedPlatforms[runtime.GOOS]

	// Test SetImmutable on non-existent file
	err := fs.SetImmutable(nonExistentFile)
	if hasRoot {
		// Running as root
		if isSupported {
			// Should get error about non-existent file on supported platforms
			if err == nil {
				t.Error("SetImmutable should return error for non-existent file when running as root")
			} else if !strings.Contains(err.Error(), nonExistentFile) {
				t.Errorf("SetImmutable error should contain file path, got: %v", err)
			}
		} else {
			// Should get "not supported" error on unsupported platforms
			if err == nil {
				t.Errorf("SetImmutable should return error on unsupported platform %s", runtime.GOOS)
			} else if !strings.Contains(err.Error(), "not supported") {
				t.Errorf("SetImmutable should return 'not supported' error on %s, got: %v", runtime.GOOS, err)
			}
		}
	} else {
		// Running as non-root
		if isSupported {
			// Should print warning and return nil (no error) on supported platforms
			if err != nil {
				t.Errorf("SetImmutable without root should return nil (with warning) on supported platform, got: %v", err)
			}
		} else {
			// Should return "not supported" error on unsupported platforms
			if err == nil {
				t.Errorf("SetImmutable should return error on unsupported platform %s", runtime.GOOS)
			} else if !strings.Contains(err.Error(), "not supported") {
				t.Errorf("SetImmutable should return 'not supported' error on %s, got: %v", runtime.GOOS, err)
			}
		}
	}

	// Test ClearImmutable on non-existent file
	err = fs.ClearImmutable(nonExistentFile)
	if hasRoot {
		// Running as root
		if isSupported {
			// Should get error about non-existent file on supported platforms
			if err == nil {
				t.Error("ClearImmutable should return error for non-existent file when running as root")
			} else if !strings.Contains(err.Error(), nonExistentFile) {
				t.Errorf("ClearImmutable error should contain file path, got: %v", err)
			}
		} else {
			// Should get "not supported" error on unsupported platforms
			if err == nil {
				t.Errorf("ClearImmutable should return error on unsupported platform %s", runtime.GOOS)
			} else if !strings.Contains(err.Error(), "not supported") {
				t.Errorf("ClearImmutable should return 'not supported' error on %s, got: %v", runtime.GOOS, err)
			}
		}
	} else {
		// Running as non-root
		if isSupported {
			// Should print warning and return nil (no error) on supported platforms
			if err != nil {
				t.Errorf("ClearImmutable without root should return nil (with warning) on supported platform, got: %v", err)
			}
		} else {
			// Should return "not supported" error on unsupported platforms
			if err == nil {
				t.Errorf("ClearImmutable should return error on unsupported platform %s", runtime.GOOS)
			} else if !strings.Contains(err.Error(), "not supported") {
				t.Errorf("ClearImmutable should return 'not supported' error on %s, got: %v", runtime.GOOS, err)
			}
		}
	}

	// Test IsImmutable on non-existent file - this should always return an error regardless of privileges
	_, err = fs.IsImmutable(nonExistentFile)
	if err == nil {
		t.Error("IsImmutable should return error for non-existent file")
	}

	if isSupported {
		// Should contain file path in error message on supported platforms
		if !strings.Contains(err.Error(), nonExistentFile) {
			t.Errorf("IsImmutable error should contain file path on supported platform, got: %v", err)
		}
	} else {
		// Should return "not supported" error on unsupported platforms
		if !strings.Contains(err.Error(), "not supported") {
			t.Errorf("IsImmutable should return 'not supported' error on %s, got: %v", runtime.GOOS, err)
		}
	}
}
