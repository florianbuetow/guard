package commands

import (
	"fmt"
	"os"
	"strings"

	"github.com/florianbuetow/guard/internal/manager"
	"github.com/spf13/cobra"
)

// NewShowCmd creates the show command with auto-detection and subcommands.
// Per Requirement 6: Displays status of files and collections.
func NewShowCmd() *cobra.Command {
	showCmd := &cobra.Command{
		Use:   "show [file|collection] [names...]",
		Short: "Display status of files or collections",
		Long: `Display the guard status of files or collections.

Auto-detection: Arguments are automatically detected as files or collections.
Use 'file' or 'collection' keyword to disambiguate when needed.

Examples:
  guard show myfile.txt          - Show file status (auto-detected)
  guard show mycollection        - Show collection status (auto-detected)
  guard show file ambiguous      - Explicitly show as file
  guard show collection ambiguous - Explicitly show as collection
  guard show                     - Show all files and collections

When no names are specified, all registered items are shown.`,
		Run: func(cmd *cobra.Command, args []string) {
			mgr := manager.NewManager(".guardfile")

			// Load registry
			if err := mgr.LoadRegistry(); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			if len(args) == 0 {
				// Show all files and collections
				showAllFiles(mgr)
				showAllCollections(mgr)
			} else {
				// Use auto-detection to resolve arguments
				files, folders, collections, err := mgr.ResolveArguments(args)
				if err != nil {
					fmt.Fprintf(os.Stderr, "Error: %v\n", err)
					os.Exit(1)
				}

				// Show files
				if len(files) > 0 {
					showSpecificFiles(mgr, files)
				}

				// Show folders (treat as files within the folder for now)
				if len(folders) > 0 {
					// For folders, show their files
					for _, folder := range folders {
						fmt.Printf("Folder: %s\n", folder)
					}
				}

				// Show collections
				if len(collections) > 0 {
					showSpecificCollections(mgr, collections)
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
	showCmd.AddCommand(newShowFileCmd())

	// Add collection subcommand for explicit usage
	showCmd.AddCommand(newShowCollectionCmd())

	return showCmd
}

// showAllFiles shows all registered files
func showAllFiles(mgr *manager.Manager) {
	fileInfos, err := mgr.ShowFiles(nil)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		return
	}

	for _, info := range fileInfos {
		printFileInfo(info)
	}
}

// printFileInfo prints a single file in format: G/- filename (collections)
func printFileInfo(info manager.FileInfo) {
	guardFlag := "-"
	if info.Guard {
		guardFlag = "G"
	}
	collectionsStr := strings.Join(info.Collections, ", ")
	fmt.Printf("%s %s (%s)\n", guardFlag, info.Path, collectionsStr)
}

// showSpecificFiles shows specific files
func showSpecificFiles(mgr *manager.Manager, files []string) {
	fileInfos, err := mgr.ShowFiles(files)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		return
	}

	for _, info := range fileInfos {
		printFileInfo(info)
	}
}

// showAllCollections shows all collections (summary view)
func showAllCollections(mgr *manager.Manager) {
	collections, summary, err := mgr.ListCollections(nil, false)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		return
	}

	for _, info := range collections {
		guardFlag := "-"
		if info.Guard {
			guardFlag = "G"
		}
		fmt.Printf("%s collection: %s (%d files)\n", guardFlag, info.Name, info.FileCount)
	}

	if summary != nil {
		fmt.Printf("\n%d collection(s) total: %d guarded, %d unguarded\n", summary.Total, summary.Guarded, summary.Unguarded)
	}
}

// showSpecificCollections shows specific collections (detailed view)
func showSpecificCollections(mgr *manager.Manager, collections []string) {
	infos, _, err := mgr.ListCollections(collections, true)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		return
	}

	for _, info := range infos {
		guardFlag := "-"
		if info.Guard {
			guardFlag = "G"
		}
		fmt.Printf("%s collection: %s (%d files)\n", guardFlag, info.Name, info.FileCount)
		for _, file := range info.Files {
			fileGuardFlag := "-"
			if file.Guard {
				fileGuardFlag = "G"
			}
			fmt.Printf("  %s %s\n", fileGuardFlag, file.Path)
		}
	}
}

// newShowFileCmd creates the "show file" subcommand.
// Per Requirement 6.1-6.2: Shows guard status and collection membership.
func newShowFileCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "file [paths...]",
		Short: "Display status of files",
		Long: `Display the guard status of files and which collections they belong to.

Output format: G/- filename (collections)
  Where G indicates guard is enabled, - indicates disabled
  Collections are shown in parentheses, comma-separated

If no files are specified, all registered files are shown.`,
		Run: func(cmd *cobra.Command, args []string) {
			mgr := manager.NewManager(".guardfile")

			// Load registry
			if err := mgr.LoadRegistry(); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Get file information from manager
			fileInfos, err := mgr.ShowFiles(args)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Print file information
			for _, info := range fileInfos {
				printFileInfo(info)
			}

			// Print summary when showing all files (no args)
			if len(args) == 0 && len(fileInfos) > 0 {
				guarded := 0
				for _, info := range fileInfos {
					if info.Guard {
						guarded++
					}
				}
				unguarded := len(fileInfos) - guarded
				fmt.Printf("\n%d file(s) total: %d guarded, %d unguarded\n", len(fileInfos), guarded, unguarded)
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

// newShowCollectionCmd creates the "show collection" subcommand.
// Per Requirement 6.3-6.4: Shows collection status and file count.
func newShowCollectionCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "collection [names...]",
		Short: "Display status of collections",
		Long: `Display the guard status of collections and their file count.

Output format: G/- collection: name (n files)
  Where G indicates guard is enabled, - indicates disabled

If no collections are specified, all collections are shown with their status
and file count (but not individual files). If specific collections are requested,
individual files in those collections are also listed.`,
		Run: func(cmd *cobra.Command, args []string) {
			mgr := manager.NewManager(".guardfile")

			// Load registry
			if err := mgr.LoadRegistry(); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			if len(args) == 0 {
				showAllCollections(mgr)
			} else {
				showSpecificCollections(mgr, args)
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
