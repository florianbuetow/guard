package commands

import (
	"fmt"
	"os"
	"sort"

	"github.com/florianbuetow/guard/internal/manager"
	"github.com/spf13/cobra"
)

// NewDisableCmd creates the disable command with auto-detection and subcommands.
// Per Requirement 5: Disables guard protection on files, folders, and collections.
func NewDisableCmd() *cobra.Command {
	disableCmd := &cobra.Command{
		Use:   "disable [file|folder|collection] <names...>",
		Short: "Disable guard protection",
		Long: `Disable guard protection for files, folders, or collections, restoring original permissions.

Auto-detection: Arguments are automatically detected as files, folders, or collections.
Use 'file', 'folder', or 'collection' keyword to disambiguate when needed.

Examples:
  guard disable myfile.txt           - Disable file (auto-detected)
  guard disable myfolder             - Disable folder (auto-detected if directory)
  guard disable mycollection         - Disable collection (auto-detected)
  guard disable file ambiguous       - Explicitly disable as file
  guard disable folder myfolder      - Explicitly disable as folder
  guard disable collection ambiguous - Explicitly disable as collection`,
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No files, folders, or collections specified. Usage: guard disable <names>...")
				os.Exit(1)
			}

			mgr := manager.NewManager(".guardfile")

			// Load registry
			if err := mgr.LoadRegistry(); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Use auto-detection to resolve arguments
			files, folders, collections, err := mgr.ResolveArguments(args)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Disable files
			if len(files) > 0 {
				// Count files already disabled before operation
				alreadyDisabled := 0
				for _, path := range files {
					status, err := mgr.GetFileStatus(path)
					if err == nil && status.Registered && !status.Guard {
						alreadyDisabled++
					}
				}

				if err := mgr.DisableFiles(files); err != nil {
					fmt.Fprintf(os.Stderr, "Error: %v\n", err)
					os.Exit(1)
				}

				// Count files now disabled
				nowDisabled := 0
				for _, path := range files {
					status, err := mgr.GetFileStatus(path)
					if err == nil && status.Registered && !status.Guard {
						nowDisabled++
					}
				}
				newlyDisabled := nowDisabled - alreadyDisabled

				// Print success message
				if newlyDisabled > 0 {
					fmt.Printf("Guard disabled for %d file(s)\n", newlyDisabled)
				}

				// Print skipped count
				if alreadyDisabled > 0 {
					fmt.Printf("Skipped %d file(s) already disabled\n", alreadyDisabled)
				}
			}

			// Disable folders
			if len(folders) > 0 {
				if err := mgr.DisableFolders(folders); err != nil {
					fmt.Fprintf(os.Stderr, "Error: %v\n", err)
					os.Exit(1)
				}
				fmt.Printf("Guard disabled for %d folder(s)\n", len(folders))
			}

			// Disable collections
			if len(collections) > 0 {
				if err := mgr.DisableCollections(collections); err != nil {
					fmt.Fprintf(os.Stderr, "Error: %v\n", err)
					os.Exit(1)
				}
			}

			// Print warnings
			printWarnings(mgr.GetWarnings())

			// Print errors
			printErrors(mgr.GetErrors())

			// Exit with error code if there were errors
			if mgr.HasErrors() {
				os.Exit(1)
			}
		},
	}

	// Add file subcommand for explicit usage
	disableCmd.AddCommand(newDisableFileCmd())

	// Add folder subcommand for explicit usage
	disableCmd.AddCommand(newDisableFolderCmd())

	// Add collection subcommand for explicit usage
	disableCmd.AddCommand(newDisableCollectionCmd())

	return disableCmd
}

