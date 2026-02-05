package manager

import (
	"fmt"
	"strings"
)

// WarningType represents different types of warnings.
type WarningType int

const (
	// WarningFileMissing indicates files that don't exist on disk
	WarningFileMissing WarningType = iota
	// WarningFileNotInRegistry indicates files not registered
	WarningFileNotInRegistry
	// WarningFileAlreadyInRegistry indicates duplicate file registration attempt
	WarningFileAlreadyInRegistry
	// WarningCollectionEmpty indicates an empty collection
	WarningCollectionEmpty
	// WarningCollectionNotFound indicates a non-existent collection
	WarningCollectionNotFound
	// WarningCollectionAlreadyExists indicates duplicate collection registration
	WarningCollectionAlreadyExists
	// WarningFileNotInCollection indicates file not in specified collection
	WarningFileNotInCollection
	// WarningCollectionHasMissingFiles suggests cleanup for collections with missing files
	WarningCollectionHasMissingFiles
	// WarningCollectionCreated indicates a collection was auto-created
	WarningCollectionCreated
	// WarningFolderEmpty indicates a folder contains no files
	WarningFolderEmpty
	// WarningFileAlreadyGuarded indicates file has permissions matching guard mode
	WarningFileAlreadyGuarded
	// WarningGeneric is for other warning messages
	WarningGeneric
)

// Warning represents a warning with a type and associated items.
type Warning struct {
	Type    WarningType
	Message string
	Items   []string // For aggregation (file paths, collection names, etc.)
}

// NewWarning creates a new warning with the specified type, message, and items.
func NewWarning(warnType WarningType, message string, items ...string) Warning {
	return Warning{
		Type:    warnType,
		Message: message,
		Items:   items,
	}
}

// AggregateWarnings combines warnings by type and formats them for display.
// Similar warnings are combined into single messages per Requirement 11.5.
// Example: "Warning: The following 3 files are missing: file1.txt, file2.txt, file3.txt"
func AggregateWarnings(warnings []Warning) []string {
	if len(warnings) == 0 {
		return nil
	}

	// Group warnings by type
	grouped := make(map[WarningType][]Warning)
	for _, w := range warnings {
		grouped[w.Type] = append(grouped[w.Type], w)
	}

	// Format warnings
	var result []string

	// Process each warning type
	for warnType, warns := range grouped {
		switch warnType {
		case WarningFileMissing:
			result = append(result, aggregateFilesMissing(warns))
		case WarningFileNotInRegistry:
			result = append(result, aggregateFilesNotInRegistry(warns))
		case WarningFileAlreadyInRegistry:
			// Silent per Requirement 2.4 (idempotent file addition)
			// Don't add to result
		case WarningCollectionEmpty:
			result = append(result, aggregateCollectionsEmpty(warns))
		case WarningCollectionNotFound:
			result = append(result, aggregateCollectionsNotFound(warns))
		case WarningCollectionAlreadyExists:
			result = append(result, aggregateCollectionsAlreadyExist(warns))
		case WarningFileNotInCollection:
			result = append(result, aggregateFilesNotInCollection(warns))
		case WarningCollectionHasMissingFiles:
			result = append(result, aggregateCollectionsHaveMissingFiles(warns))
		case WarningCollectionCreated:
			result = append(result, aggregateCollectionsCreated(warns))
		case WarningFolderEmpty:
			result = append(result, aggregateFoldersEmpty(warns))
		case WarningFileAlreadyGuarded:
			result = append(result, aggregateFilesAlreadyGuarded(warns))
		case WarningGeneric:
			// Generic warnings are not aggregated
			for _, w := range warns {
				result = append(result, fmt.Sprintf("Warning: %s", w.Message))
			}
		}
	}

	return result
}

func aggregateFilesMissing(warnings []Warning) string {
	allFiles := []string{}
	context := ""
	for _, w := range warnings {
		allFiles = append(allFiles, w.Items...)
		if w.Message != "" {
			context = w.Message
		}
	}

	if len(allFiles) == 0 {
		return ""
	}

	var sb strings.Builder
	sb.WriteString("Warning: The following files do not exist on disk:")
	for _, f := range allFiles {
		sb.WriteString("\n  - ")
		sb.WriteString(f)
	}

	// Append context-specific message
	if context == "not_registered" {
		sb.WriteString("\nThese files were not registered.")
	} else {
		sb.WriteString("\nRun 'guard cleanup' to remove missing files from registry.")
	}
	return sb.String()
}

