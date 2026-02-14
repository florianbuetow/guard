package commands

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

// NewDestroyCmd creates the destroy command for removing collections.
// This replaces `guard remove collection <name>...` with `guard destroy <name>...`
func NewDestroyCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "destroy <collection>...",
		Short: "Remove one or more collections",
		Long: `Remove one or more collections from the registry.

This will:
1. Disable guard on all files in the collections
2. Remove the collections from the registry

The files themselves remain registered in guard (not unregistered).

Examples:
  guard destroy mygroup                    - Remove a single collection
  guard destroy group1 group2 group3       - Remove multiple collections`,
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No collections specified. Usage: guard destroy <collection>...")
				os.Exit(1)
			}

			mgr := GetManager(cmd.Context())

			// Track collection file counts before destroying
			type collectionInfo struct {
				name      string
				fileCount int
			}
			existingCollections := []collectionInfo{}

			for _, name := range args {
				status, err := mgr.GetCollectionStatus(name, false)
				if err != nil {
					fmt.Fprintf(os.Stderr, "Error: %v\n", err)
					os.Exit(1)
				}
				if status.Exists {
					existingCollections = append(existingCollections, collectionInfo{name: name, fileCount: status.FileCount})
				}
			}

			// Remove collections
			if err := mgr.RemoveCollections(args); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Print success message
			if len(existingCollections) > 0 {
				fmt.Printf("Destroyed %d collection(s):\n", len(existingCollections))
				for _, coll := range existingCollections {
					if coll.fileCount == 1 {
						fmt.Printf("  - %s (1 file)\n", coll.name)
					} else {
						fmt.Printf("  - %s (%d files)\n", coll.name, coll.fileCount)
					}
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
