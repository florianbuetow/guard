package manager

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// setupTestManager creates a temporary directory and Manager for testing.
func setupTestManager(t *testing.T) (*Manager, string, func()) {
	// Create temporary directory
	tmpDir, err := os.MkdirTemp("", "guard-manager-test-*")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}

	registryPath := filepath.Join(tmpDir, ".guardfile")

	// Create manager
	mgr := NewManager(registryPath)

	// Cleanup function
	cleanup := func() {
		os.RemoveAll(tmpDir)
	}

	return mgr, tmpDir, cleanup
}

// createTestFile creates a test file with specified permissions.
func createTestFile(t *testing.T, dir string, name string, mode os.FileMode) string {
	path := filepath.Join(dir, name)
	if err := os.WriteFile(path, []byte("test content"), mode); err != nil {
		t.Fatalf("Failed to create test file %s: %v", path, err)
	}
	return path
}

// TestManagerInitialization tests creating and loading a manager.
func TestManagerInitialization(t *testing.T) {
	mgr, _, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "testuser", "testgroup", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Verify registry was created
	if mgr.GetRegistry() == nil {
		t.Fatal("Registry should not be nil after initialization")
	}

	// Verify defaults
	mode := mgr.GetRegistry().GetDefaultFileMode()
	if mode != 0600 {
		t.Errorf("Expected mode 0600, got %o", mode)
	}

	owner := mgr.GetRegistry().GetDefaultFileOwner()
	if owner != "testuser" {
		t.Errorf("Expected owner 'testuser', got %s", owner)
	}

	group := mgr.GetRegistry().GetDefaultFileGroup()
	if group != "testgroup" {
		t.Errorf("Expected group 'testgroup', got %s", group)
	}
}

// TestLoadRegistryMissing tests loading when .guardfile doesn't exist.
func TestLoadRegistryMissing(t *testing.T) {
	mgr, _, cleanup := setupTestManager(t)
	defer cleanup()

	err := mgr.LoadRegistry()
	if err == nil {
		t.Fatal("Expected error when loading non-existent registry")
	}

	expectedMsg := ".guardfile not found in current directory"
	if !strings.Contains(err.Error(), expectedMsg) {
		t.Errorf("Error should contain '%s', got: %v", expectedMsg, err)
	}
}

// TestAddFiles tests adding files to the registry.
func TestAddFiles(t *testing.T) {
	mgr, tmpDir, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "", "", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Create test files
	file1 := createTestFile(t, tmpDir, "test1.txt", 0644)
	file2 := createTestFile(t, tmpDir, "test2.txt", 0644)

	// Add files
	err = mgr.AddFiles([]string{file1, file2})
	if err != nil {
		t.Fatalf("AddFiles failed: %v", err)
	}

	// Verify files were registered
	if !mgr.GetRegistry().IsRegisteredFile(file1) {
		t.Error("File1 should be registered")
	}
	if !mgr.GetRegistry().IsRegisteredFile(file2) {
		t.Error("File2 should be registered")
	}

	// Verify no errors
	if mgr.HasErrors() {
		t.Errorf("Should not have errors, got: %v", mgr.GetErrors())
	}
}

// TestAddFilesMissing tests adding files that don't exist.
func TestAddFilesMissing(t *testing.T) {
	mgr, tmpDir, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "", "", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Add non-existent file
	missingFile := filepath.Join(tmpDir, "missing.txt")
	err = mgr.AddFiles([]string{missingFile})
	if err != nil {
		t.Fatalf("AddFiles should not error for missing files: %v", err)
	}

	// Should have warning, not error (per Requirement 2.3)
	if !mgr.HasWarnings() {
		t.Error("Should have warnings for missing files")
	}
	if mgr.HasErrors() {
		t.Errorf("Should not have errors for missing files, got: %v", mgr.GetErrors())
	}
}

