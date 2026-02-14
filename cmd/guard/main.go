package main

import (
	"fmt"
	"os"

	"github.com/florianbuetow/guard/cmd/guard/commands"
	"github.com/florianbuetow/guard/internal/manager"
	"github.com/florianbuetow/guard/internal/tui"
	"github.com/spf13/cobra"
)

var version = "dev" // Set by ldflags during build

// Flag for interactive mode
var interactive bool

// Custom help template with grouped commands in specific order
const customHelpTemplate = `{{.Long}}

Usage:
  {{.UseLine}}
  {{.CommandPath}} [command]

Available Commands:
  init        Initialize a new guard registry

  add         Add files to the registry
  remove      Remove files from the registry
  toggle      Toggle guard protection
  enable      Enable guard protection
  disable     Disable guard protection

  create      Create one or more collections
  update      Add or remove files from a collection
  clear       Clear files from collections (disable guard and unlink files)
  destroy     Remove one or more collections

  show        Display status of files or collections
  info        Display information about guard
  config      Manage guard configuration

  cleanup     Remove empty collections and missing files
  reset       Disable guard for all files and collections
  uninstall   Reset, cleanup, verify, and delete the .guardfile

  completion  Generate the autocompletion script for the specified shell
  help        Help about any command
  version     Display version information

Flags:
{{.LocalFlags.FlagUsages | trimTrailingWhitespaces}}

Use "{{.CommandPath}} [command] --help" for more information about a command.`

func main() {
	// Check for interactive mode flag before setting up Cobra
	// This allows -i to work without going through Cobra's command parsing
	for _, arg := range os.Args[1:] {
		if arg == "-i" || arg == "--interactive" {
			if err := tui.Run(); err != nil {
				fmt.Fprintln(os.Stderr, err)
				os.Exit(1)
			}
			return
		}
	}

	// Create root command
	rootCmd := &cobra.Command{
		Use:   "guard",
		Short: "Guard - File permission management tool",
		Long: `Guard is a terminal-based file permission management tool that allows users
to track, modify, and restore file permissions, ownership, and group settings.

Use guard to protect files from accidental modifications by AI coding assistants
and other tools that might change file permissions.`,
		Run: func(cmd *cobra.Command, args []string) {
			// Check interactive flag
			if interactive {
				if err := tui.Run(); err != nil {
					fmt.Fprintln(os.Stderr, err)
					os.Exit(1)
				}
				return
			}
			// When run without subcommand, show help (Requirement 7.4)
			_ = cmd.Help()
		},
	}

	// Prevent Cobra from double-printing errors
	rootCmd.SilenceErrors = true

	// Set custom help template
	rootCmd.SetHelpTemplate(customHelpTemplate)

	// Add interactive mode flag
	rootCmd.PersistentFlags().BoolVarP(&interactive, "interactive", "i", false, "Launch interactive TUI mode")

	// Commands that operate without a .guardfile and skip registry loading
	skipRegistry := map[string]bool{
		"init": true, "version": true, "info": true,
		"help": true, "completion": true,
	}
	rootCmd.PersistentPreRunE = func(cmd *cobra.Command, args []string) error {
		name := cmd.Name()
		if name == "guard" || skipRegistry[name] {
			return nil
		}
		mgr := manager.NewManager(".guardfile")
		if err := mgr.LoadRegistry(); err != nil {
			return err
		}
		cmd.SetContext(commands.SetManager(cmd.Context(), mgr))
		return nil
	}

	// Add all subcommands
	rootCmd.AddCommand(commands.NewInitCmd())
	rootCmd.AddCommand(commands.NewAddCmd())
	rootCmd.AddCommand(commands.NewRemoveCmd())
	rootCmd.AddCommand(commands.NewToggleCmd())
	rootCmd.AddCommand(commands.NewEnableCmd())
	rootCmd.AddCommand(commands.NewDisableCmd())
	rootCmd.AddCommand(commands.NewCreateCmd())
	rootCmd.AddCommand(commands.NewUpdateCmd())
	rootCmd.AddCommand(commands.NewClearCmd())
	rootCmd.AddCommand(commands.NewDestroyCmd())
	rootCmd.AddCommand(commands.NewShowCmd())
	rootCmd.AddCommand(commands.NewInfoCmd())
	rootCmd.AddCommand(commands.NewConfigCmd())
	rootCmd.AddCommand(commands.NewCleanupCmd())
	rootCmd.AddCommand(commands.NewResetCmd())
	rootCmd.AddCommand(commands.NewUninstallCmd())
	rootCmd.AddCommand(commands.NewVersionCmd(version))

	// Execute root command
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
