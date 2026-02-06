package commands

import (
	"fmt"
	"os"

	"github.com/florianbuetow/guard/internal/manager"
	"github.com/spf13/cobra"
)

// NewUninstallCmd creates the uninstall command.
// Per Requirement 8.3: Runs reset, cleanup, verifies, and deletes .guardfile.
func NewUninstallCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "uninstall",
		Short: "Reset, cleanup, verify, and delete the .guardfile",
		Long: `Completely remove guard from the current directory.

This command:
1. Runs reset (disable all guards)
2. Runs cleanup (remove empty collections and missing files)
3. Verifies all existing files have restored permissions
4. Deletes the .guardfile only if verification succeeds

If verification fails, the .guardfile is preserved and an error is returned.`,
		Run: func(cmd *cobra.Command, args []string) {
			mgr := manager.NewManager(".guardfile")

			// Load registry
			if err := mgr.LoadRegistry(); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Run uninstall (includes reset, cleanup, verification, and deletion)
			result, err := mgr.Destroy()
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)

				// Print warnings and errors
				printWarnings(mgr.GetWarnings())
				printErrors(mgr.GetErrors())

				os.Exit(1)
			}

			// Print warnings (if any)
			printWarnings(mgr.GetWarnings())

			// Print errors (if any)
			printErrors(mgr.GetErrors())

			// Exit with error code if there were errors
			if mgr.HasErrors() {
				os.Exit(1)
			}

			// Print success output per CLI-INTERFACE-SPECS.md
			fmt.Println("Reset complete:")
			if result.ResetResult.FilesDisabled > 0 || result.ResetResult.CollectionsDisabled > 0 {
				if result.ResetResult.FilesDisabled > 0 {
					fmt.Printf("  Guard disabled for %d file(s)\n", result.ResetResult.FilesDisabled)
				}
				if result.ResetResult.CollectionsDisabled > 0 {
					fmt.Printf("  Guard disabled for %d collection(s)\n", result.ResetResult.CollectionsDisabled)
				}
			} else {
				fmt.Println("  No guarded files or collections found")
			}

			fmt.Println("Cleanup complete:")
			if result.CleanupResult.FilesRemoved > 0 || result.CleanupResult.CollectionsRemoved > 0 {
				fmt.Printf("  Removed %d file(s) (file not found)\n", result.CleanupResult.FilesRemoved)
				fmt.Printf("  Removed %d collection(s) (empty)\n", result.CleanupResult.CollectionsRemoved)
			} else {
				fmt.Println("  No stale entries found")
			}

			if result.GuardfileRemoved {
				fmt.Println("Removed .guardfile")
				fmt.Println("Uninstall complete")
			}
		},
	}
}