// TestAddFilesIdempotent tests that adding files multiple times is idempotent.
func TestAddFilesIdempotent(t *testing.T) {
	mgr, tmpDir, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "", "", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Create test file
	file1 := createTestFile(t, tmpDir, "test1.txt", 0644)

	// Add file first time
	err = mgr.AddFiles([]string{file1})
	if err != nil {
		t.Fatalf("AddFiles failed: %v", err)
	}

	// Clear warnings
	mgr.ClearWarnings()

	// Add file second time (idempotent)
	err = mgr.AddFiles([]string{file1})
	if err != nil {
		t.Fatalf("AddFiles failed on second call: %v", err)
	}

	// Per Requirement 2.4 and 12.1: No warnings for duplicate file addition
	if mgr.HasWarnings() {
		t.Errorf("Should not have warnings for duplicate file addition, got: %v", mgr.GetWarnings())
	}
}

// TestAddCollections tests adding collections.
func TestAddCollections(t *testing.T) {
	mgr, _, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "", "", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Add collections
	err = mgr.AddCollections([]string{"coll1", "coll2"})
	if err != nil {
		t.Fatalf("AddCollections failed: %v", err)
	}

	// Verify collections were registered
	if !mgr.GetRegistry().IsRegisteredCollection("coll1") {
		t.Error("Collection coll1 should be registered")
	}
	if !mgr.GetRegistry().IsRegisteredCollection("coll2") {
		t.Error("Collection coll2 should be registered")
	}

	// Verify no errors
	if mgr.HasErrors() {
		t.Errorf("Should not have errors, got: %v", mgr.GetErrors())
	}
}

// TestAddCollectionsDuplicate tests adding collections that already exist.
func TestAddCollectionsDuplicate(t *testing.T) {
	mgr, _, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "", "", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Add collection first time
	err = mgr.AddCollections([]string{"coll1"})
	if err != nil {
		t.Fatalf("AddCollections failed: %v", err)
	}

	// Clear warnings
	mgr.ClearWarnings()

	// Add collection second time
	err = mgr.AddCollections([]string{"coll1"})
	if err != nil {
		t.Fatalf("AddCollections failed on second call: %v", err)
	}

	// Per Requirement 3.3 and 12.2: Should have warning for duplicate collection
	if !mgr.HasWarnings() {
		t.Error("Should have warnings for duplicate collection addition")
	}
}

// TestReservedCollectionNames tests that "to" and "from" are rejected.
func TestReservedCollectionNames(t *testing.T) {
	mgr, _, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "", "", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Try to add collection named "to" (reserved keyword)
	err = mgr.AddCollections([]string{"to"})
	if err == nil {
		t.Fatal("Expected error for reserved collection name 'to'")
	}

	expectedMsg := "reserved keyword"
	if !strings.Contains(err.Error(), expectedMsg) {
		t.Errorf("Error should contain '%s', got: %v", expectedMsg, err)
	}

	// Try to add collection named "from" (reserved keyword)
	err = mgr.AddCollections([]string{"from"})
	if err == nil {
		t.Fatal("Expected error for reserved collection name 'from'")
	}

	if !strings.Contains(err.Error(), expectedMsg) {
		t.Errorf("Error should contain '%s', got: %v", expectedMsg, err)
	}
}

// TestWarningAggregation tests that warnings are aggregated correctly.
func TestWarningAggregation(t *testing.T) {
	// Create multiple warnings of the same type
	warnings := []Warning{
		NewWarning(WarningFileMissing, "", "file1.txt"),
		NewWarning(WarningFileMissing, "", "file2.txt"),
		NewWarning(WarningFileMissing, "", "file3.txt"),
	}

	// Aggregate warnings
	aggregated := AggregateWarnings(warnings)

	// Should produce single message
	if len(aggregated) != 1 {
		t.Errorf("Expected 1 aggregated message, got %d", len(aggregated))
	}

	// Message should mention all files individually
	msg := aggregated[0]
	if !strings.Contains(msg, "files do not exist on disk") {
		t.Errorf("Aggregated message should mention files not existing, got: %s", msg)
	}
	if !strings.Contains(msg, "file1.txt") || !strings.Contains(msg, "file2.txt") || !strings.Contains(msg, "file3.txt") {
		t.Errorf("Aggregated message should mention all files, got: %s", msg)
	}
}

