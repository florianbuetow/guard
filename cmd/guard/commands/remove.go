package commands

import (
	"fmt"
	"os"

	"github.com/florianbuetow/guard/internal/manager"
	"github.com/spf13/cobra"
)

// NewRemoveCmd creates the remove command.
// The 'file' keyword is optional - args are treated as files by default.
// For removing collections, use 'guard destroy' instead.
// For removing files from collections, use 'guard update <collection> remove <files>...'
func NewRemoveCmd() *cobra.Command {
	removeCmd := &cobra.Command{
		Use:   "remove [file] <paths>...",
		Short: "Remove files from the registry",
		Args:  cobra.ArbitraryArgs,
		Long: `Remove files from the registry.

The 'file' keyword is optional. Both of these work:
  guard remove file.txt           - Remove file (file keyword optional)
  guard remove file file.txt      - Remove file (file keyword explicit)

When removing files from registry:
1. Files are removed from all collections
2. Original permissions are restored
3. Files are removed from registry

To remove collections, use: guard destroy <collection>...
To remove files from collections, use: guard update <collection> remove <files>...`,
		Run: func(cmd *cobra.Command, args []string) {
			// When called without subcommand, treat args as files
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No files specified. Usage: guard remove <path>...")
				os.Exit(1)
			}

			removeFiles(GetManager(cmd.Context()), args)
		},
	}

	// Add file subcommand for explicit usage (backward compatibility)
	removeCmd.AddCommand(newRemoveFileCmd())

	return removeCmd
}

// removeFiles is the shared implementation for removing files.
func removeFiles(mgr *manager.Manager, args []string) {
	// Count files in registry before removal
	inRegistry := 0
	notInRegistry := 0
	for _, path := range args {
		if mgr.IsRegisteredFile(path) {
			inRegistry++
		} else {
			notInRegistry++
		}
	}

	// Remove files
	if err := mgr.RemoveFiles(args); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	// Print success message
	if inRegistry > 0 {
		fmt.Printf("Removed %d file(s)\n", inRegistry)
	}

	// Print skipped count
	if notInRegistry > 0 {
		fmt.Printf("Skipped %d file(s) not in registry\n", notInRegistry)
	}

	// Print warnings
	printWarnings(mgr.GetWarnings())

	// Print errors
	printErrors(mgr.GetErrors())

	// Exit with error code if there were errors
	if mgr.HasErrors() {
		os.Exit(1)
	}
}

// newRemoveFileCmd creates the "remove file" subcommand.
// This is kept for backward compatibility with explicit 'file' keyword.
func newRemoveFileCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "file <paths>...",
		Short: "Remove files from the registry",
		Long: `Remove files from the registry.

Example:
  guard remove file <path>...    - Remove files from registry

To remove files from collections, use: guard update <collection> remove <files>...`,
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No files specified. Usage: guard remove file <path>...")
				os.Exit(1)
			}

			removeFiles(GetManager(cmd.Context()), args)
		},
	}
}
