package commands

import (
	"fmt"
	"os"
	"sort"

	"github.com/florianbuetow/guard/internal/manager"
	"github.com/spf13/cobra"
)

// toggleFilesWithOutput toggles files and prints status messages.
// Returns true if any errors occurred.
func toggleFilesWithOutput(mgr *manager.Manager, files []string) bool {
	// Track guard state and registration status before toggling
	guardBefore := make(map[string]bool)
	wasRegistered := make(map[string]bool)
	for _, path := range files {
		status, err := mgr.GetFileStatus(path)
		if err != nil || !status.Registered {
			// File not registered yet - will be added with guard=false, then toggled to true
			wasRegistered[path] = false
			guardBefore[path] = false
			continue
		}
		wasRegistered[path] = true
		guardBefore[path] = status.Guard
	}

	// Toggle files
	if err := mgr.ToggleFiles(files); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		return true
	}

	// Count newly registered files
	newlyRegistered := 0
	for _, path := range files {
		status, err := mgr.GetFileStatus(path)
		if err == nil && status.Registered && !wasRegistered[path] {
			newlyRegistered++
		}
	}

	// Print registration message if any files were auto-registered
	if newlyRegistered > 0 {
		fmt.Printf("Registered %d file(s)\n", newlyRegistered)
	}

	// Print status messages for each file
	for _, path := range files {
		status, err := mgr.GetFileStatus(path)
		if err != nil || !status.Registered {
			continue
		}
		// Only print if state changed
		if before, ok := guardBefore[path]; ok && before != status.Guard {
			if status.Guard {
				fmt.Printf("Guard enabled for %s\n", path)
			} else {
				fmt.Printf("Guard disabled for %s\n", path)
			}
		}
	}

	return false
}