// TestWarningAggregationSilentDuplicateFiles tests that duplicate file warnings are silent.
func TestWarningAggregationSilentDuplicateFiles(t *testing.T) {
	// Create duplicate file registration warnings
	warnings := []Warning{
		NewWarning(WarningFileAlreadyInRegistry, "", "file1.txt"),
		NewWarning(WarningFileAlreadyInRegistry, "", "file2.txt"),
	}

	// Aggregate warnings
	aggregated := AggregateWarnings(warnings)

	// Per Requirement 2.4: WarningFileAlreadyInRegistry should be silent
	if len(aggregated) != 0 {
		t.Errorf("Expected 0 aggregated messages for duplicate file warnings, got %d: %v", len(aggregated), aggregated)
	}
}

// TestAddFilesToCollections tests adding files to collections.
func TestAddFilesToCollections(t *testing.T) {
	mgr, tmpDir, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "", "", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Create test files
	file1 := createTestFile(t, tmpDir, "test1.txt", 0644)
	file2 := createTestFile(t, tmpDir, "test2.txt", 0644)

	// Add files to collections (creates collections if missing)
	err = mgr.AddFilesToCollections([]string{file1, file2}, []string{"coll1", "coll2"})
	if err != nil {
		t.Fatalf("AddFilesToCollections failed: %v", err)
	}

	// Verify files are in collections
	files1, _ := mgr.GetRegistry().GetRegisteredCollectionFiles("coll1")
	if len(files1) != 2 {
		t.Errorf("Collection coll1 should have 2 files, got %d", len(files1))
	}

	files2, _ := mgr.GetRegistry().GetRegisteredCollectionFiles("coll2")
	if len(files2) != 2 {
		t.Errorf("Collection coll2 should have 2 files, got %d", len(files2))
	}
}

// TestAddFilesToCollectionsMissingFiles tests that missing files cause errors.
func TestAddFilesToCollectionsMissingFiles(t *testing.T) {
	mgr, tmpDir, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "", "", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Try to add non-existent file to collection
	missingFile := filepath.Join(tmpDir, "missing.txt")
	err = mgr.AddFilesToCollections([]string{missingFile}, []string{"coll1"})

	// Per Requirement 4.2: Should ERROR for missing files (unlike AddFiles which warns)
	if err == nil {
		t.Fatal("Expected error when adding missing files to collection")
	}

	expectedMsg := "do not exist"
	if !strings.Contains(err.Error(), expectedMsg) {
		t.Errorf("Error should mention files don't exist, got: %v", err)
	}
}

// TestCleanup tests the cleanup operation.
func TestCleanup(t *testing.T) {
	mgr, tmpDir, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "", "", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Create and add a file
	file1 := createTestFile(t, tmpDir, "test1.txt", 0644)
	err = mgr.AddFiles([]string{file1})
	if err != nil {
		t.Fatalf("AddFiles failed: %v", err)
	}

	// Create empty collection
	err = mgr.AddCollections([]string{"empty_coll"})
	if err != nil {
		t.Fatalf("AddCollections failed: %v", err)
	}

	// Delete the file from disk
	os.Remove(file1)

	// Run cleanup
	_, err = mgr.Cleanup()
	if err != nil {
		t.Fatalf("Cleanup failed: %v", err)
	}

	// Verify file was removed from registry
	if mgr.GetRegistry().IsRegisteredFile(file1) {
		t.Error("File should be removed from registry after cleanup")
	}

	// Verify empty collection was removed
	if mgr.GetRegistry().IsRegisteredCollection("empty_coll") {
		t.Error("Empty collection should be removed after cleanup")
	}
}

