package commands

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/florianbuetow/guard/internal/manager"
	"github.com/spf13/cobra"
)

// NewInitCmd creates the init command.
// Per Requirement 1: Initializes a new guard registry with default settings.
// Per Requirement 1.2: Interactively prompts for missing parameters.
func NewInitCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "init [mode] [owner] [group]",
		Short: "Initialize a new guard registry",
		Long: `Initialize a new guard registry with default permission settings.

If parameters are not provided, you will be prompted for each value.
Press Enter to accept the suggested default value, or type a new value.

Parameters:
  mode    File permission mode (octal, 000-777)
  owner   Default file owner (username)
  group   Default file group (group name)

Examples:
  guard init 0600 root wheel
  guard init 0644
  guard init`,
		Run: func(cmd *cobra.Command, args []string) {
			// Per Requirement 1.1: guard init without arguments should error
			if len(args) == 0 {
				fmt.Fprintln(os.Stderr, "Error: No arguments provided. Usage: guard init <mode> [owner] [group]")
				os.Exit(1)
			}

			// Check if .guardfile already exists before prompting for parameters
			if _, err := os.Stat(".guardfile"); err == nil {
				fmt.Fprintln(os.Stderr, "Error: .guardfile already exists. Use 'guard config set' to modify settings.")
				os.Exit(1)
			}

			var mode, owner, group string

			// Parse arguments
			if len(args) > 0 {
				mode = args[0]
			}
			if len(args) > 1 {
				owner = args[1]
			}
			if len(args) > 2 {
				group = args[2]
			}

			// Validate mode early (before prompting for other values)
			if mode != "" && !isValidOctalMode(mode) {
				fmt.Fprintf(os.Stderr, "Error: Invalid mode '%s'. Mode must be an octal number between 000 and 777.\n", mode)
				os.Exit(1)
			}

			// Prompt for missing parameters (Requirement 1.2)
			// Only prompts when at least one arg is provided
			reader := bufio.NewReader(os.Stdin)

			// Prompt for mode if not provided
			if mode == "" {
				fmt.Print("Enter guard mode (000-777) [0644]: ")
				input, _ := reader.ReadString('\n')
				input = strings.TrimSpace(input)
				if input == "" {
					mode = "0644"
				} else {
					mode = input
				}
			}

			// Prompt for owner if not provided
			if owner == "" {
				// Try to get current user as default suggestion
				defaultOwner := "root"
				if currentUser := os.Getenv("USER"); currentUser != "" {
					defaultOwner = currentUser
				}

				fmt.Print("No owner specified. Use current user's owner? [Y/n]: ")
				input, _ := reader.ReadString('\n')
				input = strings.TrimSpace(input)
				if input == "" || strings.ToLower(input) == "y" {
					owner = defaultOwner
				} else {
					// User said 'n', prompt for custom value
					fmt.Print("Enter owner: ")
					customInput, _ := reader.ReadString('\n')
					owner = strings.TrimSpace(customInput)
				}
			}

			// Prompt for group if not provided
			if group == "" {
				defaultGroup := "wheel"

				fmt.Print("No group specified. Use current user's group? [Y/n]: ")
				input, _ := reader.ReadString('\n')
				input = strings.TrimSpace(input)
				if input == "" || strings.ToLower(input) == "y" {
					group = defaultGroup
				} else {
					// User said 'n', prompt for custom value
					fmt.Print("Enter group: ")
					customInput, _ := reader.ReadString('\n')
					group = strings.TrimSpace(customInput)
				}
			}

			// Create manager
			mgr := manager.NewManager(".guardfile")

			// Initialize registry
			if err := mgr.InitializeRegistry(mode, owner, group, false); err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				os.Exit(1)
			}

			fmt.Println("Initialized .guardfile with:")
			fmt.Printf("  Mode:  %s\n", mode)
			fmt.Printf("  Owner: %s\n", owner)
			fmt.Printf("  Group: %s\n", group)

			printWarnings(mgr.GetWarnings())
		},
	}
}

// isValidOctalMode validates that a mode string is a valid octal number 000-777.
func isValidOctalMode(mode string) bool {
	trimmed := strings.TrimSpace(mode)
	if len(trimmed) != 3 && len(trimmed) != 4 {
		return false
	}
	// Try to parse as octal
	val, err := strconv.ParseUint(trimmed, 8, 32)
	if err != nil {
		return false
	}
	// Ensure it's in valid range (0-511 which is 0000-0777)
	return val <= 0777
}
