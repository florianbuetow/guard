package commands

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

// NewCleanupCmd creates the cleanup command.
// Per Requirement 8.1: Removes empty collections and non-existent files.
func NewCleanupCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "cleanup",
		Short: "Remove empty collections and missing files",
		Long: `Remove all empty collections and files that don't exist on disk from the registry.

This command helps maintain registry integrity by cleaning up orphaned entries.`,
		Run: func(cmd *cobra.Command, args []string) {
			mgr := GetManager(cmd.Context())

			// Run cleanup
			result, err := mgr.Cleanup()
			if err != nil {
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

			// Print success output per CLI-INTERFACE-SPECS.md
			fmt.Println("Cleanup complete:")
			if result.FilesRemoved > 0 || result.CollectionsRemoved > 0 {
				if result.FilesRemoved > 0 {
					fmt.Printf("  Removed %d file(s) (file not found)\n", result.FilesRemoved)
				}
				if result.CollectionsRemoved > 0 {
					fmt.Printf("  Removed %d collection(s) (empty)\n", result.CollectionsRemoved)
				}
			} else {
				fmt.Println("  No stale entries found")
			}
		},
	}
}