// TestToggleCollectionsConflictDetection tests conflict detection per Requirement 3.5.
// CRITICAL: Multiple collections, shared files, different guard states -> ERROR.
func TestToggleCollectionsConflictDetection(t *testing.T) {
	mgr, tmpDir, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "", "", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Create test file
	file1 := createTestFile(t, tmpDir, "shared.txt", 0644)

	// Add file to two collections
	err = mgr.AddFilesToCollections([]string{file1}, []string{"coll1", "coll2"})
	if err != nil {
		t.Fatalf("AddFilesToCollections failed: %v", err)
	}

	// Enable guard for coll1 only (creates different guard states)
	err = mgr.EnableCollections([]string{"coll1"})
	if err != nil {
		t.Fatalf("EnableCollections failed: %v", err)
	}

	// Verify coll1 is guarded, coll2 is not
	guard1, _ := mgr.GetRegistry().GetRegisteredCollectionGuard("coll1")
	guard2, _ := mgr.GetRegistry().GetRegisteredCollectionGuard("coll2")

	if !guard1 {
		t.Fatal("coll1 should be guarded")
	}
	if guard2 {
		t.Fatal("coll2 should not be guarded")
	}

	// Clear any warnings/errors from setup
	mgr.ClearWarnings()
	mgr.ClearErrors()

	// Try to toggle both collections (should detect conflict)
	err = mgr.ToggleCollections([]string{"coll1", "coll2"})

	// Per Requirement 3.5: Should error due to conflict
	if err == nil {
		t.Fatal("Expected error for conflicting collection toggle")
	}

	expectedMsg := "cannot toggle collections that share files with different guard states"
	if !strings.Contains(err.Error(), expectedMsg) {
		t.Errorf("Error should mention conflict, got: %v", err)
	}

	// Verify no state changes occurred (critical requirement)
	guard1After, _ := mgr.GetRegistry().GetRegisteredCollectionGuard("coll1")
	guard2After, _ := mgr.GetRegistry().GetRegisteredCollectionGuard("coll2")

	if guard1After != guard1 {
		t.Error("coll1 guard state should not have changed after conflict")
	}
	if guard2After != guard2 {
		t.Error("coll2 guard state should not have changed after conflict")
	}
}

// TestToggleCollectionsNoConflictSameState tests toggle works when collections have same guard state.
func TestToggleCollectionsNoConflictSameState(t *testing.T) {
	mgr, tmpDir, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "", "", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Create test file
	file1 := createTestFile(t, tmpDir, "shared.txt", 0644)

	// Add file to two collections
	err = mgr.AddFilesToCollections([]string{file1}, []string{"coll1", "coll2"})
	if err != nil {
		t.Fatalf("AddFilesToCollections failed: %v", err)
	}

	// Both collections have same initial guard state (false)
	// Toggle should work without conflict
	err = mgr.ToggleCollections([]string{"coll1", "coll2"})
	if err != nil {
		t.Fatalf("ToggleCollections should not error when collections have same state: %v", err)
	}

	// Both should now be guarded
	guard1, _ := mgr.GetRegistry().GetRegisteredCollectionGuard("coll1")
	guard2, _ := mgr.GetRegistry().GetRegisteredCollectionGuard("coll2")

	if !guard1 || !guard2 {
		t.Error("Both collections should be guarded after toggle")
	}
}

