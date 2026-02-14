package commands

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

// NewCreateCmd creates the create command for creating collections.
// This replaces `guard add collection <name>...` with `guard create <name>...`
func NewCreateCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "create <collection>...",
		Short: "Create one or more collections",
		Long: `Create one or more collections in the registry.

Examples:
  guard create mygroup                    - Create a single collection
  guard create group1 group2 group3       - Create multiple collections

Note: Collection names cannot be reserved keywords (to, from, add, remove,
file, collection, create, destroy, clear, update, uninstall).`,
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No collections specified. Usage: guard create <collection>...")
				os.Exit(1)
			}

			mgr := GetManager(cmd.Context())

			// Track which collections already exist
			alreadyExisting := []string{}
			for _, name := range args {
				if mgr.IsRegisteredCollection(name) {
					alreadyExisting = append(alreadyExisting, name)
				}
			}

			// Create collections
			if err := mgr.AddCollections(args); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			// Build list of newly created collections
			newlyCreated := []string{}
			alreadyExistingMap := make(map[string]bool)
			for _, name := range alreadyExisting {
				alreadyExistingMap[name] = true
			}
			for _, name := range args {
				if !alreadyExistingMap[name] && mgr.IsRegisteredCollection(name) {
					newlyCreated = append(newlyCreated, name)
				}
			}

			// Print success message in multi-line format
			if len(newlyCreated) > 0 {
				fmt.Printf("Created %d collection(s):\n", len(newlyCreated))
				for _, name := range newlyCreated {
					fmt.Printf("  - %s\n", name)
				}
			}

			// Print skipped count for already existing
			if len(alreadyExisting) > 0 {
				fmt.Printf("Skipped %d collection(s) already exist\n", len(alreadyExisting))
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