// NewToggleCmd creates the toggle command with auto-detection and subcommands.
// Per Requirement 2.7: Toggles guard status for files, folders, and collections.
func NewToggleCmd() *cobra.Command {
	toggleCmd := &cobra.Command{
		Use:   "toggle [file|folder|collection] <names...>",
		Short: "Toggle guard protection",
		Long: `Toggle guard protection for files, folders, or collections.

Auto-detection: Arguments are automatically detected as files, folders, or collections.
Use 'file', 'folder', or 'collection' keyword to disambiguate when needed.

Examples:
  guard toggle myfile.txt           - Toggle file (auto-detected)
  guard toggle myfolder             - Toggle folder (auto-detected if directory)
  guard toggle mycollection         - Toggle collection (auto-detected)
  guard toggle file ambiguous       - Explicitly toggle as file
  guard toggle folder myfolder      - Explicitly toggle as folder
  guard toggle collection ambiguous - Explicitly toggle as collection`,
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No files, folders, or collections specified")
				fmt.Fprintln(os.Stderr, "Usage: guard toggle [file|folder|collection] <names>...")
				fmt.Fprintln(os.Stderr)
				fmt.Fprintln(os.Stderr, "Use 'guard help toggle' for more information.")
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

			// Toggle files
			if len(files) > 0 {
				if toggleFilesWithOutput(mgr, files) {
					os.Exit(1)
				}
			}

			// Toggle folders
			if len(folders) > 0 {
				if err := mgr.ToggleFolders(folders); err != nil {
					fmt.Fprintf(os.Stderr, "Error: %v\n", err)
					os.Exit(1)
				}
			}

			// Toggle collections
			if len(collections) > 0 {
				if err := mgr.ToggleCollections(collections); err != nil {
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
	toggleCmd.AddCommand(newToggleFileCmd())

	// Add folder subcommand for explicit usage
	toggleCmd.AddCommand(newToggleFolderCmd())

	// Add collection subcommand for explicit usage
	toggleCmd.AddCommand(newToggleCollectionCmd())

	return toggleCmd
}

// newToggleFileCmd creates the "toggle file" subcommand.
func newToggleFileCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "file <paths...>",
		Short: "Toggle guard for files",
		Long: `Toggle guard protection for the specified files.

Files not in the registry will be added first. Files missing on disk will
generate warnings.`,
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No files specified")
				fmt.Fprintln(os.Stderr, "Usage: guard toggle file <path>...")
				fmt.Fprintln(os.Stderr)
				fmt.Fprintln(os.Stderr, "Use 'guard help toggle' for more information.")
				os.Exit(1)
			}

			mgr := manager.NewManager(".guardfile")

			// Load registry
			if err := mgr.LoadRegistry(); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Toggle files with output
			if toggleFilesWithOutput(mgr, args) {
				os.Exit(1)
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

// newToggleFolderCmd creates the "toggle folder" subcommand.
func newToggleFolderCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "folder <paths...>",
		Short: "Toggle guard for folders",
		Long: `Toggle guard protection for files in the specified folders.

Folders are dynamic collections that scan files from disk. On toggle:
- Creates folder entry in .guardfile if it doesn't exist
- Scans folder for immediate files (non-recursive)
- Registers any new files found
- Syncs ALL files to the folder's new guard state`,
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No folders specified")
				fmt.Fprintln(os.Stderr, "Usage: guard toggle folder <path>...")
				fmt.Fprintln(os.Stderr)
				fmt.Fprintln(os.Stderr, "Use 'guard help toggle' for more information.")
				os.Exit(1)
			}

			mgr := manager.NewManager(".guardfile")

			// Load registry
			if err := mgr.LoadRegistry(); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Toggle folders
			if err := mgr.ToggleFolders(args); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
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

// newToggleCollectionCmd creates the "toggle collection" subcommand.
// CRITICAL: Implements conflict detection per Requirement 3.5.
func newToggleCollectionCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "collection <names...>",
		Short: "Toggle guard for collections",
		Long: `Toggle guard protection for all files in the specified collections.

If multiple collections are specified and they share files with different guard
states, an error will be returned and no changes will be made (conflict detection).`,
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No collections specified")
				fmt.Fprintln(os.Stderr, "Usage: guard toggle collection <name>...")
				fmt.Fprintln(os.Stderr)
				fmt.Fprintln(os.Stderr, "Use 'guard help toggle' for more information.")
				os.Exit(1)
			}

			mgr := manager.NewManager(".guardfile")

			// Load registry
			if err := mgr.LoadRegistry(); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Check if any collections exist
			validCollections := 0
			for _, name := range args {
				status, err := mgr.GetCollectionStatus(name, false)
				if err != nil {
					fmt.Fprintf(os.Stderr, "Error: %v\n", err)
					os.Exit(1)
				}
				if status.Exists {
					validCollections++
				}
			}
			if validCollections == 0 {
				// All collections are non-existent - print warnings and exit with error
				for _, name := range args {
					mgr.AddWarning(manager.NewWarning(manager.WarningCollectionNotFound, "", name))
				}
				printWarnings(mgr.GetWarnings())
				os.Exit(1)
			}

			// Toggle collections (with conflict detection)
			if err := mgr.ToggleCollections(args); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Print success messages - files first (sorted), then collection summary
			for _, collectionName := range args {
				status, err := mgr.GetCollectionStatus(collectionName, true)
				if err != nil {
					fmt.Fprintf(os.Stderr, "Error: %v\n", err)
					os.Exit(1)
				}
				if !status.Exists {
					continue
				}
				if len(status.Files) == 0 {
					continue
				}

				// Print header for this collection's files
				fmt.Printf("toggling guarded state for files in collection: %s\n", collectionName)

				// Get collection's current guard state to determine message
				guardState := status.Guard

				existing, _ := mgr.GetFileSystem().CheckFilesExist(status.Files)
				sort.Strings(existing)
				for _, file := range existing {
					if guardState {
						fmt.Printf("Guard enabled for %s\n", displayPath(mgr, file))
					} else {
						fmt.Printf("Guard disabled for %s\n", displayPath(mgr, file))
					}
				}
			}
			fmt.Println()
			for _, collectionName := range args {
				status, err := mgr.GetCollectionStatus(collectionName, false)
				if err != nil {
					fmt.Fprintf(os.Stderr, "Error: %v\n", err)
					os.Exit(1)
				}
				if !status.Exists {
					continue
				}
				if status.Guard {
					fmt.Printf("Guard enabled for collection %s\n", collectionName)
				} else {
					fmt.Printf("Guard disabled for collection %s\n", collectionName)
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
}
