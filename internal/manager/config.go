package manager

import (
	"fmt"
	"os"
	"strconv"
)

// ConfigInfo represents the current guard configuration.
type ConfigInfo struct {
	Mode           os.FileMode
	Owner          string
	Group          string
	UseGitignore   bool
	UseGuardignore bool
}

// ConfigUpdateResult describes which config fields were updated.
type ConfigUpdateResult struct {
	ModeUpdated           bool
	Mode                  os.FileMode
	OwnerUpdated          bool
	Owner                 string
	GroupUpdated          bool
	Group                 string
	UseGitignoreUpdated   bool
	UseGitignore          bool
	UseGuardignoreUpdated bool
	UseGuardignore        bool
}

// GetConfig returns the current configuration from the registry.
func (m *Manager) GetConfig() (ConfigInfo, error) {
	if m.security == nil {
		return ConfigInfo{}, fmt.Errorf(".guardfile not found. Run 'guard init' first")
	}

	return ConfigInfo{
		Mode:           m.security.GetDefaultFileMode(),
		Owner:          m.security.GetDefaultFileOwner(),
		Group:          m.security.GetDefaultFileGroup(),
		UseGitignore:   m.security.GetUseGitignore(),
		UseGuardignore: m.security.GetUseGuardignore(),
	}, nil
}

// SetConfig updates guard configuration with one or more values.
// Parameters with non-nil pointers are updated, nil means "don't change".
func (m *Manager) SetConfig(modeStr *string, owner *string, group *string) (*ConfigUpdateResult, error) {
	if m.security == nil {
		return nil, fmt.Errorf(".guardfile not found. Run 'guard init' first")
	}

	// Check that at least one parameter is provided
	if modeStr == nil && owner == nil && group == nil {
		return nil, fmt.Errorf("no configuration values provided")
	}

	result := &ConfigUpdateResult{}

	// Check if any files/collections are guarded (warning only)
	m.checkAndWarnGuardedFiles()

	// Update mode if provided
	if modeStr != nil {
		mode, err := parseOctalMode(*modeStr)
		if err != nil {
			return nil, fmt.Errorf("invalid mode: %w", err)
		}

		if err := m.security.SetDefaultFileMode(mode); err != nil {
			return nil, fmt.Errorf("failed to set mode: %w", err)
		}

		result.ModeUpdated = true
		result.Mode = mode
	}

	// Update owner if provided (can be empty string to clear)
	if owner != nil {
		m.security.SetDefaultFileOwner(*owner)
		result.OwnerUpdated = true
		result.Owner = *owner
	}

	// Update group if provided (can be empty string to clear)
	if group != nil {
		m.security.SetDefaultFileGroup(*group)
		result.GroupUpdated = true
		result.Group = *group
	}

	// Save registry
	if err := m.SaveRegistry(); err != nil {
		return nil, fmt.Errorf("failed to save config: %w", err)
	}

	return result, nil
}

// SetConfigMode updates guard_mode configuration.
func (m *Manager) SetConfigMode(modeStr string) (*ConfigUpdateResult, error) {
	return m.SetConfig(&modeStr, nil, nil)
}

// SetConfigOwner updates guard_owner configuration.
func (m *Manager) SetConfigOwner(owner string) (*ConfigUpdateResult, error) {
	return m.SetConfig(nil, &owner, nil)
}

// SetConfigGroup updates guard_group configuration.
func (m *Manager) SetConfigGroup(group string) (*ConfigUpdateResult, error) {
	return m.SetConfig(nil, nil, &group)
}

// checkAndWarnGuardedFiles checks if any files/collections are guarded and adds a warning.
func (m *Manager) checkAndWarnGuardedFiles() {
	guardedFileCount := 0
	guardedCollCount := 0

	// Count guarded files
	for _, file := range m.security.GetRegisteredFiles() {
		isGuarded, err := m.security.GetRegisteredFileGuard(file)
		if err == nil && isGuarded {
			guardedFileCount++
		}
	}

	// Count guarded collections
	for _, coll := range m.security.GetRegisteredCollections() {
		isGuarded, err := m.security.GetRegisteredCollectionGuard(coll)
		if err == nil && isGuarded {
			guardedCollCount++
		}
	}

	if guardedFileCount > 0 || guardedCollCount > 0 {
		// Format per spec: multi-line warning message
		warning := NewWarning(
			WarningGeneric,
			fmt.Sprintf("%d file(s) and %d collection(s) are currently guarded.\nThe new config will only apply to future guard operations.\nTo apply the new config to existing guards, disable and re-enable them.", guardedFileCount, guardedCollCount),
		)
		m.AddWarning(warning)
	}
}

// SetConfigUseGitignore updates the use_gitignore configuration flag.
func (m *Manager) SetConfigUseGitignore(value string) (*ConfigUpdateResult, error) {
	if m.security == nil {
		return nil, fmt.Errorf(".guardfile not found. Run 'guard init' first")
	}

	enabled, err := parseBool(value)
	if err != nil {
		return nil, fmt.Errorf("invalid value for use_gitignore: %s (expected true or false)", value)
	}

	m.security.SetUseGitignore(enabled)

	if err := m.SaveRegistry(); err != nil {
		return nil, fmt.Errorf("failed to save config: %w", err)
	}

	m.initIgnoreMatcher()

	result := &ConfigUpdateResult{UseGitignoreUpdated: true, UseGitignore: enabled}
	return result, nil
}

// SetConfigUseGuardignore updates the use_guardignore configuration flag.
func (m *Manager) SetConfigUseGuardignore(value string) (*ConfigUpdateResult, error) {
	if m.security == nil {
		return nil, fmt.Errorf(".guardfile not found. Run 'guard init' first")
	}

	enabled, err := parseBool(value)
	if err != nil {
		return nil, fmt.Errorf("invalid value for use_guardignore: %s (expected true or false)", value)
	}

	m.security.SetUseGuardignore(enabled)

	if err := m.SaveRegistry(); err != nil {
		return nil, fmt.Errorf("failed to save config: %w", err)
	}

	m.initIgnoreMatcher()

	result := &ConfigUpdateResult{UseGuardignoreUpdated: true, UseGuardignore: enabled}
	return result, nil
}

// parseBool parses a string as a boolean value (true/false).
func parseBool(value string) (bool, error) {
	switch value {
	case "true":
		return true, nil
	case "false":
		return false, nil
	default:
		return false, fmt.Errorf("invalid boolean value: %s", value)
	}
}

// parseOctalMode parses an octal mode string and returns os.FileMode.
func parseOctalMode(modeStr string) (os.FileMode, error) {
	// Parse as uint32 in base 8
	modeInt, err := strconv.ParseUint(modeStr, 8, 32)
	if err != nil {
		return 0, fmt.Errorf("not a valid octal number: %s", modeStr)
	}

	// Check range (000-777)
	if modeInt > 0777 {
		return 0, fmt.Errorf("mode must be between 000 and 777, got: %s", modeStr)
	}

	return os.FileMode(modeInt), nil
}