// TestRemoveFilesOperationOrder tests the critical 3-step removal order.
// Per CLI-INTERFACE-SPECS.md lines 46-48:
// 1. Remove from all collections
// 2. Restore permissions (error if fails)
// 3. Remove from registry
func TestRemoveFilesOperationOrder(t *testing.T) {
	mgr, tmpDir, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "", "", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Create and add test file
	file1 := createTestFile(t, tmpDir, "test1.txt", 0644)
	err = mgr.AddFiles([]string{file1})
	if err != nil {
		t.Fatalf("AddFiles failed: %v", err)
	}

	// Add file to a collection
	err = mgr.AddFilesToCollections([]string{file1}, []string{"coll1"})
	if err != nil {
		t.Fatalf("AddFilesToCollections failed: %v", err)
	}

	// Enable guard for the file
	err = mgr.EnableFiles([]string{file1})
	if err != nil {
		t.Fatalf("EnableFiles failed: %v", err)
	}

	// Verify file is in collection and guarded
	files, _ := mgr.GetRegistry().GetRegisteredCollectionFiles("coll1")
	if len(files) != 1 {
		t.Fatal("File should be in collection before removal")
	}

	// Remove file
	err = mgr.RemoveFiles([]string{file1})
	if err != nil {
		t.Fatalf("RemoveFiles failed: %v", err)
	}

	// Verify file was removed from collection
	filesAfter, _ := mgr.GetRegistry().GetRegisteredCollectionFiles("coll1")
	if len(filesAfter) != 0 {
		t.Error("File should be removed from collection")
	}

	// Verify file was removed from registry
	if mgr.GetRegistry().IsRegisteredFile(file1) {
		t.Error("File should be removed from registry")
	}

	// Verify permissions were restored (file should exist with original perms)
	info, err := os.Stat(file1)
	if err != nil {
		t.Fatalf("File should still exist after removal: %v", err)
	}
	if info.Mode().Perm() != 0644 {
		t.Errorf("Permissions should be restored to 0644, got %o", info.Mode().Perm())
	}
}

// TestUninstallVerification tests the uninstall operation with verification.
// Per Requirement 8.3: reset -> cleanup -> verify -> delete .guardfile.
func TestUninstallVerification(t *testing.T) {
	mgr, tmpDir, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "", "", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Create and enable a file
	file1 := createTestFile(t, tmpDir, "test1.txt", 0644)
	err = mgr.AddFiles([]string{file1})
	if err != nil {
		t.Fatalf("AddFiles failed: %v", err)
	}

	err = mgr.EnableFiles([]string{file1})
	if err != nil {
		t.Fatalf("EnableFiles failed: %v", err)
	}

	// Verify .guardfile exists
	registryPath := mgr.registryPath
	if _, err := os.Stat(registryPath); os.IsNotExist(err) {
		t.Fatal(".guardfile should exist before uninstall")
	}

	// Run uninstall
	_, err = mgr.Destroy()
	if err != nil {
		t.Fatalf("Uninstall failed: %v", err)
	}

	// Verify .guardfile was deleted
	if _, err := os.Stat(registryPath); !os.IsNotExist(err) {
		t.Error(".guardfile should be deleted after uninstall")
	}

	// Verify file permissions were restored
	info, err := os.Stat(file1)
	if err != nil {
		t.Fatalf("File should still exist: %v", err)
	}
	if info.Mode().Perm() != 0644 {
		t.Errorf("Permissions should be restored to 0644, got %o", info.Mode().Perm())
	}
}

// TestWarningFileMissingContainsCleanupSuggestion tests that missing file warnings include cleanup suggestion.
func TestWarningFileMissingContainsCleanupSuggestion(t *testing.T) {
	// Test single file missing warning
	warnings := []Warning{
		NewWarning(WarningFileMissing, "", "missing.txt"),
	}
	aggregated := AggregateWarnings(warnings)
	if len(aggregated) != 1 {
		t.Fatalf("Expected 1 aggregated message, got %d", len(aggregated))
	}
	if !strings.Contains(aggregated[0], "guard cleanup") {
		t.Errorf("Single file missing warning should suggest 'guard cleanup', got: %s", aggregated[0])
	}
	if !strings.Contains(aggregated[0], "missing.txt") {
		t.Errorf("Warning should mention the missing file, got: %s", aggregated[0])
	}

	// Test multiple files missing warning
	warnings = []Warning{
		NewWarning(WarningFileMissing, "", "file1.txt"),
		NewWarning(WarningFileMissing, "", "file2.txt"),
		NewWarning(WarningFileMissing, "", "file3.txt"),
	}
	aggregated = AggregateWarnings(warnings)
	if len(aggregated) != 1 {
		t.Fatalf("Expected 1 aggregated message, got %d", len(aggregated))
	}
	if !strings.Contains(aggregated[0], "guard cleanup") {
		t.Errorf("Multiple file missing warning should suggest 'guard cleanup', got: %s", aggregated[0])
	}
	// Check that all files are listed individually
	if !strings.Contains(aggregated[0], "file1.txt") || !strings.Contains(aggregated[0], "file2.txt") || !strings.Contains(aggregated[0], "file3.txt") {
		t.Errorf("Warning should mention all files, got: %s", aggregated[0])
	}
}