func aggregateFilesNotInRegistry(warnings []Warning) string {
	allFiles := []string{}
	for _, w := range warnings {
		allFiles = append(allFiles, w.Items...)
	}

	if len(allFiles) == 0 {
		return ""
	}

	var sb strings.Builder
	sb.WriteString("Warning: The following files are not in the registry:")
	for _, f := range allFiles {
		sb.WriteString("\n  - ")
		sb.WriteString(f)
	}
	return sb.String()
}

func aggregateCollectionsEmpty(warnings []Warning) string {
	allColls := []string{}
	for _, w := range warnings {
		allColls = append(allColls, w.Items...)
	}

	if len(allColls) == 0 {
		return ""
	}

	var sb strings.Builder
	sb.WriteString("Warning: The following collections are empty:")
	for _, c := range allColls {
		sb.WriteString("\n  - ")
		sb.WriteString(c)
	}
	return sb.String()
}

func aggregateCollectionsNotFound(warnings []Warning) string {
	allColls := []string{}
	for _, w := range warnings {
		allColls = append(allColls, w.Items...)
	}

	if len(allColls) == 0 {
		return ""
	}

	var sb strings.Builder
	sb.WriteString("Warning: The following collections do not exist:")
	for _, c := range allColls {
		sb.WriteString("\n  - ")
		sb.WriteString(c)
	}
	return sb.String()
}

func aggregateCollectionsAlreadyExist(warnings []Warning) string {
	allColls := []string{}
	for _, w := range warnings {
		allColls = append(allColls, w.Items...)
	}

	if len(allColls) == 0 {
		return ""
	}

	var sb strings.Builder
	sb.WriteString("Warning: The following collections already exist:")
	for _, c := range allColls {
		sb.WriteString("\n  - ")
		sb.WriteString(c)
	}
	return sb.String()
}

func aggregateFilesNotInCollection(warnings []Warning) string {
	// This is more complex as it involves file-collection pairs
	messages := []string{}
	for _, w := range warnings {
		if len(w.Items) > 0 {
			messages = append(messages, w.Message)
		}
	}

	if len(messages) == 0 {
		return ""
	}

	if len(messages) == 1 {
		return fmt.Sprintf("Warning: %s", messages[0])
	}

	return fmt.Sprintf("Warning: Multiple files not in specified collections:\n  %s",
		strings.Join(messages, "\n  "))
}

func aggregateCollectionsHaveMissingFiles(warnings []Warning) string {
	allColls := []string{}
	for _, w := range warnings {
		allColls = append(allColls, w.Items...)
	}

	if len(allColls) == 0 {
		return ""
	}

	var sb strings.Builder
	sb.WriteString("Warning: The following collections have files missing on disk:")
	for _, c := range allColls {
		sb.WriteString("\n  - ")
		sb.WriteString(c)
	}
	sb.WriteString("\nRun 'guard cleanup' to remove missing files from registry.")
	return sb.String()
}

func aggregateCollectionsCreated(warnings []Warning) string {
	allColls := []string{}
	for _, w := range warnings {
		allColls = append(allColls, w.Items...)
	}

	if len(allColls) == 0 {
		return ""
	}

	if len(allColls) == 1 {
		return fmt.Sprintf("Warning: Collection '%s' did not exist and was created.", allColls[0])
	}

	var sb strings.Builder
	sb.WriteString("Warning: The following collections did not exist and were created:")
	for _, c := range allColls {
		sb.WriteString("\n  - ")
		sb.WriteString(c)
	}
	return sb.String()
}

func aggregateFoldersEmpty(warnings []Warning) string {
	allFolders := []string{}
	for _, w := range warnings {
		allFolders = append(allFolders, w.Items...)
	}

	if len(allFolders) == 0 {
		return ""
	}

	if len(allFolders) == 1 {
		return fmt.Sprintf("Warning: Folder '%s' contains no files", allFolders[0])
	}

	var sb strings.Builder
	sb.WriteString("Warning: The following folders contain no files:")
	for _, f := range allFolders {
		sb.WriteString("\n  - ")
		sb.WriteString(f)
	}
	return sb.String()
}

func aggregateFilesAlreadyGuarded(warnings []Warning) string {
	allFiles := []string{}
	for _, w := range warnings {
		allFiles = append(allFiles, w.Items...)
	}

	if len(allFiles) == 0 {
		return ""
	}

	if len(allFiles) == 1 {
		return fmt.Sprintf("Warning: File '%s' has permissions matching guard mode", allFiles[0])
	}

	var sb strings.Builder
	sb.WriteString("Warning: The following files have permissions matching guard mode:")
	for _, f := range allFiles {
		sb.WriteString("\n  - ")
		sb.WriteString(f)
	}
	return sb.String()
}
