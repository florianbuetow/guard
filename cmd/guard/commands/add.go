package commands

import (
	"fmt"
	"os"

	"github.com/florianbuetow/guard/internal/manager"
	"github.com/spf13/cobra"
)

// NewAddCmd creates the add command.
// The 'file' keyword is optional - args are treated as files by default.
// For collections, use 'guard create' instead.
// For adding files to collections, use 'guard update <collection> add <files>...'
func NewAddCmd() *cobra.Command {
	addCmd := &cobra.Command{
		Use:   "add [file] <paths>...",
		Short: "Add files to the registry",
		Long: `Add files to the registry.

The 'file' keyword is optional. Both of these work:
  guard add file.txt           - Add file (file keyword optional)
  guard add file file.txt      - Add file (file keyword explicit)

To create collections, use: guard create <collection>...
To add files to collections, use: guard update <collection> add <files>...`,
		Args: cobra.ArbitraryArgs,
		Run: func(cmd *cobra.Command, args []string) {
			// When called without subcommand, treat args as files
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No files specified. Usage: guard add <path>...")
				os.Exit(1)
			}

			addFiles(GetManager(cmd.Context()), args)
		},
	}

	// Add file subcommand for explicit usage (backward compatibility)
	addCmd.AddCommand(newAddFileCmd())

	return addCmd
}

// addFiles is the shared implementation for adding files.
func addFiles(mgr *manager.Manager, args []string) {
	// Count files already registered before adding
	alreadyRegistered := 0
	for _, path := range args {
		if mgr.IsRegisteredFile(path) {
			alreadyRegistered++
		}
	}

	// Add files
	if err := mgr.AddFiles(args); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	// Count newly registered files
	nowRegistered := 0
	for _, path := range args {
		if mgr.IsRegisteredFile(path) {
			nowRegistered++
		}
	}
	newlyRegistered := nowRegistered - alreadyRegistered

	// Print success message
	if newlyRegistered > 0 {
		fmt.Printf("Registered %d file(s)\n", newlyRegistered)
	}

	// Print skipped count
	if alreadyRegistered > 0 {
		fmt.Printf("Skipped %d file(s) already in registry\n", alreadyRegistered)
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

// newAddFileCmd creates the "add file" subcommand.
// This is kept for backward compatibility with explicit 'file' keyword.
func newAddFileCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "file <paths>...",
		Short: "Add files to the registry",
		Long: `Add files to the registry.

Example:
  guard add file <path>...    - Add files to registry

To add files to collections, use: guard update <collection> add <files>...`,
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No files specified. Usage: guard add file <path>...")
				os.Exit(1)
			}

			addFiles(GetManager(cmd.Context()), args)
		},
	}
}
