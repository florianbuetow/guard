package tui

import (
	"github.com/florianbuetow/guard/internal/manager"
)

// GetFileRegistryGuardState returns the direct guard state from registry.
// This is the ONLY state files should display - no implicit/effective computation.
// Files can only be: [G] guarded, [-] not guarded, [ ] not registered.
func GetFileRegistryGuardState(mgr *manager.Manager, path string) GuardState {
	if mgr == nil {
		return GuardStateNotRegistered
	}

	status, err := mgr.GetFileStatus(path)
	if err != nil || !status.Registered {
		return GuardStateNotRegistered
	}
	if status.Guard {
		return GuardStateExplicit
	}
	return GuardStateUnguarded
}

// ComputeFileGuardState computes the guard state for a file.
// For files, this is simply the direct registry state - files do NOT have implicit guard.
func ComputeFileGuardState(mgr *manager.Manager, path string) GuardState {
	return GetFileRegistryGuardState(mgr, path)
}

// ComputeEffectiveFolderGuardState computes the effective guard state for a folder
// based on the registry states of its files.
// files is the list of files in the folder (can be immediate or recursive)
func ComputeEffectiveFolderGuardState(mgr *manager.Manager, files []string, collectionName string) GuardState {
	if mgr == nil {
		return GuardStateNoCollection
	}

	if len(files) == 0 {
		// Empty folder - check if collection exists
		if collectionName != "" && mgr.IsRegisteredCollection(collectionName) {
			return GuardStateUnguarded
		}
		return GuardStateNoCollection
	}

	// Count the guard states of all files based on their direct registry state
	var guarded, unguarded, notRegistered int
	for _, path := range files {
		state := GetFileRegistryGuardState(mgr, path)
		switch state {
		case GuardStateExplicit:
			guarded++
		case GuardStateUnguarded:
			unguarded++
		default:
			notRegistered++
		}
	}

	// If no files are registered
	if guarded == 0 && unguarded == 0 {
		return GuardStateNoCollection
	}

	// Determine overall state
	if guarded > 0 && unguarded == 0 {
		// All registered files are guarded
		return GuardStateExplicit
	}
	if unguarded > 0 && guarded == 0 {
		// All registered files are unguarded
		return GuardStateUnguarded
	}

	// Mixed state
	return GuardStateMixed
}

// ComputeEffectiveCollectionGuardState computes the effective guard state for a collection
// based on the collection's guard flag and the registry states of its member files.
func ComputeEffectiveCollectionGuardState(mgr *manager.Manager, collectionName string) GuardState {
	if mgr == nil {
		return GuardStateUnguarded
	}

	status, err := mgr.GetCollectionStatus(collectionName, true)
	if err != nil || !status.Exists {
		return GuardStateUnguarded
	}

	// Get the collection's direct guard status
	if status.Guard {
		return GuardStateExplicit
	}

	// Get files in the collection
	if len(status.Files) == 0 {
		return GuardStateUnguarded
	}

	// Check individual file states based on their direct registry state
	var guarded, unguarded int
	for _, path := range status.Files {
		state := GetFileRegistryGuardState(mgr, path)
		switch state {
		case GuardStateExplicit:
			guarded++
		default:
			unguarded++
		}
	}

	if guarded > 0 && unguarded == 0 {
		// All files are guarded (but collection itself is not) - inherited guard
		return GuardStateImplicit
	}
	if guarded > 0 && unguarded > 0 {
		return GuardStateMixed
	}

	return GuardStateUnguarded
}

// IsFileInCollection checks if a file is in a collection
func IsFileInCollection(mgr *manager.Manager, path, collectionName string) bool {
	if mgr == nil {
		return false
	}

	collections, err := mgr.GetCollectionsContainingFile(path)
	if err != nil {
		return false
	}

	for _, name := range collections {
		if name == collectionName {
			return true
		}
	}
	return false
}

// GetCollectionsContainingFile returns all collection names that contain the given file
func GetCollectionsContainingFile(mgr *manager.Manager, path string) []string {
	if mgr == nil {
		return nil
	}

	collections, err := mgr.GetCollectionsContainingFile(path)
	if err != nil {
		return nil
	}
	return collections
}
