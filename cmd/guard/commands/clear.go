package commands

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

// NewClearCmd creates the clear command for collections.
// Clears collections by disabling guard on files and removing files from the collection.
func NewClearCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "clear <collection>...",
		Short: "Clear files from collections (disable guard and unlink files)",
		Long: `Clear files from specified collections.

This command:
1. Disables guard on all files in the collection(s)
2. Removes all files from the collection(s)
3. Keeps the collection itself (now empty)
4. Keeps files registered in guard (not unregistered)

Use this to empty a collection while keeping the collection and file registrations.`,
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No collections specified. Usage: guard clear <collection>...")
				os.Exit(1)
			}

			mgr := GetManager(cmd.Context())

			// Track collection file counts before clearing
			type collectionInfo struct {
				name      string
				fileCount int
			}
			existingCollections := []collectionInfo{}
			alreadyEmpty := []string{}

			for _, name := range args {
				status, err := mgr.GetCollectionStatus(name, false)
				if err != nil {
					fmt.Fprintf(os.Stderr, "Error: %v\n", err)
					os.Exit(1)
				}
				if !status.Exists {
					continue
				}
				if status.FileCount == 0 {
					alreadyEmpty = append(alreadyEmpty, name)
				} else {
					existingCollections = append(existingCollections, collectionInfo{name: name, fileCount: status.FileCount})
				}
			}

			// Clear collections
			if err := mgr.ClearCollections(args); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Print success message
			if len(existingCollections) > 0 {
				fmt.Printf("Cleared %d collection(s):\n", len(existingCollections))
				for _, coll := range existingCollections {
					fmt.Printf("  - %s: removed %d file(s)\n", coll.name, coll.fileCount)
				}
			}

			// Print warning for already empty collections
			if len(alreadyEmpty) > 0 {
				fmt.Printf("Warning: The following collections are already empty:\n")
				for _, name := range alreadyEmpty {
					fmt.Printf("  - %s\n", name)
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