// TestCollectionEnableWithMissingFilesWarning tests that enabling a collection with missing files produces correct warning.
func TestCollectionEnableWithMissingFilesWarning(t *testing.T) {
	mgr, tmpDir, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "", "", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Create a file and add it to a collection
	file1 := createTestFile(t, tmpDir, "test1.txt", 0644)
	file2 := createTestFile(t, tmpDir, "test2.txt", 0644)
	err = mgr.AddFilesToCollections([]string{file1, file2}, []string{"testcoll"})
	if err != nil {
		t.Fatalf("AddFilesToCollections failed: %v", err)
	}

	// Delete one file from disk
	os.Remove(file2)

	// Clear warnings before the operation
	mgr.ClearWarnings()

	// Enable the collection - should warn about missing file
	err = mgr.EnableCollections([]string{"testcoll"})
	if err != nil {
		t.Fatalf("EnableCollections failed: %v", err)
	}

	// Check for warning about missing file
	warnings := mgr.GetWarnings()
	if len(warnings) == 0 {
		t.Fatal("Expected warning about missing file")
	}

	// Aggregate warnings and check content
	aggregated := AggregateWarnings(warnings)
	found := false
	for _, msg := range aggregated {
		if strings.Contains(msg, "test2.txt") && strings.Contains(msg, "cleanup") {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("Expected warning about missing file with cleanup suggestion, got: %v", aggregated)
	}
}

// TestCollectionDisableWithMissingFilesWarning tests that disabling a collection with missing files produces correct warning.
func TestCollectionDisableWithMissingFilesWarning(t *testing.T) {
	mgr, tmpDir, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "", "", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Create files and add to collection
	file1 := createTestFile(t, tmpDir, "test1.txt", 0644)
	file2 := createTestFile(t, tmpDir, "test2.txt", 0644)
	err = mgr.AddFilesToCollections([]string{file1, file2}, []string{"testcoll"})
	if err != nil {
		t.Fatalf("AddFilesToCollections failed: %v", err)
	}

	// Enable the collection first
	err = mgr.EnableCollections([]string{"testcoll"})
	if err != nil {
		t.Fatalf("EnableCollections failed: %v", err)
	}

	// Delete one file from disk
	os.Remove(file2)

	// Clear warnings before the operation
	mgr.ClearWarnings()

	// Disable the collection - should warn about missing file
	err = mgr.DisableCollections([]string{"testcoll"})
	if err != nil {
		t.Fatalf("DisableCollections failed: %v", err)
	}

	// Check for warning about missing file
	warnings := mgr.GetWarnings()
	if len(warnings) == 0 {
		t.Fatal("Expected warning about missing file")
	}

	// Aggregate warnings and check content
	aggregated := AggregateWarnings(warnings)
	found := false
	for _, msg := range aggregated {
		if strings.Contains(msg, "test2.txt") && strings.Contains(msg, "cleanup") {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("Expected warning about missing file with cleanup suggestion, got: %v", aggregated)
	}
}

// TestCollectionToggleWithMissingFilesWarning tests that toggling a collection with missing files produces correct warning.
func TestCollectionToggleWithMissingFilesWarning(t *testing.T) {
	mgr, tmpDir, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "", "", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Create files and add to collection
	file1 := createTestFile(t, tmpDir, "test1.txt", 0644)
	file2 := createTestFile(t, tmpDir, "test2.txt", 0644)
	err = mgr.AddFilesToCollections([]string{file1, file2}, []string{"testcoll"})
	if err != nil {
		t.Fatalf("AddFilesToCollections failed: %v", err)
	}

	// Delete one file from disk
	os.Remove(file2)

	// Clear warnings before the operation
	mgr.ClearWarnings()

	// Toggle the collection - should warn about missing file
	err = mgr.ToggleCollections([]string{"testcoll"})
	if err != nil {
		t.Fatalf("ToggleCollections failed: %v", err)
	}

	// Check for warning about missing file
	warnings := mgr.GetWarnings()
	if len(warnings) == 0 {
		t.Fatal("Expected warning about missing file")
	}

	// Aggregate warnings and check content
	aggregated := AggregateWarnings(warnings)
	found := false
	for _, msg := range aggregated {
		if strings.Contains(msg, "test2.txt") && strings.Contains(msg, "cleanup") {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("Expected warning about missing file with cleanup suggestion, got: %v", aggregated)
	}
}

// TestWarningShowsRelativePathsNotAbsolute tests that warnings show relative paths, not absolute paths.
func TestWarningShowsRelativePathsNotAbsolute(t *testing.T) {
	mgr, tmpDir, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "", "", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Create subdirectory and a file, then add it to a collection
	subdir := filepath.Join(tmpDir, "subdir")
	if err := os.MkdirAll(subdir, 0755); err != nil {
		t.Fatalf("Failed to create subdirectory: %v", err)
	}
	file1 := createTestFile(t, subdir, "test1.txt", 0644)
	err = mgr.AddFilesToCollections([]string{file1}, []string{"testcoll"})
	if err != nil {
		t.Fatalf("AddFilesToCollections failed: %v", err)
	}

	// Delete file from disk
	os.Remove(file1)

	// Clear warnings before the operation
	mgr.ClearWarnings()

	// Enable the collection - should warn about missing file
	err = mgr.EnableCollections([]string{"testcoll"})
	if err != nil {
		t.Fatalf("EnableCollections failed: %v", err)
	}

	// Check warnings
	warnings := mgr.GetWarnings()
	if len(warnings) == 0 {
		t.Fatal("Expected warning about missing file")
	}

	aggregated := AggregateWarnings(warnings)
	for _, msg := range aggregated {
		// Warning should NOT contain the absolute tmpDir path
		if strings.Contains(msg, tmpDir) {
			t.Errorf("Warning should not contain absolute path '%s', got: %s", tmpDir, msg)
		}
		// Warning should contain relative path
		if strings.Contains(msg, "subdir/test1.txt") || strings.Contains(msg, "test1.txt") {
			// Good - relative path is shown
			continue
		}
	}
}

// TestDestroyCollectionWithMissingFilesWarning tests that destroying a collection with missing files produces correct warning.
func TestDestroyCollectionWithMissingFilesWarning(t *testing.T) {
	mgr, tmpDir, cleanup := setupTestManager(t)
	defer cleanup()

	// Initialize registry
	err := mgr.InitializeRegistry("0600", "", "", false)
	if err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	// Create files and add to collection
	file1 := createTestFile(t, tmpDir, "test1.txt", 0644)
	file2 := createTestFile(t, tmpDir, "test2.txt", 0644)
	err = mgr.AddFilesToCollections([]string{file1, file2}, []string{"testcoll"})
	if err != nil {
		t.Fatalf("AddFilesToCollections failed: %v", err)
	}

	// Delete one file from disk
	os.Remove(file2)

	// Clear warnings before the operation
	mgr.ClearWarnings()

	// Destroy the collection - should warn about missing file
	err = mgr.RemoveCollections([]string{"testcoll"})
	if err != nil {
		t.Fatalf("RemoveCollections failed: %v", err)
	}

	// Check for warning about missing file
	warnings := mgr.GetWarnings()
	if len(warnings) == 0 {
		t.Fatal("Expected warning about missing file")
	}

	// Aggregate warnings and check content
	aggregated := AggregateWarnings(warnings)
	found := false
	for _, msg := range aggregated {
		if strings.Contains(msg, "test2.txt") && strings.Contains(msg, "cleanup") {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("Expected warning about missing file with cleanup suggestion, got: %v", aggregated)
	}
}
