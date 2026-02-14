package commands

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

// NewResetCmd creates the reset command.
// Per Requirement 8.2: Disables guard for all files and collections.
func NewResetCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "reset",
		Short: "Disable guard for all files and collections",
		Long: `Disable guard protection for all files and collections in the registry.

This restores original permissions for all files but keeps them in the registry.
Files that don't exist on disk will generate warnings. Run cleanup afterwards
to remove orphaned entries.`,
		Run: func(cmd *cobra.Command, args []string) {
			mgr := GetManager(cmd.Context())

			// Run reset
			result, err := mgr.Reset()
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
			fmt.Println("Reset complete:")
			if result.FilesDisabled > 0 || result.CollectionsDisabled > 0 {
				if result.FilesDisabled > 0 {
					fmt.Printf("  Guard disabled for %d file(s)\n", result.FilesDisabled)
				}
				if result.CollectionsDisabled > 0 {
					fmt.Printf("  Guard disabled for %d collection(s)\n", result.CollectionsDisabled)
				}
			} else {
				fmt.Println("  No guarded files or collections found")
			}
		},
	}
}
