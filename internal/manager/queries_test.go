package manager

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestGetFileStatusAndCollectionsQueries(t *testing.T) {
	mgr, tmpDir, cleanup := setupTestManager(t)
	defer cleanup()

	if err := mgr.InitializeRegistry("0600", "", "", false); err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	filePath := createTestFile(t, tmpDir, "file.txt", 0o644)
	if err := mgr.AddFiles([]string{filePath}); err != nil {
		t.Fatalf("AddFiles failed: %v", err)
	}

	status, err := mgr.GetFileStatus(filePath)
	if err != nil {
		t.Fatalf("GetFileStatus failed: %v", err)
	}
	if !status.Registered {
		t.Fatalf("expected file to be registered")
	}
	if status.Guard {
		t.Fatalf("expected file to be unguarded initially")
	}
	if !strings.HasSuffix(status.Path, "file.txt") {
		t.Fatalf("expected display path to include file name, got %s", status.Path)
	}

	if err := mgr.EnableFiles([]string{filePath}); err != nil {
		t.Fatalf("EnableFiles failed: %v", err)
	}

	status, err = mgr.GetFileStatus(filePath)
	if err != nil {
		t.Fatalf("GetFileStatus failed: %v", err)
	}
	if !status.Guard {
		t.Fatalf("expected file to be guarded after enable")
	}

	if err := mgr.AddCollections([]string{"coll1"}); err != nil {
		t.Fatalf("AddCollections failed: %v", err)
	}
	if err := mgr.AddFilesToCollections([]string{filePath}, []string{"coll1"}); err != nil {
		t.Fatalf("AddFilesToCollections failed: %v", err)
	}

	collStatus, err := mgr.GetCollectionStatus("coll1", true)
	if err != nil {
		t.Fatalf("GetCollectionStatus failed: %v", err)
	}
	if !collStatus.Exists {
		t.Fatalf("expected collection to exist")
	}
	if collStatus.FileCount != 1 || len(collStatus.Files) != 1 {
		t.Fatalf("expected collection to have 1 file, got %d", collStatus.FileCount)
	}

	collections, err := mgr.GetCollectionsContainingFile(filePath)
	if err != nil {
		t.Fatalf("GetCollectionsContainingFile failed: %v", err)
	}
	if len(collections) != 1 || collections[0] != "coll1" {
		t.Fatalf("expected file to be in coll1, got %v", collections)
	}

	registeredCollections, err := mgr.GetRegisteredCollections()
	if err != nil {
		t.Fatalf("GetRegisteredCollections failed: %v", err)
	}
	if len(registeredCollections) != 1 || registeredCollections[0] != "coll1" {
		t.Fatalf("expected registered collections to include coll1, got %v", registeredCollections)
	}
}

func TestSaveRegistryPersistsGuardFlag(t *testing.T) {
	mgr, tmpDir, cleanup := setupTestManager(t)
	defer cleanup()

	if err := mgr.InitializeRegistry("0600", "", "", false); err != nil {
		t.Fatalf("InitializeRegistry failed: %v", err)
	}

	filePath := createTestFile(t, tmpDir, "persist.txt", 0o644)
	if err := mgr.AddFiles([]string{filePath}); err != nil {
		t.Fatalf("AddFiles failed: %v", err)
	}
	if err := mgr.EnableFiles([]string{filePath}); err != nil {
		t.Fatalf("EnableFiles failed: %v", err)
	}

	guardfilePath := filepath.Join(tmpDir, ".guardfile")
	content, err := os.ReadFile(guardfilePath)
	if err != nil {
		t.Fatalf("failed to read .guardfile: %v", err)
	}

	text := string(content)
	if !strings.Contains(text, "persist.txt") {
		t.Fatalf("expected .guardfile to contain file entry for persist.txt")
	}
	if !strings.Contains(text, "guard: true") {
		t.Fatalf("expected .guardfile to contain guard: true")
	}
}
