package commands

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
)

// NewUpdateCmd creates the update command for modifying collection membership.
// This replaces:
//   - `guard add file <files>... to <collection>` with `guard update <collection> add <files>...`
//   - `guard remove file <files>... from <collection>` with `guard update <collection> remove <files>...`
func NewUpdateCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "update <collection> add|remove <files>...",
		Short: "Add or remove files from a collection",
		Long: `Modify collection membership by adding or removing files.

Examples:
  guard update mycoll add file1.txt file2.txt    - Add files to collection
  guard update mycoll remove file1.txt           - Remove file from collection

The collection will be created if it doesn't exist (with a warning).
Files will be registered if they don't exist in the registry.`,
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) < 2 {
				fmt.Fprintln(os.Stderr, "Error: Invalid syntax. Usage: guard update <collection> add|remove <files>...")
				os.Exit(1)
			}

			collectionName := args[0]
			operation := args[1]

			if operation != "add" && operation != "remove" {
				fmt.Fprintf(os.Stderr, "Error: Invalid operation '%s'. Use 'add' or 'remove'.\n", operation)
				os.Exit(1)
			}

			if len(args) < 3 {
				fmt.Fprintln(os.Stderr, "Error: No files specified")
				os.Exit(1)
			}

			files := args[2:]

			mgr := GetManager(cmd.Context())

			if operation == "add" {
				// Count how many files will be newly registered
				newlyRegistered := 0
				for _, file := range files {
					absPath, err := filepath.Abs(file)
					if err == nil && !mgr.IsRegisteredFile(absPath) {
						newlyRegistered++
					}
				}

				// Get count before adding
				beforeCount, _ := mgr.CountFilesInCollection(collectionName)

				if err := mgr.AddFilesToCollections(files, []string{collectionName}); err != nil {
					fmt.Fprintf(os.Stderr, "Error: %v\n", err)
					os.Exit(1)
				}

				// Get count after adding
				afterCount, _ := mgr.CountFilesInCollection(collectionName)

				// Print success messages
				if newlyRegistered > 0 {
					fmt.Printf("Registered %d file(s)\n", newlyRegistered)
				}
				added := afterCount - beforeCount
				if added > 0 {
					fmt.Printf("Added %d file(s) to collection '%s'\n", added, collectionName)
				}

				// Calculate files that were already in collection
				// Files are either added or already contained (newlyRegistered is separate)
				alreadyContained := len(files) - added
				if alreadyContained > 0 {
					fmt.Printf("%d file(s) already contained in the collection\n", alreadyContained)
				}
			} else {
				// operation == "remove"
				// Normalize file paths for RemoveFilesFromCollections
				normalizedFiles := make([]string, 0, len(files))
				for _, file := range files {
					absPath, err := filepath.Abs(file)
					if err != nil {
						normalizedFiles = append(normalizedFiles, file)
					} else {
						normalizedFiles = append(normalizedFiles, absPath)
					}
				}

				// Get count before removal
				beforeCount, _ := mgr.CountFilesInCollection(collectionName)

				if err := mgr.RemoveFilesFromCollections(normalizedFiles, []string{collectionName}); err != nil {
					fmt.Fprintf(os.Stderr, "Error: %v\n", err)
					os.Exit(1)
				}

				// Get count after removal
				afterCount, _ := mgr.CountFilesInCollection(collectionName)

				removed := beforeCount - afterCount
				if removed > 0 {
					fmt.Printf("Removed %d file(s) from collection '%s'\n", removed, collectionName)
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
