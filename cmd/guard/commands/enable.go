package commands

import (
	"fmt"
	"os"
	"sort"

	"github.com/florianbuetow/guard/internal/manager"
	"github.com/spf13/cobra"
)

// NewEnableCmd creates the enable command with auto-detection and subcommands.
// Per Requirement 5: Enables guard protection on files, folders, and collections.
func NewEnableCmd() *cobra.Command {
	enableCmd := &cobra.Command{
		Use:   "enable [file|folder|collection] <names...>",
		Short: "Enable guard protection",
		Long: `Enable guard protection for files, folders, or collections.

Auto-detection: Arguments are automatically detected as files, folders, or collections.
Use 'file', 'folder', or 'collection' keyword to disambiguate when needed.

Examples:
  guard enable myfile.txt           - Enable file (auto-detected)
  guard enable myfolder             - Enable folder (auto-detected if directory)
  guard enable mycollection         - Enable collection (auto-detected)
  guard enable file ambiguous       - Explicitly enable as file
  guard enable folder myfolder      - Explicitly enable as folder
  guard enable collection ambiguous - Explicitly enable as collection`,
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No files, folders, or collections specified. Usage: guard enable <names>...")
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

			// Enable files
			if len(files) > 0 {
				// Track registration status and guard state before operation
				wasRegistered := make(map[string]bool)
				alreadyEnabled := 0
				for _, path := range files {
					status, err := mgr.GetFileStatus(path)
					wasRegistered[path] = err == nil && status.Registered
					if err == nil && status.Guard {
						alreadyEnabled++
					}
				}

				if err := mgr.EnableFiles(files); err != nil {
					fmt.Fprintf(os.Stderr, "Error: %v\n", err)
					os.Exit(1)
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

				// Count files now enabled
				nowEnabled := 0
				for _, path := range files {
					status, err := mgr.GetFileStatus(path)
					if err == nil && status.Guard {
						nowEnabled++
					}
				}
				newlyEnabled := nowEnabled - alreadyEnabled

				// Print success message
				if newlyEnabled > 0 {
					fmt.Printf("Guard enabled for %d file(s)\n", newlyEnabled)
				}

				// Print skipped count
				if alreadyEnabled > 0 {
					fmt.Printf("Skipped %d file(s) already enabled\n", alreadyEnabled)
				}
			}

			// Enable folders
			if len(folders) > 0 {
				if err := mgr.EnableFolders(folders); err != nil {
					fmt.Fprintf(os.Stderr, "Error: %v\n", err)
					os.Exit(1)
				}
				fmt.Printf("Guard enabled for %d folder(s)\n", len(folders))
			}

			// Enable collections
			if len(collections) > 0 {
				if err := mgr.EnableCollections(collections); err != nil {
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
	enableCmd.AddCommand(newEnableFileCmd())

	// Add folder subcommand for explicit usage
	enableCmd.AddCommand(newEnableFolderCmd())

	// Add collection subcommand for explicit usage
	enableCmd.AddCommand(newEnableCollectionCmd())

	return enableCmd
}

// newEnableFileCmd creates the "enable file" subcommand.
// Per Requirement 5.1: Registers files if not in registry, then enables guard.
func newEnableFileCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "file <paths...>",
		Short: "Enable guard for files",
		Long: `Enable guard protection for the specified files.

If files are not in the registry, they will be registered first with guard disabled,
then guard will be enabled. Files missing on disk will generate warnings.`,
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No files specified. Usage: guard enable file <path>...")
				os.Exit(1)
			}

			mgr := manager.NewManager(".guardfile")

			// Load registry
			if err := mgr.LoadRegistry(); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Count files already enabled before operation
			alreadyEnabled := 0
			for _, path := range args {
				status, err := mgr.GetFileStatus(path)
				if err == nil && status.Guard {
					alreadyEnabled++
				}
			}

			// Enable files
			if err := mgr.EnableFiles(args); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Count files now enabled
			nowEnabled := 0
			for _, path := range args {
				status, err := mgr.GetFileStatus(path)
				if err == nil && status.Guard {
					nowEnabled++
				}
			}
			newlyEnabled := nowEnabled - alreadyEnabled

			// Print success message
			if newlyEnabled > 0 {
				fmt.Printf("Guard enabled for %d file(s)\n", newlyEnabled)
			}

			// Print skipped count
			if alreadyEnabled > 0 {
				fmt.Printf("Skipped %d file(s) already enabled\n", alreadyEnabled)
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

// newEnableFolderCmd creates the "enable folder" subcommand.
func newEnableFolderCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "folder <paths...>",
		Short: "Enable guard for folders",
		Long: `Enable guard protection for files in the specified folders.

Folders are dynamic collections that scan files from disk. On enable:
- Creates folder entry in .guardfile if it doesn't exist
- Scans folder for immediate files (non-recursive)
- Registers any new files found
- Sets guard state to true for ALL files in folder`,
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No folders specified. Usage: guard enable folder <path>...")
				os.Exit(1)
			}

			mgr := manager.NewManager(".guardfile")

			// Load registry
			if err := mgr.LoadRegistry(); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Enable folders
			if err := mgr.EnableFolders(args); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Print success message for folders
			if len(args) > 0 {
				fmt.Printf("Guard enabled for %d folder(s)\n", len(args))
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

// newEnableCollectionCmd creates the "enable collection" subcommand.
// Per Requirement 5.4: Enables guard for all files in collections.
func newEnableCollectionCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "collection <names...>",
		Short: "Enable guard for collections",
		Long: `Enable guard protection for all files in the specified collections.

Empty or non-existent collections will generate warnings.`,
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No collections specified. Usage: guard enable collection <name>...")
				os.Exit(1)
			}

			mgr := manager.NewManager(".guardfile")

			// Load registry
			if err := mgr.LoadRegistry(); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Enable collections
			if err := mgr.EnableCollections(args); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Print success messages - files first (sorted), then collection summary
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

				// Get files from collection
				if len(status.Files) == 0 {
					continue // Error or empty collection, warnings already printed
				}

				// Check which files exist on disk and print them (sorted)
				existing, _ := mgr.GetFileSystem().CheckFilesExist(status.Files)
				sort.Strings(existing)
				for _, file := range existing {
					fmt.Printf("Guard enabled for %s\n", file)
				}
			}
			fmt.Println()
			for _, collectionName := range args {
				status, err := mgr.GetCollectionStatus(collectionName, true)
				if err != nil {
					fmt.Fprintf(os.Stderr, "Error: %v\n", err)
					os.Exit(1)
				}
				if !status.Exists {
					continue
				}
				// Only print collection success if it has files
				if len(status.Files) == 0 {
					continue // Skip empty collections
				}
				fmt.Printf("Guard enabled for collection %s\n", collectionName)
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
