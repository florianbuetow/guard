package tui

import (
	"slices"

	"github.com/florianbuetow/guard/internal/manager"
)

// CollectionInfo holds information about a collection for display
type CollectionInfo struct {
	Name         string
	FileCount    int
	IsEmpty      bool
	GuardState   GuardState
	EquivalentTo string   // Name of an equivalent collection (same files), if any
	Children     []string // Names of child collections (proper subsets)
	Parent       string   // Name of parent collection (proper superset), if any
	Depth        int      // Hierarchy depth for indentation
}

// BuildCollectionHierarchy builds a hierarchical view of collections based on file relationships
func BuildCollectionHierarchy(mgr *manager.Manager) []CollectionInfo {
	if mgr == nil {
		return nil
	}

	collections, err := mgr.GetRegisteredCollections()
	if err != nil {
		return nil
	}
	if len(collections) == 0 {
		return nil
	}

	// Sort collections alphabetically
	slices.Sort(collections)

	// Build file sets for each collection
	fileSets := make(map[string]map[string]bool)
	for _, name := range collections {
		status, err := mgr.GetCollectionStatus(name, true)
		if err != nil || !status.Exists {
			continue
		}
		fileSet := make(map[string]bool)
		for _, f := range status.Files {
			fileSet[f] = true
		}
		fileSets[name] = fileSet
	}

	// Find equivalence groups (collections with identical file sets)
	equivalences := findEquivalenceGroups(collections, fileSets)

	// Find parent-child relationships (proper subsets)
	parents := findParents(collections, fileSets)

	// Build the result list
	var result []CollectionInfo

	// Track which collections have been added
	added := make(map[string]bool)

	// First, add root collections (those without parents)
	for _, name := range collections {
		if added[name] {
			continue
		}

		parent := parents[name]
		if parent != "" {
			continue // Will be added as a child
		}

		// Check if this is part of an equivalence group
		equiv := equivalences[name]

		info := CollectionInfo{
			Name:       name,
			FileCount:  len(fileSets[name]),
			IsEmpty:    len(fileSets[name]) == 0,
			GuardState: ComputeEffectiveCollectionGuardState(mgr, name),
			Depth:      0,
		}

		if equiv != "" && equiv != name {
			info.EquivalentTo = equiv
		}

		result = append(result, info)
		added[name] = true

		// Add children recursively
		addChildren(collections, fileSets, parents, equivalences, mgr, name, 1, added, &result)
	}

	return result
}

// addChildren recursively adds child collections
func addChildren(collections []string, fileSets map[string]map[string]bool, parents map[string]string, equivalences map[string]string, mgr *manager.Manager, parent string, depth int, added map[string]bool, result *[]CollectionInfo) {
	for _, name := range collections {
		if added[name] {
			continue
		}

		if parents[name] != parent {
			continue
		}

		equiv := equivalences[name]

		info := CollectionInfo{
			Name:       name,
			FileCount:  len(fileSets[name]),
			IsEmpty:    len(fileSets[name]) == 0,
			GuardState: ComputeEffectiveCollectionGuardState(mgr, name),
			Parent:     parent,
			Depth:      depth,
		}

		if equiv != "" && equiv != name {
			info.EquivalentTo = equiv
		}

		*result = append(*result, info)
		added[name] = true

		// Recursively add children
		addChildren(collections, fileSets, parents, equivalences, mgr, name, depth+1, added, result)
	}
}

// findEquivalenceGroups finds collections with identical file sets
// Returns a map from collection name to the "canonical" equivalent (first alphabetically)
func findEquivalenceGroups(collections []string, fileSets map[string]map[string]bool) map[string]string {
	result := make(map[string]string)

	for i := 0; i < len(collections); i++ {
		nameA := collections[i]
		setA := fileSets[nameA]

		for j := i + 1; j < len(collections); j++ {
			nameB := collections[j]
			setB := fileSets[nameB]

			if setsEqual(setA, setB) {
				// Both are equivalent - point to the alphabetically first one
				if nameA < nameB {
					result[nameB] = nameA
				} else {
					result[nameA] = nameB
				}
			}
		}
	}

	return result
}

// findParents finds the immediate parent for each collection
// A parent is the smallest proper superset
func findParents(collections []string, fileSets map[string]map[string]bool) map[string]string {
	result := make(map[string]string)

	for _, child := range collections {
		childSet := fileSets[child]
		if len(childSet) == 0 {
			continue // Empty collections have no parents
		}

		var bestParent string
		bestParentSize := -1

		for _, parent := range collections {
			if parent == child {
				continue
			}

			parentSet := fileSets[parent]
			if len(parentSet) <= len(childSet) {
				continue // Parent must be larger
			}

			// Check if parent is a proper superset
			if isProperSuperset(parentSet, childSet) {
				// Find the smallest superset
				if bestParent == "" || len(parentSet) < bestParentSize {
					bestParent = parent
					bestParentSize = len(parentSet)
				}
			}
		}

		if bestParent != "" {
			result[child] = bestParent
		}
	}

	return result
}

// setsEqual checks if two sets are equal
// Empty sets are never considered equal (empty collections are not equivalent per spec line 359)
func setsEqual(a, b map[string]bool) bool {
	if len(a) == 0 || len(b) == 0 {
		return false // Empty collections are not equivalent
	}
	if len(a) != len(b) {
		return false
	}
	for k := range a {
		if !b[k] {
			return false
		}
	}
	return true
}

// isProperSuperset checks if a is a proper superset of b (a > b)
func isProperSuperset(a, b map[string]bool) bool {
	if len(a) <= len(b) {
		return false
	}
	// All elements of b must be in a
	for k := range b {
		if !a[k] {
			return false
		}
	}
	return true
}

// GetCollectionDisplayName returns the display name for a collection, including equivalence indicator
func GetCollectionDisplayName(info CollectionInfo) string {
	name := info.Name
	if info.EquivalentTo != "" {
		name += " (≡ " + info.EquivalentTo + ")"
	}
	if info.IsEmpty {
		name += " (empty)"
	}
	return name
}