// newDisableFileCmd creates the "disable file" subcommand.
// Per Requirement 5.2: Restores original permissions for files.
func newDisableFileCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "file <paths...>",
		Short: "Disable guard for files",
		Long: `Disable guard protection for the specified files, restoring original permissions.

Files not in the registry or missing on disk will generate warnings.`,
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No files specified. Usage: guard disable file <path>...")
				os.Exit(1)
			}

			mgr := manager.NewManager(".guardfile")

			// Load registry
			if err := mgr.LoadRegistry(); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Count files already disabled before operation
			alreadyDisabled := 0
			for _, path := range args {
				status, err := mgr.GetFileStatus(path)
				if err == nil && status.Registered && !status.Guard {
					alreadyDisabled++
				}
			}

			// Disable files
			if err := mgr.DisableFiles(args); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Count files now disabled (guard=false and in registry)
			nowDisabled := 0
			for _, path := range args {
				status, err := mgr.GetFileStatus(path)
				if err == nil && status.Registered && !status.Guard {
					nowDisabled++
				}
			}
			newlyDisabled := nowDisabled - alreadyDisabled

			// Print success message
			if newlyDisabled > 0 {
				fmt.Printf("Guard disabled for %d file(s)\n", newlyDisabled)
			}

			// Print skipped count
			if alreadyDisabled > 0 {
				fmt.Printf("Skipped %d file(s) already disabled\n", alreadyDisabled)
			}

			// Print warnings
			printWarnings(mgr.GetWarnings())

			// Print errors
			printErrors(mgr.GetErrors())

			// Exit with error code if there were errors
			if mgr.HasErrors() {
				os.Exit(1)
			}
		},
	}
}

// newDisableFolderCmd creates the "disable folder" subcommand.
func newDisableFolderCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "folder <paths...>",
		Short: "Disable guard for folders",
		Long: `Disable guard protection for files in the specified folders.

Folders are dynamic collections that scan files from disk. On disable:
- Creates folder entry in .guardfile if it doesn't exist
- Scans folder for immediate files (non-recursive)
- Registers any new files found
- Sets guard state to false for ALL files in folder
- Restores original permissions for all files`,
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No folders specified. Usage: guard disable folder <path>...")
				os.Exit(1)
			}

			mgr := manager.NewManager(".guardfile")

			// Load registry
			if err := mgr.LoadRegistry(); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Disable folders
			if err := mgr.DisableFolders(args); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Print success message for folders
			if len(args) > 0 {
				fmt.Printf("Guard disabled for %d folder(s)\n", len(args))
			}

			// Print warnings
			printWarnings(mgr.GetWarnings())

			// Print errors
			printErrors(mgr.GetErrors())

			// Exit with error code if there were errors
			if mgr.HasErrors() {
				os.Exit(1)
			}
		},
	}
}

// newDisableCollectionCmd creates the "disable collection" subcommand.
func newDisableCollectionCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "collection <names...>",
		Short: "Disable guard for collections",
		Long: `Disable guard protection for all files in the specified collections.

Empty or non-existent collections will generate warnings.`,
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No collections specified. Usage: guard disable collection <name>...")
				os.Exit(1)
			}

			mgr := manager.NewManager(".guardfile")

			// Load registry
			if err := mgr.LoadRegistry(); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Disable collections
			if err := mgr.DisableCollections(args); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Print success messages - files first (sorted), then collection summary
			statusByName := make(map[string]manager.CollectionStatus, len(args))
			for _, collectionName := range args {
				// Check if collection exists in registry
				status, err := mgr.GetCollectionStatus(collectionName, true)
				if err != nil {
					fmt.Fprintf(os.Stderr, "Error: %v\n", err)
					os.Exit(1)
				}
				if !status.Exists {
					continue // Collection doesn't exist, warning already printed
				}
				statusByName[collectionName] = status

				// Get files from collection
				if len(status.Files) == 0 {
					continue // Error or empty collection, warnings already printed
				}

				// Check which files exist on disk and print them (sorted)
				existing, _ := mgr.GetFileSystem().CheckFilesExist(status.Files)
				sort.Strings(existing)

				// Print header for this collection's files
				fmt.Printf("toggling guarded state for files in collection: %s\n", collectionName)

				for _, file := range existing {
					fmt.Printf("Guard disabled for %s\n", displayPath(mgr, file))
				}
			}
			fmt.Println()
			for _, collectionName := range args {
				status, ok := statusByName[collectionName]
				if !ok || !status.Exists {
					continue
				}
				// Only print collection success if it has files
				if len(status.Files) == 0 {
					continue // Skip empty collections
				}
				fmt.Printf("Guard disabled for collection %s\n", collectionName)
			}

			// Print warnings
			printWarnings(mgr.GetWarnings())

			// Print errors
			printErrors(mgr.GetErrors())

			// Exit with error code if there were errors
			if mgr.HasErrors() {
				os.Exit(1)
			}
		},
	}
}
