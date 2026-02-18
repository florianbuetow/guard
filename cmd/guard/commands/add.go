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
	var force bool

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

			addFiles(GetManager(cmd.Context()), args, force)
		},
	}

	addCmd.Flags().BoolVar(&force, "force", false, "Add files even if they match ignore patterns")

	// Add file subcommand for explicit usage (backward compatibility)
	addCmd.AddCommand(newAddFileCmd())

	return addCmd
}

// addFiles is the shared implementation for adding files.
func addFiles(mgr *manager.Manager, args []string, force bool) {
	filesToAdd := make([]string, 0, len(args))
	ignoredFiles := make([]string, 0)
	for _, path := range args {
		if !force && !mgr.IsRegisteredFile(path) && mgr.IsIgnored(path) {
			ignoredFiles = append(ignoredFiles, path)
			continue
		}
		filesToAdd = append(filesToAdd, path)
	}

	for _, path := range ignoredFiles {
		fmt.Fprintf(os.Stderr, "Warning: %s is ignored by .gitignore or .guardignore (use --force to add)\n", path)
	}

	if len(filesToAdd) == 0 {
		return
	}

	// Count files already registered before adding
	alreadyRegistered := 0
	for _, path := range filesToAdd {
		if mgr.IsRegisteredFile(path) {
			alreadyRegistered++
		}
	}

	// Add files
	if err := mgr.AddFiles(filesToAdd); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	// Count newly registered files
	nowRegistered := 0
	for _, path := range filesToAdd {
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
	var force bool

	cmd := &cobra.Command{
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

			addFiles(GetManager(cmd.Context()), args, force)
		},
	}

	cmd.Flags().BoolVar(&force, "force", false, "Add files even if they match ignore patterns")
	return cmd
}
