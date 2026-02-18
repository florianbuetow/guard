package registry

import (
	"os"
	"path/filepath"
	"testing"

	"gopkg.in/yaml.v3"
)

func TestConfig_IgnoreFieldsDefault(t *testing.T) {
	tmpDir := t.TempDir()
	registryPath := filepath.Join(tmpDir, ".guardfile")

	defaults := &RegistryDefaults{
		GuardMode:  "0644",
		GuardOwner: "user",
		GuardGroup: "group",
	}

	reg, err := NewRegistry(registryPath, defaults, false)
	if err != nil {
		t.Fatalf("NewRegistry failed: %v", err)
	}

	if !reg.config.GetUseGitignore() {
		t.Fatal("expected GetUseGitignore to default to true")
	}
	if !reg.config.GetUseGuardignore() {
		t.Fatal("expected GetUseGuardignore to default to true")
	}
}

func TestConfig_IgnoreFieldsSerialization(t *testing.T) {
	tmpDir := t.TempDir()
	registryPath := filepath.Join(tmpDir, ".guardfile")

	defaults := &RegistryDefaults{
		GuardMode:  "0644",
		GuardOwner: "user",
		GuardGroup: "group",
	}

	reg, err := NewRegistry(registryPath, defaults, false)
	if err != nil {
		t.Fatalf("NewRegistry failed: %v", err)
	}

	reg.config.UseGitignore = boolPtr(false)
	reg.config.UseGuardignore = boolPtr(false)

	data := RegistryData{
		Config:      reg.config,
		Files:       []FileEntry{},
		Collections: []Collection{},
		Folders:     []Folder{},
	}

	yamlData, err := yaml.Marshal(&data)
	if err != nil {
		t.Fatalf("yaml marshal failed: %v", err)
	}
	if err := os.WriteFile(registryPath, yamlData, 0644); err != nil {
		t.Fatalf("write registry failed: %v", err)
	}

	loaded, err := LoadRegistry(registryPath)
	if err != nil {
		t.Fatalf("LoadRegistry failed: %v", err)
	}

	if loaded.config.GetUseGitignore() {
		t.Fatal("expected GetUseGitignore to be false after reload")
	}
	if loaded.config.GetUseGuardignore() {
		t.Fatal("expected GetUseGuardignore to be false after reload")
	}
}

func TestConfig_BackwardCompatibility(t *testing.T) {
	tmpDir := t.TempDir()
	registryPath := filepath.Join(tmpDir, ".guardfile")

	content := `config:
  guard_mode: "0644"
  guard_owner: "user"
  guard_group: "group"
files: []
collections: []
folders: []
`

	if err := os.WriteFile(registryPath, []byte(content), 0644); err != nil {
		t.Fatalf("write legacy registry failed: %v", err)
	}

	loaded, err := LoadRegistry(registryPath)
	if err != nil {
		t.Fatalf("LoadRegistry failed: %v", err)
	}

	if !loaded.config.GetUseGitignore() {
		t.Fatal("expected missing use_gitignore to default to true")
	}
	if !loaded.config.GetUseGuardignore() {
		t.Fatal("expected missing use_guardignore to default to true")
	}
}
